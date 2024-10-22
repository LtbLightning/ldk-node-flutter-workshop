# Solutions

Here you can find the completed functions for the `LightningWalletService` class. If you get stuck, take a look at the solutions to get an idea of how to proceed or compare your solution with the provided one. Of course in software development there are many ways to code a solution, so your solution might look different from the provided one and still be correct.

### Generating a new Lightning wallet

```dart
@override
Future<void> addWallet() async {
    // 1. Use ldk_node's Mnemonic class to generate a new, valid mnemonic
    final mnemonic = await Mnemonic.generate();

    print('Generated mnemonic: ${mnemonic.seedPhrase}');

    await _mnemonicRepository.setMnemonic(
        _walletType.label,
        mnemonic.seedPhrase,
    );

    await _initialize(mnemonic);

    if (_node != null) {
        print(
            'Lightning Node added with node id: ${(await _node!.nodeId()).hex}',
        );
    }
}
```

### Lightning Node setup

```dart
Future<void> _initialize(Mnemonic mnemonic) async {
  // 2. To create a Lightning Node instance, ldk_node provides a Builder class.
  //  Configure a Builder class instance by setting
  //    - the mnemonic as the entropy to create the node's wallet/keys from
  //    - the storage directory path to `_nodePath`,
  //    - the network to signet,
  //    - the Esplora server URL to `https://mutinynet.ltbl.io/api/`
  //    - a listening address to 0.0.0.0:9735
  final builder = Builder()
        .setEntropyBip39Mnemonic(mnemonic: mnemonic)
        .setStorageDirPath(await _nodePath)
        .setNetwork(Network.signet)
        .setEsploraServer('https://mutinynet.ltbl.io/api/')
        .setListeningAddresses(
            [
                const SocketAddress.hostname(addr: '0.0.0.0', port: 9735),
            ],
        );

  // 3. Build the node from the builder and assign it to the `_node` variable
  //  so it can be used in the rest of the class.
  _node = await builder.build();

  // 4. Start the node
  await _node!.start();

  _printLogs();
}
```

### Get the spendable balance

```dart
@override
Future<int> getSpendableBalanceSat() async {
    if (_node == null) {
      throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 5. Get all channels of the node and sum the usable channels' outbound capacity
    final usableChannels =
        (await _node!.listChannels()).where((channel) => channel.isUsable);
    final outboundCapacityMsat = usableChannels.fold(
      BigInt.zero,
      (sum, channel) => sum + channel.outboundCapacityMsat,
    );

    // 6. Return the balance in sats
    return (outboundCapacityMsat ~/ BigInt.from(1000)).toInt();
}
```

### Receive a payment

```dart
@override
Future<(String?, String?)> generateInvoices({
    int? amountSat,
    int expirySecs = 3600 * 24, // Default to 1 day
    String description = 'LDK Node Flutter Workshop',
}) async {
    if (_node == null) {
      throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 7. Based on an amount of sats being passed or not, generate a bolt11 invoice
    //  to receive a fixed amount or a variable amount of sats.
    Bolt11Payment bolt11Payment = await _node!.bolt11Payment();
    Bolt11Invoice? bolt11;
    try {
      if (amountSat == null) {
        bolt11 = await bolt11Payment.receiveVariableAmount(
          expirySecs: expirySecs,
          description: description,
        );
      } else {
        bolt11 = await bolt11Payment.receive(
          amountMsat: BigInt.from(amountSat * 1000),
          expirySecs: expirySecs,
          description: description,
        );
      }
    } catch (e) {
      final errorMessage = 'Failed to generate invoice: $e';
      print(errorMessage);
    }

    // 8. As a fallback, also generate a new on-chain address to receive funds
    //  in case the sender doesn't support Lightning payments.
    final onChainPayment = await _node!.onChainPayment();
    final bitcoinAddress = await onChainPayment.newAddress();

    print('Generated invoice: ${bolt11?.signedRawInvoice}');
    print('Generated address: ${bitcoinAddress.s}');

    // 9. Return the bitcoin address and the bolt11 invoice
    return (bitcoinAddress.s, bolt11 == null ? '' : bolt11.signedRawInvoice);
}
```

### Open a channel

```dart
Future<String> openChannel({
    required String host,
    required int port,
    required String nodeId,
    required int channelAmountSat,
    bool announceChannel = false,
}) async {
    if (_node == null) {
        throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 10. Connect to a node and open a new channel.
    await _node!.connectOpenChannel(
      socketAddress: SocketAddress.hostname(addr: host, port: port),
      nodeId: PublicKey(
        hex: nodeId,
      ),
      channelAmountSats: BigInt.from(channelAmountSat),
      announceChannel: announceChannel,
      channelConfig: null,
      pushToCounterpartyMsat: null,
    );
}
```

### Pay an invoice

```dart
@override
Future<String> pay(
    String invoice, {
    int? amountSat,
    double? satPerVbyte, // Not used in Lightning
    int? absoluteFeeSat, // Not used in Lightning
}) async {
    if (_node == null) {
        throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 11. Use the node to create and send a payment.
    //  If the amount is not specified, suppose it is embeded in the invoice.
    //  If the amount is specified, suppose the invoice is a zero-amount invoice and specify the amount when sending the payment.
    final bolt11Payment = await _node!.bolt11Payment();
    final hash = amountSat == null
        ? await bolt11Payment.send(
            invoice: Bolt11Invoice(
              signedRawInvoice: invoice,
            ),
        )
        : await bolt11Payment.sendUsingAmount(
            invoice: Bolt11Invoice(
              signedRawInvoice: invoice,
            ),
            amountMsat: BigInt.from(amountSat * 1000),
        );

    // 12. Return the payment hash as a hex string
    return hash.field0.toString();
}
```

### Get payment history

```dart
@override
Future<List<TransactionEntity>> getTransactions() async {
    if (_node == null) {
        throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 13. Get all payments of the node
    final payments = await _node!.listPayments();

    return payments.where((payment) {
      // 14. Get the actual status of the payment to only include successful ones
      final status = payment.status;
      return status == PaymentStatus.succeeded;
    }).map((payment) {
      // 15. Get the actual values from the payment for the following variables
      final paymentHash = payment.id.field0.toString();
      final isIncoming = payment.direction == PaymentDirection.inbound;
      final amountSat = payment.amountMsat != null
                ? (payment.amountMsat! ~/ BigInt.from(1000)).toInt()
                : 0;
      final timestamp = payment.latestUpdateTimestamp;

      return TransactionEntity(
        id: paymentHash,
        receivedAmountSat: isIncoming ? amountSat : 0,
        sentAmountSat: !isIncoming ? amountSat : 0,
        timestamp: timestamp,
      );
    }).toList();
}
```

### Just-in-Time (JIT) Channels

```dart
Future<void> _initialize(Mnemonic mnemonic) async {
    // 16. Add the following LSP to be able to request LSPS2 JIT channels:
    //       Node Pubkey: 02de89e79fd4adfd5f15b5f09efa60250f5fcc62b8cda477a1cfab38d0bb53dd96
    //       Node Address: 192.243.215.101:27110
    final builder = Builder()
        .setEntropyBip39Mnemonic(mnemonic: mnemonic)
        .setStorageDirPath(await _nodePath)
        .setNetwork(Network.signet)
        .setEsploraServer('https://mutinynet.ltbl.io/api')
        .setListeningAddresses(
          [
            const SocketAddress.hostname(addr: '0.0.0.0', port: 9735),
          ],
        ).setLiquiditySourceLsps2(
            address: const SocketAddress.hostname(
                addr: '192.243.215.101',
                port: 27110,
            ),
            publicKey: const PublicKey(
                hex:
                    '02de89e79fd4adfd5f15b5f09efa60250f5fcc62b8cda477a1cfab38d0bb53dd96',
            )
        );

    _node = await builder.build();

    await _node!.start();

    await _printLogs();
}
```

#### Check inbound liquidity

```dart
Future<int> get inboundLiquiditySat async {
    if (_node == null) {
      return 0;
    }

    // 17. Get the total inbound liquidity in satoshis by summing up the inbound
    //  capacity of all channels that are usable and return it in satoshis.
    final usableChannels =
        (await _node!.listChannels()).where((channel) => channel.isUsable);
    final inboundCapacityMsat = usableChannels.fold(
      BigInt.zero,
      (sum, channel) => sum + channel.inboundCapacityMsat,
    );

    return (inboundCapacityMsat ~/ BigInt.from(1000)).toInt();
}
```

#### Request JIT channels

```dart
@override
Future<(String?, String?)> generateInvoices({
  int? amountSat,
  int expirySecs = 3600 * 24, // Default to 1 day
  String description = 'LDK Node Workshop',
}) async {
    if (_node == null) {
        throw NoWalletException('A Lightning node has to be initialized first!');
    }

    Bolt11Payment bolt11Payment = await _node!.bolt11Payment();
    Bolt11Invoice? bolt11;
    try {
        if (amountSat == null) {
            // 18. Change to receive via a JIT channel when no amount is specified
            bolt11 = await bolt11Payment.receiveVariableAmountViaJitChannel(
            expirySecs: expirySecs,
            description: description,
            );
        } else {
            // 19. Check the inbound liquidity and request a JIT channel if needed
            //  otherwise receive the payment as before.
            if (await inboundLiquiditySat < amountSat) {
                bolt11 = await _node!.receiveViaJitChannel(
                    amountMsat: BigInt.from(amountSat * 1000),
                    expirySecs: expirySecs,
                    description: description,
                );
            } else {
                bolt11 = await _node!.receive(
                    amountMsat: BigInt.from(amountSat * 1000),
                    expirySecs: expirySecs,
                    description: description,
                );
            }
        }
    } catch (e) {
        final errorMessage = 'Failed to generate invoice: $e';
        print(errorMessage);
    }

    final onChainPayment = await _node!.onChainPayment();
    final bitcoinAddress = await onChainPayment.newAddress();

    print('Generated invoice: ${bolt11?.signedRawInvoice}');
    print('Generated address: ${bitcoinAddress.s}');

    return (bitcoinAddress.s, bolt11 == null ? '' : bolt11.signedRawInvoice);
}
```

### Rapid Gossip Sync

```dart
Future<void> _initialize(Mnemonic mnemonic) async {
    // 20. Add the following url to the Builder instance as the Rapid Gossip Sync server url to source the network graph data from: https://mutinynet.ltbl.io/snapshot
    final builder = Builder()
        .setEntropyBip39Mnemonic(mnemonic: mnemonic)
        .setStorageDirPath(await _nodePath)
        .setNetwork(Network.signet)
        .setEsploraServer('https://mutinynet.ltbl.io/api')
        .setListeningAddresses(
          [
            const SocketAddress.hostname(addr: '0.0.0.0', port: 9735),
          ],
        ).setLiquiditySourceLsps2(
            address: const SocketAddress.hostname(
                addr: '192.243.215.101',
                port: 27110,
            ),
            publicKey: const PublicKey(
                hex:
                    '02de89e79fd4adfd5f15b5f09efa60250f5fcc62b8cda477a1cfab38d0bb53dd96',
            )
        ).setGossipSourceRgs('https://mutinynet.ltbl.io/snapshot');

    _node = await builder.build();

    await _node!.start();

    await _printLogs();
}
```
