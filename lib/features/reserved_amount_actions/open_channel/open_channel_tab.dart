import 'package:ldk_node_flutter_workshop/constants.dart';
import 'package:ldk_node_flutter_workshop/features/reserved_amount_actions/open_channel/open_channel_controller.dart';
import 'package:ldk_node_flutter_workshop/features/reserved_amount_actions/open_channel/open_channel_state.dart';
import 'package:ldk_node_flutter_workshop/services/wallets/impl/lightning_wallet_service.dart';
import 'package:flutter/material.dart';

class OpenChannelTab extends StatefulWidget {
  const OpenChannelTab({required this.walletService, super.key});

  final LightningWalletService walletService;

  @override
  OpenChannelTabState createState() => OpenChannelTabState();
}

class OpenChannelTabState extends State<OpenChannelTab> {
  OpenChannelState _state = const OpenChannelState(
    host: '192.243.215.101',
    port: 27110,
    nodeId:
        '02de89e79fd4adfd5f15b5f09efa60250f5fcc62b8cda477a1cfab38d0bb53dd96',
    announceChannel: true,
  );
  late OpenChannelController _controller;

  @override
  void initState() {
    super.initState();

    _controller = OpenChannelController(
      getState: () => _state,
      updateState: (OpenChannelState state) => setState(() => _state = state),
      walletService: widget.walletService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: kSpacingUnit * 2),
        // Host
        ListTile(
          title: const Text('Host & Port'),
          subtitle: Text('${_state.host!}:${_state.port}'),
        ),
        // Node ID
        ListTile(
          title: const Text('Node ID'),
          subtitle: Text(_state.nodeId!),
        ),
        // Channel amount
        const SizedBox(height: kSpacingUnit * 2),
        TextField(
          onChanged: _controller.amountChangeHandler,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Channel amount',
            hintText: '0',
            helperText: 'The amount of sats to make instantly spendable.',
          ),
        ),
        const SizedBox(height: kSpacingUnit * 2),
        // Error message
        SizedBox(
          height: kSpacingUnit * 2,
          child: Text(
            _state.error is NoAmountError ||
                    _state.error is InvalidAmountException
                ? 'Please enter a valid amount.'
                : _state.error is NotEnoughFundsException
                    ? 'Not enough funds to make spendable.'
                    : _state.error is FailedToOpenChannelError
                        ? 'Failed to make funds instantly spendable. Please try again.'
                        : '',
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
        ),
        const SizedBox(height: kSpacingUnit * 2),
        // Send funds Button
        ElevatedButton.icon(
          onPressed: _state.isOpeningChannel
              ? null
              : () => _controller.confirm().then(
                    (_) {
                      if (_state.channelId != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Channel with id ${_state.channelId} opened.',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
          label: const Text('Make instantly spendable'),
          icon: _state.isOpeningChannel
              ? const CircularProgressIndicator()
              : const Icon(Icons.flash_on),
        ),
      ],
    );
  }
}
