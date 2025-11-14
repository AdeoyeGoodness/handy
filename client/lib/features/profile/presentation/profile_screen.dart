import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    if (user == null) {
      return const Center(child: Text('No user information available.'));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CircleAvatar(
          radius: 48,
          child: Text(user.firstName.substring(0, 1)),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user.fullName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text(user.phone)),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Role'),
            subtitle: Text(user.role),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone'),
            subtitle: Text(user.phone),
          ),
        ),
        if (user.bio != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: Text(user.bio!),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

