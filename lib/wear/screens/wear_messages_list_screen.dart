import 'package:bsharp/app/providers/messages_providers.dart';
import 'package:bsharp/wear/screens/wear_message_detail_screen.dart';
import 'package:bsharp/wear/screens/wear_messages_tile.dart';
import 'package:bsharp/wear/widgets/wear_scaffold.dart';
import 'package:bsharp/wear/widgets/wear_swipe_dismiss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wear_os_scrollbar/wear_os_scrollbar.dart';

class WearMessagesListScreen extends ConsumerStatefulWidget {
  const WearMessagesListScreen({super.key});

  @override
  ConsumerState<WearMessagesListScreen> createState() =>
      _WearMessagesListScreenState();
}

class _WearMessagesListScreenState
    extends ConsumerState<WearMessagesListScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(inboxProvider);
    final theme = Theme.of(context);

    return WearSwipeDismiss(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: WearScaffold(
          child: WearOsScrollbar(
            controller: _scrollController,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(4),
              itemCount: inbox.length,
              itemBuilder: (context, index) {
                final msg = inbox[index];
                return WearMessageItem(
                  message: msg,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WearMessageDetailScreen(message: msg),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
