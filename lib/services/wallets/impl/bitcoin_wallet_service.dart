import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:ldk_node_flutter_workshop/entities/recommended_fee_rates_entity.dart';
import 'package:ldk_node_flutter_workshop/entities/transaction_entity.dart';
import 'package:ldk_node_flutter_workshop/enums/wallet_type.dart';
import 'package:ldk_node_flutter_workshop/repositories/mnemonic_repository.dart';
import 'package:ldk_node_flutter_workshop/services/wallets/wallet_service.dart';

class BitcoinWalletService implements WalletService {
  final WalletType _walletType = WalletType.onChain;
  final MnemonicRepository _mnemonicRepository;
  Wallet? _wallet;
  late Blockchain _blockchain;

  BitcoinWalletService({
    required MnemonicRepository mnemonicRepository,
  }) : _mnemonicRepository = mnemonicRepository;

  @override
  WalletType get walletType => _walletType;

  @override
  Future<void> init() async {
    print('Initializing BitcoinWalletService...');
    await _initBlockchain();
    print('Blockchain initialized!');

    final mnemonic = await _mnemonicRepository.getMnemonic(_walletType.label);
    if (mnemonic != null && mnemonic.isNotEmpty) {
      await _initWallet(await Mnemonic.fromString(mnemonic));
      await sync();
      print('Wallet with mnemonic "$mnemonic" found, initialized and synced!');
    } else {
      print('No wallet found!');
    }
  }

  @override
  Future<void> addWallet() async {
    Mnemonic mnemonic;
    String? storedMnemonic =
        await _mnemonicRepository.getMnemonic(_walletType.label);
    if (storedMnemonic == null || storedMnemonic.isEmpty) {
      mnemonic = await Mnemonic.create(WordCount.words12);
      await _mnemonicRepository.setMnemonic(
        _walletType.label,
        await mnemonic.asString(),
      );
    } else {
      mnemonic = await Mnemonic.fromString(storedMnemonic);
    }

    await _initWallet(mnemonic);
    print(
        'Wallet added with mnemonic: ${await mnemonic.asString()} and initialized!');
  }

  @override
  bool get hasWallet => _wallet != null;

  @override
  Future<void> deleteWallet() async {
    await _mnemonicRepository.deleteMnemonic(_walletType.label);
    _wallet = null;
  }

  @override
  Future<void> sync() async {
    await _wallet!.sync(blockchain: _blockchain);
  }

  @override
  Future<int> getSpendableBalanceSat() async {
    final balance = await _wallet!.getBalance();

    print('Confirmed balance: ${balance.confirmed}');
    print('Spendable balance: ${balance.spendable}');
    print('Unconfirmed balance: ${balance.immature}');
    print('Trusted pending balance: ${balance.trustedPending}');
    print('Pending balance: ${balance.untrustedPending}');
    print('Total balance: ${balance.total}');

    return balance.spendable;
  }

  @override
  Future<(String?, String?)> generateInvoices({
    int? amountSat,
    int? expirySecs,
    String? description,
  }) async {
    final invoice = await _wallet!.getAddress(
      addressIndex: const AddressIndex.increase(),
    );

    return (await invoice.address.asString(), null);
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final transactions = await _wallet!.listTransactions(includeRaw: true);

    return transactions.map((tx) {
      return TransactionEntity(
        id: tx.txid,
        receivedAmountSat: tx.received,
        sentAmountSat: tx.sent,
        timestamp: tx.confirmationTime?.timestamp,
      );
    }).toList();
  }

  @override
  Future<String> pay(
    String invoice, {
    int? amountSat,
    double? satPerVbyte,
    int? absoluteFeeSat,
  }) async {
    if (amountSat == null) {
      throw Exception('Amount is required for a bitcoin on-chain transaction!');
    }

    // Convert the invoice to an address
    final address = await Address.fromString(
      s: invoice,
      network: Network.signet,
    );
    final script = await address
        .scriptPubkey(); // Creates the output scripts so that the wallet that generated the address can spend the funds
    var txBuilder = TxBuilder().addRecipient(script, amountSat);

    // Set the fee rate for the transaction
    if (satPerVbyte != null) {
      txBuilder = txBuilder.feeRate(satPerVbyte);
    } else if (absoluteFeeSat != null) {
      txBuilder = txBuilder.feeAbsolute(absoluteFeeSat);
    }

    final (psbt, _) = await txBuilder.finish(_wallet!);
    await _wallet!.sign(psbt: psbt);
    final tx = await psbt.extractTx();
    await _blockchain.broadcast(transaction: tx);

    return tx.txid();
  }

  Future<RecommendedFeeRatesEntity> calculateFeeRates() async {
    final [highPriority, mediumPriority, lowPriority, noPriority] =
        await Future.wait(
      [
        _blockchain.estimateFee(target: 5),
        _blockchain.estimateFee(target: 144),
        _blockchain.estimateFee(target: 504),
        _blockchain.estimateFee(target: 1008),
      ],
    );

    return RecommendedFeeRatesEntity(
      highPriority: highPriority.satPerVb,
      mediumPriority: mediumPriority.satPerVb,
      lowPriority: lowPriority.satPerVb,
      noPriority: noPriority.satPerVb,
    );
  }

  Future<void> _initBlockchain() async {
    _blockchain = await Blockchain.create(
      config: const BlockchainConfig.esplora(
        config: EsploraConfig(
          baseUrl: 'https://mutinynet.ltbl.io/api',
          stopGap: 10,
        ),
      ),
    );
  }

  Future<void> _initWallet(Mnemonic mnemonic) async {
    final descriptors = await _getBip84TemplateDescriptors(mnemonic);
    _wallet = await Wallet.create(
      descriptor: descriptors.$1,
      changeDescriptor: descriptors.$2,
      network: Network.signet,
      databaseConfig: const DatabaseConfig
          .memory(), // Txs and UTXOs related to the wallet will be stored in memory
    );
  }

  Future<(Descriptor receive, Descriptor change)> _getBip84TemplateDescriptors(
    Mnemonic mnemonic,
  ) async {
    const network = Network.signet;
    final secretKey =
        await DescriptorSecretKey.create(network: network, mnemonic: mnemonic);
    final receivingDescriptor = await Descriptor.newBip84(
      secretKey: secretKey,
      network: network,
      keychain: KeychainKind.externalChain,
    );
    final changeDescriptor = await Descriptor.newBip84(
      secretKey: secretKey,
      network: network,
      keychain: KeychainKind.internalChain,
    );

    return (receivingDescriptor, changeDescriptor);
  }
}
