import 'package:ldk_node_flutter_workshop/enums/wallet_type.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class WalletBalanceViewModel extends Equatable {
  const WalletBalanceViewModel({
    required this.walletType,
    this.balanceSat,
  });

  final WalletType walletType;
  final int? balanceSat;

  double? get balanceBtc => balanceSat != null ? balanceSat! / 100000000 : null;

  @override
  List<Object?> get props => [
        walletType,
        balanceSat,
      ];
}
