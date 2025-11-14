import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/models/message_models.dart';
import '../../../shared/widgets/async_value_widget.dart';
import 'thread_view.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(messageThreadsProvider);
    return AsyncValueWidget<List<MessageThreadModel>>(
      value: threadsAsync,
      data: (threads) {
        if (threads.isEmpty) {
          return const Center(child: Text('No messages yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: threads.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final thread = threads[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('Thread ${thread.id}'),
              subtitle: Text(
                thread.lastMessageAt != null
                    ? 'Last message: ${thread.lastMessageAt}'
                    : 'Start chatting',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ThreadView(thread: thread),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

