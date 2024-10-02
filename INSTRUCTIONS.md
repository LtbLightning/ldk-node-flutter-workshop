# Instructions

This workshop focuses on building the functionalities of a basic Lightning Network node/wallet. Generally, a Lightning wallet is seen as a spending wallet since it enables instant and low-fee payments, but has some extra operational considerations different to a regular on-chain (savings) wallet.

## Starting point

### Head start

To implement a complete app including UI components, state management, controllers, repositories etc. we would need a lot more time and it would take us too far from the Lightning Network and `ldk_node` specific code. Therefore you get a head start. All needed widgets, screens, entities, view_models, repositories, controllers and state classes are already implemented and ready for you.

Take a look at the different files and folders in the [`lib`](./lib/) folder. This is the folder where the code of a Flutter/Dart app is located.

#### Lightning Development Kit (LDK)

A lot goes into creating a full Lightning Network node, so luckily for us, an implementation for a full functional node build with the [Lightning Development Kit](https://lightningdevkit.org) is available in another library called [LDK Node](https://github.com/lightningdevkit/ldk-node). This library also has a Flutter package that has bindings to the LDK Node library in Rust, so we can use it in our Flutter app and quickly have a real Lightning Node embedded and running on our mobile device. The Flutter package is called [ldk_node](https://pub.dev/packages/ldk_node) on pub.dev or [ldk-node-flutter](https://github.com/LtbLightning/ldk-node-flutter) on github.

To add LDK Node to an app, you can simply run `flutter pub add ldk_node` or add it to the dependencies in the `pubspec.yaml` file of your project manually:

```yaml
dependencies:
  ldk_node: ^0.3.0
```

> [!NOTE]
> If you cloned this repository, the `ldk_node` package is already added to the dependencies in the [`pubspec.yaml`](./pubspec.yaml) file and is ready to be used.

> [!NOTE]
> The minSdkVersion in the [`android/app/build.gradle`](./android/app/build.gradle) file is also changed to 23 already. Also the iOS platform version in [`ios/Podfile`](./ios/Podfile) is set to 12.0 and for macOS the osx version is set to 14. These are the minimum versions required by the `ldk_node` package to work.

> [!NOTE]
> On macOS, network access must be allowed in the `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements` files. This is already done in this project through the following lines that were added to the files:
>
> ```xml
> <key>com.apple.security.network.client</key>
> <true/>
> ```

### Run the app

Start the app to make sure the provided code is working. You should see the user interface of the app, but it is based on hardcoded data and does not really permits you to do much yet.

### Wallet service

In the [`lib/services/wallets`](./lib/services/wallets) folder you can find the `wallet_service.dart` file. It provides an abstract `WalletService` class with the main functions a wallet service needs. In the [`impl`](./lib/services/wallets/impl/) folder a class `BitcoinWalletService` is provided and already implemented, this is not needed if you do not need a separate on-chain wallet. We just added it to be able to easily send on-chain funds from the Lightning node to another on-chain wallet as a demostration.

> [!NOTE]
> To know more about the Bitcoin wallet service implementation and how to build an on-chain Bitcoin wallet yourself, check out our [BDK Flutter Workshop](https://github.com/LtbLightning/bdk-flutter-workshop).

In this workshop, another implementation of the wallet service functions will be implemented in the `LightningWalletService` class to have a self-custodial Lightning wallet. We have left some code out of the `LightningWalletService` class for you to complete during the workshop.

## Let's code

So let's start implementing the missing parts of the `LightningWalletService` class step by step.

Try to implement the steps yourself first and only then check the [solution](SOLUTIONS.md).

### Generating a new Lightning wallet

A Lightning Node needs a seed phrase or mnemonic to derive private and public keys from to be able to receive funds and sign transactions. So generating a mnemonic is the first thing to do when a user presses the `+ Add wallet: Spending` button in the app.
Pressing this button invokes a controller function and in the end calls the addWallet function of the `LightningWalletService` class. This function should generate a new mnemonic and then initialize the wallet by setting up the Lightning Node with it.

The code to generate the mnemonic is left out of the `addWallet` function in the `LightningWalletService` class for you to complete.

```dart
@override
Future<void> addWallet() async {
    // 1. Use ldk_node's Mnemonic class to generate a new, valid mnemonic
    final mnemonic = Mnemonic(seedPhrase: 'invalid mnemonic');

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

After generating the mnemonic, the `addWallet` function calls the `_initialize` function to set up the Lightning Node with the generated mnemonic. The `_initialize` function is not implemented and should be implemented by you:

```dart
Future<void> _initialize(Mnemonic mnemonic) async {
    // 2. To create a Lightning Node instance, ldk_node provides a Builder class.
    //  Configure a Builder class instance by setting
    //    - the mnemonic as the entropy to create the node's wallet/keys from
    //    - the storage directory path to `_nodePath`,
    //    - the network to Signet,
    //    - the Esplora server URL to `https://mutinynet.ltbl.io/api/`
    //    - a listening address to 0.0.0.0:9735

    // 3. Build the node from the builder and assign it to the `_node` variable
    //  so it can be used in the rest of the class.

    // 4. Start the node

    _printLogs();
}
```

### Get the spendable balance

To get the real balance of the node, the `getSpendableBalanceSat` function should be implemented.
The amount that can be spend is the sum of the outbound capacity of all channels that are usable.

```dart
@override
Future<int> getSpendableBalanceSat() async {
    if (_node == null) {
      throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 5. Get all channels of the node and sum the usable channels' outbound capacity

    // 6. Return the balance in sats
    return 0;
}
```

### Receive a payment

In the Lightning Network, the standard way to request payments is by creating invoices. Invoices with a prefixed amount are most common and most secure, but invoices without a prefixed amount can also be created, they are generally called zero-amount invoices.

In the app we use the BIP21 format, also known as unified QR codes. This format permits to encode both Bitcoin addresses and Lightning Network invoices in the same QR code. This can be used to share a Bitcoin address as a fallback in case the sender does not support Lightning payments. So the `generateInvoices` function should return both a Bitcoin address and a Lightning Network invoice as a tuple, so the app can generate a QR code with both.

```dart
@override
Future<(String?, String?)> generateInvoices({
    int? amountSat,
    int expirySecs = 3600 * 24, // Default to 1 day
    String? description,
}) async {
    if (_node == null) {
      throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 7. Based on an amount of sats being passed or not, generate a bolt11 invoice
    //  to receive a fixed amount or a variable amount of sats.

    // 8. As a fallback, also generate a new on-chain address to receive funds
    //  in case the sender doesn't support Lightning payments.

    // 9. Return the bitcoin address and the bolt11 invoice
    return ('invalid Bitcoin address', 'invalid bolt11 invoice');
}
```

Once you have implemented the generateInvoices correctly, you should be able to see the QR code of the generated invoice in the app when you press the `Generate invoice` button in the Receive tab of the wallet actions with the spending wallet selected.

If you try to pay this invoice through the mutinynet faucet though, you will see that the payment will fail. This is because your node does not have any channels yet. First an on-chain bitcoin address needs to be funded and a channel needs to be opened before payments can be made.

So use the faucet to send some funds to the bitcoin address generated with the spending wallet.

> [!NOTE]  
> The LDK Node library uses the Bitcoin Development Kit under the hood to manage on-chain transactions and addresses. But it does not expose all the functionalities of the Bitcoin Development Kit. Mainly just receiving and sending funds without much control and obtaining the on-chain balances, respectively with `ldk_node` functions `sendToOnchainAddress`, `sendAllToOnchainAddress`, `totalOnchainBalanceSats` and `spendableOnchainBalanceSats` . These latter functionalities are used in some implemented functions of the `LightningWalletService` class already. If you want more on-chain functionalities and control, you will have to use the Bitcoin Development Kit directly and add a separate savings wallet as we did for you already and as you can learn in the [BDK Flutter Workshop](https://github.com/LtbLightning/bdk-flutter-workshop).

### Open a channel

Connect and open a channel with a node from which the host, port and node id are passed as parameters. The channel amount is also passed as a parameter and the channel is not announced by default, since this is a mobile wallet and not a routing node.

```dart
Future<void> openChannel({
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
}
```

To get the option to open a channel, press the pending balance in the transactions overview, which should appear if you have sent funds to the bitcoin address of the spending wallet and the transaction has been confirmed.

### Pay an invoice

Now that the wallet was funded and a channel was opened, you have outbound capacity and should be able to pay invoices from the 'Send funds' tab in the wallet actions bottom sheet.

When the button is pressed, calls propogate through the controller and the `pay` function of the `LightningWalletService` class is called. This function should pay the invoice with the given bolt11 string.

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

    // 11. Use the node to send a payment.
    //  If the amount is not specified, suppose it is embeded in the invoice.
    //  If the amount is specified, suppose the invoice is a zero-amount invoice and specify the amount when sending the payment.

    // 12. Return the payment hash as a hex string
    return '0x';
}
```

Try to make some payments with the app to other nodes on mutinynet and see if they are successful.
You can get invoices from the mutinynet faucet's lightning address here: https://www.lnurlpay.com/refund@lnurl-staging.mutinywallet.com. You can also try to send to other participants in the workshop.

### Get payment history

Now that we are able to send and receive payments, we should also be able to see the payment history in the app. You can get this to work by implementing the `getTransactions` function in the `LightningWalletService` class.

```dart
@override
Future<List<TransactionEntity>> getTransactions() async {
    if (_node == null) {
        throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 13. Get all payments of the node

    // 14. Filter the payments to only include successful ones and return them as a list of `TransactionEntity` instances.
    return [];
}
```

Now you have a very basic functioning Lightning wallet in your app. You can see the balance, generate invoices, pay invoices, open channels and see the payment history.

We can still improve on this though. Some additional features can be added to make the app more user-friendly. Like Rapid Gossip Sync and JIT channels. We will add them in the next steps.

### Rapid Gossip Sync

Everytime you (re)start a Lightning node, it needs to sync and verify the latest channel graph data of the network (commonly referred to as "gossip") to know the current state of the Lightning Network and how to route payments.
This can take a couple of minutes, which on a mobile phone, where the app and thus node is started and stopped frequently, can be a bit annoying when you want to make a payment quickly.

One solution that is applied by some mobile Lightning Network node wallets today is not having the gossip data on the device, but instead offloading the calculation of routing payments to a server. This approach however has some downsides, like privacy concerns, since the server will know all the payments of its users, and the need to trust the server to not manipulate the route calculation.

A better solution is to use a Rapid Gossip Sync server. This server serves a compact snapshot of the gossip network that can be used to bootstrap a node. This way the node can directly start with a recent snapshot of the network graph and calculate routes itself, without the need to pass payment recipient information to a server.

To learn more about Rapid Gossip Sync and its intricacies, check out the [docs](https://lightningdevkit.org/blog/announcing-rapid-gossip-sync/).

LDK Node already has all the Rapid Gossip Sync client functionality implemented as you can see in the original [rust-lightning code](https://github.com/lightningdevkit/rust-lightning/blob/main/lightning-rapid-gossip-sync/src/lib.rs).

We just need to use it in our app by configuring the url of the Rapid Gossip Sync server we want to use in the `LightningWalletService` class. There are a couple of LSPs that provide Rapid Gossip Sync servers. Here are some examples for different networks you can use for development:

- https://mutinynet.ltbl.io/snapshot for the Mutinynet Signet
- https://testnet.ltbl.io/snapshot for Testnet
- https://rapidsync.lightningdevkit.org/snapshot for Mainnet

Now add the url of the network you want to use to the node builder in the `_initialize` function of the `LightningWalletService` class:

```dart
Future<void> _initialize(Mnemonic mnemonic) async {
    // 15. Add the following url to the Builder instance as the Rapid Gossip Sync server url to source the network graph data from: https://mutinynet.ltbl.io/snapshot
    final builder = Builder()
        .setEntropyBip39Mnemonic(mnemonic: mnemonic)
        .setStorageDirPath(await _nodePath)
        .setNetwork(Network.signet)
        .setEsploraServer('https://mutinynet.ltbl.io/api')
        .setListeningAddresses(
          [
            const SocketAddress.hostname(addr: '0.0.0.0', port: 9735),
          ],
        );

    _node = await builder.build();

    await _node!.start();

    await _printLogs();
}
```

If you now run the app and compare the printed logs to the logs when no RGS is used, you should see a significant improvement in the time it takes to sync the network graph and see that in just the seconds of the node starting up, it has up to date information about a lot of nodes and channels. This gives the node the information it needs to calculate routes for payments itself, without having sync some minutes at every startup, and also without having to pass private payment recipient information to a third party to offload the routing calculations, as some wallets do. With RGS, the node can do it all itself, privately and quickly.

### JIT channels with LSPS2

The next feature we will implement is the Just-In-Time (JIT) channels with LSPS2. This feature allows a wallet to receive a Lightning payment without having inbound liquidity yet. The LSP will open a zero-conf channel when a payment for the wallet reaches the node of the LSP and pass the payment through this channel. So the channel is created just in time when it is needed as the name suggests. A fee is generally deducted from the amount by the LSP for this service.

Various Liquidity Service Providers and Lightning wallets and developers are working on an open standard for this feature called [LSPS2](https://github.com/BitcoinAndLightningLayerSpecs/lsp/tree/main/LSPS2). Having a standard for this feature will make it easier for wallets to integrate with different LSPs and for LSPs to provide this service to different wallets, without the need for custom integrations for each wallet-LSP pair. This gives users more choice and competition in the market.

LDK Node already has the LSPS2 client functionality implemented and we can again just use it in our app by configuring the LSPS2 compatible LSP we want to use in the `LightningWalletService` class.

#### Set the LSPS2 Liquidity Source

To configure the LSPS2 compatible LSP you want to use, you need to know the public key/node id and the address of the Lightning Node of the LSP. Possibly an access token is also needed to use an LSP and get specific quotes or liquidity capacity. You can get this information from the LSP you want to use.

For example, the following is the info of a node of the [C= (C equals)](https://cequals.xyz/) LSP on Mutinynet:

Node Pubkey: 0371d6fd7d75de2d0372d03ea00e8bacdacb50c27d0eaea0a76a0622eff1f5ef2b
Node Address: 44.219.111.31:39735
Token: JZWN9YLW

Use this information to configure the LSPS2 client in the `LightningWalletService` class:

```dart
Future<void> _initialize(Mnemonic mnemonic) async {
    // 16. Add the following LSP to be able to request LSPS2 JIT channels:
    //  Node Pubkey: 0371d6fd7d75de2d0372d03ea00e8bacdacb50c27d0eaea0a76a0622eff1f5ef2b
    //  Node Address: 44.219.111.31:39735
    //  Access token: JZWN9YLW
    final builder = Builder()
        .setEntropyBip39Mnemonic(mnemonic: mnemonic)
        .setStorageDirPath(await _nodePath)
        .setNetwork(Network.signet)
        .setEsploraServer('https://mutinynet.ltbl.io/api')
        .setListeningAddresses(
          [
            const SocketAddress.hostname(addr: '0.0.0.0', port: 9735),
          ],
        )
        .setGossipSourceRgs('https://mutinynet.ltbl.io/snapshot');

    _node = await builder.build();

    await _node!.start();

    await _printLogs();
}
```

Now we can request payments through LSPS2 JIT channels even if we don't have any channel yet or if we don't have inbound liquidity in our channels.

#### Check inbound liquidity

To be able to check the inbound liquidity, get the inbound liquidity from the node in the `inboundLiquiditySat` getter in the `LightningWalletService` class. The inbound liquidity is the sum of the inbound capacity of all channels of the node.

```dart
Future<int> get inboundLiquiditySat async {
    if (_node == null) {
      return 0;
    }

    // 17. Get the total inbound liquidity in satoshis by summing up the inbound
    //  capacity of all channels that are usable ad return it in satoshis.
    return 0;
}
```

#### Request JIT channels

Now we can change the `generateInvoices` function to request JIT channels from the LSPS2 compatible LSP when the inbound liquidity is not enough to receive a payment. We will also request a JIT channel when no amount is specified in the invoice, so we can receive any amount of payment without inbound liquidity problems.

```dart
@override
Future<(String?, String?)> generateInvoices({
  int? amountSat,
  int expirySecs = 3600 * 24, // Default to 1 day
  String description = 'BBE Workshop',
}) async {
    if (_node == null) {
        throw NoWalletException('A Lightning node has to be initialized first!');
    }

    Bolt11Payment bolt11Payment = await _node!.bolt11Payment();
    Bolt11Invoice? bolt11;
    try {
        if (amountSat == null) {
            // 18. Change to receive via a JIT channel when no amount is specified
            bolt11 = await bolt11Payment.receiveVariableAmount(
                expirySecs: expirySecs,
                description: description,
            );
        } else {
            // 19. Check the inbound liquidity and request a JIT channel if needed
            //  otherwise receive the payment as usual.
            bolt11 = await bolt11Payment.receive(
                amountMsat: amountSat * 1000,
                expirySecs: expirySecs,
                description: description,
            );
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

In a real app, you could use other logic to decide when to request a JIT channel or give the user the option to choose if they want to use JIT channels or not.

> [!TIP]
> The `ldk_node` package offers some useful `Builder` constructors to easily set up a Lightning Node for a specific network (e.g. `Builder.mutinynet()` or `Builder.testnet()`) with default configurations and with services as Esplora, Rapid Gossip Sync and LSPS2 already configured. Only thing you need to do is set the mnemonic. And you can also overwrite any default configuration as with a normal `Builder` instance.

## What's next?

Take a look at the [overview](https://github.com/LtbLightning) of other resources, packages and services developed by [Let there be Lightning](https://ltbl.io) to see what else you can use to keep building Bitcoin apps.
