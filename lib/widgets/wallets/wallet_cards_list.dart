import 'package:ldk_node_flutter_workshop/constants.dart';
import 'package:ldk_node_flutter_workshop/enums/wallet_type.dart';
import 'package:ldk_node_flutter_workshop/view_models/wallet_balance_view_model.dart';
import 'package:ldk_node_flutter_workshop/widgets/wallets/add_new_wallet_card.dart';
import 'package:ldk_node_flutter_workshop/widgets/wallets/wallet_balance_card.dart';
import 'package:flutter/material.dart';

class WalletCardsList extends StatelessWidget {
  const WalletCardsList(
    this.walletBalances, {
    required this.onAddNewWallet,
    required this.onDeleteWallet,
    required this.onSelectWallet,
    required this.selectedWalletIndex,
    super.key,
  });

  final List<WalletBalanceViewModel> walletBalances;
  final Function(WalletType) onAddNewWallet;
  final Function(int index) onDeleteWallet;
  final Function(int index) onSelectWallet;
  final int selectedWalletIndex;

  @override
  Widget build(context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: walletBalances.length,
      itemExtent: kSpacingUnit * 20,
      itemBuilder: (BuildContext context, int index) {
        if (walletBalances[index].balanceSat == null) {
          return AddNewWalletCard(
            walletType: walletBalances[index].walletType,
            onPressed: onAddNewWallet,
          );
        } else {
          return WalletBalanceCard(
            walletBalances[index],
            onDelete: () => onDeleteWallet(index),
            onTap: () => onSelectWallet(index),
            isSelected: index == selectedWalletIndex,
          );
        }
      },
    );
  }
}
