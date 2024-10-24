import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ldk_node_flutter_workshop/entities/transaction_entity.dart';
import 'package:ldk_node_flutter_workshop/enums/wallet_type.dart';
import 'package:ldk_node_flutter_workshop/repositories/mnemonic_repository.dart';
import 'package:ldk_node_flutter_workshop/services/wallets/wallet_service.dart';
import 'package:ldk_node/ldk_node.dart';
import 'package:path_provider/path_provider.dart';

class LightningWalletService implements WalletService {
  final WalletType _walletType = WalletType.lightning;
  final MnemonicRepository _mnemonicRepository;
  Node? _node;

  LightningWalletService({
    required MnemonicRepository mnemonicRepository,
  }) : _mnemonicRepository = mnemonicRepository;

  @override
  WalletType get walletType => _walletType;

  @override
  Future<void> init() async {
    final mnemonic = await _mnemonicRepository.getMnemonic(_walletType.label);
    if (mnemonic != null && mnemonic.isNotEmpty) {
      await _initialize(Mnemonic(seedPhrase: mnemonic));

      if (_node != null) {
        debugPrint(
          'Lightning node initialized with id: ${(await _node!.nodeId()).hex}',
        );
      }
    }
  }

  @override
  Future<void> addWallet() async {
    // 1. Use ldk_node's Mnemonic class to generate a new, valid mnemonic
    final mnemonic = Mnemonic(seedPhrase: 'invalid mnemonic');

    debugPrint('Generated mnemonic: ${mnemonic.seedPhrase}');

    await _mnemonicRepository.setMnemonic(
      _walletType.label,
      mnemonic.seedPhrase,
    );

    await _initialize(mnemonic);

    if (_node != null) {
      debugPrint(
        'Lightning Node added with node id: ${(await _node!.nodeId()).hex}',
      );
    }
  }

  Future<void> _initialize(Mnemonic mnemonic) async {
    // 2. To create a Lightning Node instance, ldk_node provides a Builder class.
    //  Configure a Builder class instance by setting
    //    - the mnemonic as the entropy to create the node's wallet/keys from
    //    - the storage directory path to `_nodePath`,
    //    - the network to Signet,
    //    - the Esplora server URL to `https://mutinynet.ltbl.io/api/`
    //    - a listening address to 0.0.0.0:9735
    // 16. Add the following LSP to be able to request LSPS2 JIT channels:
    //       Node Pubkey: 02de89e79fd4adfd5f15b5f09efa60250f5fcc62b8cda477a1cfab38d0bb53dd96
    //       Node Address: 192.243.215.101:27110
    // 20. Add the following url to the Builder instance as the Rapid Gossip Sync
    //     server url to source the network graph data from: https://mutinynet.ltbl.io/snapshot

    // 3. Build the node from the builder and assign it to the `_node` variable
    //  so it can be used in the rest of the class.

    // 4. Start the node

    //_printLogs();
  }

  @override
  Future<int> getSpendableBalanceSat() async {
    if (_node == null) {
      throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 5. Get all channels of the node and sum the usable channels' outbound capacity

    // 6. Return the balance in sats
    return 0;
  }

  @override
  Future<(String?, String?)> generateInvoices({
    int? amountSat,
    int expirySecs = 3600 * 24, // Default to 1 day
    String? description = 'LDK Node Workshop',
  }) async {
    if (_node == null) {
      throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 7. Based on an amount of sats being passed or not, generate a bolt11 invoice
    //  to receive a fixed amount or a variable amount of sats.
    try {
      if (amountSat == null) {
        // 18. Change to receive via a JIT channel when no amount is specified
      } else {
        // 19. Check the inbound liquidity and request a JIT channel if needed
        //  otherwise receive the payment as before.
      }
    } catch (e) {
      final errorMessage = 'Failed to generate invoice: $e';
      debugPrint(errorMessage);
    }

    // 8. As a fallback, also generate a new on-chain address to receive funds
    //  in case the sender doesn't support Lightning payments.

    // 9. Return the bitcoin address and the bolt11 invoice
    return ('invalid Bitcoin address', 'invalid bolt11 invoice');
  }

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

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    if (_node == null) {
      throw NoWalletException('A Lightning node has to be initialized first!');
    }

    // 13. Get all payments of the node
    final payments = [];

    return payments.where((payment) {
      // 14. Get the actual status of the payment to only include successful ones
      final status = PaymentStatus.succeeded;
      return status == PaymentStatus.succeeded;
    }).map((payment) {
      // 15. Get the actual values from the payment for the following variables
      final paymentHash = '';
      final isIncoming = false;
      final amountSat = 0;
      final timestamp = null;

      return TransactionEntity(
        id: paymentHash,
        receivedAmountSat: isIncoming ? amountSat : 0,
        sentAmountSat: !isIncoming ? amountSat : 0,
        timestamp: timestamp,
      );
    }).toList();
  }

  Future<int> get inboundLiquiditySat async {
    if (_node == null) {
      return 0;
    }

    // 17. Get the total inbound liquidity in satoshis by summing up the inbound
    //  capacity of all channels that are usable and return it in satoshis.
    return 0;
  }

  @override
  bool get hasWallet => _node != null;

  @override
  Future<void> deleteWallet() async {
    if (_node != null) {
      await _mnemonicRepository.deleteMnemonic(_walletType.label);
      await _node!.stop();
      await Future.delayed(const Duration(seconds: 12));
      await _clearCache();
      _node = null;
    }
  }

  @override
  Future<void> sync() async {
    if (_node == null) {
      throw NoWalletException('A Lightning node has to be initialized first!');
    }
    await _node!.syncWallets();

    await _printLogs();
  }

  Future<int> get totalOnChainBalanceSat async {
    if (_node == null) {
      return 0;
    }

    final balances = await _node!.listBalances();
    return balances.totalOnchainBalanceSats.toInt();
  }

  Future<int> get spendableOnChainBalanceSat async {
    if (_node == null) {
      return 0;
    }

    final balances = await _node!.listBalances();
    return balances.spendableOnchainBalanceSats.toInt();
  }

  Future<String> drainOnChainFunds(String address) async {
    if (_node == null) {
      throw NoWalletException('A Lightning node has to be initialized first!');
    }

    final onChainPayment = await _node!.onChainPayment();
    final tx =
        await onChainPayment.sendAllToAddress(address: Address(s: address));
    return tx.hash;
  }

  Future<String> sendOnChainFunds(String address, int amountSat) async {
    if (_node == null) {
      throw NoWalletException('A Lightning node has to be initialized first!');
    }

    final onChainPayment = await _node!.onChainPayment();
    final tx = await onChainPayment.sendToAddress(
      address: Address(s: address),
      amountSats: BigInt.from(amountSat),
    );
    return tx.hash;
  }

  Future<String> get _nodePath async {
    final directory = await getApplicationDocumentsDirectory();
    return "${directory.path}/ldk_cache";
  }

  Future<void> _clearCache() async {
    final directory = Directory(await _nodePath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> _printLogs() async {
    final logsFile = File('${await _nodePath}/logs/ldk_node_latest.log');
    String contents = await logsFile.readAsString();

    // Define the maximum length of each chunk to be printed
    const int chunkSize = 1024;

    // Split the contents into chunks and print each chunk
    for (int i = 0; i < contents.length; i += chunkSize) {
      int end =
          (i + chunkSize < contents.length) ? i + chunkSize : contents.length;
      debugPrint(contents.substring(i, end));
    }
  }
}

/*extension U8Array32X on U8Array32 {
  String get hexCode =>
      map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}*/
