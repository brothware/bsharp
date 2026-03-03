import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bsharp/app/sync_provider.dart';
import 'package:bsharp/domain/entities/portal.dart';
import 'package:bsharp/l10n/strings.g.dart';
import 'package:bsharp/presentation/more/providers/more_providers.dart';

class BulletinsScreen extends ConsumerWidget {
  const BulletinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bulletins = ref.watch(bulletinsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(syncStatusProvider.notifier).sync(),
      child: bulletins.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bulletins.length,
              itemBuilder: (context, index) {
                final bulletin = bulletins[index];
                return _BulletinTile(bulletin: bulletin);
              },
            ),
    );
  }
}

class _BulletinTile extends StatelessWidget {
  const _BulletinTile({required this.bulletin});

  final PortalBulletin bulletin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(
          bulletin.isRead
              ? Icons.mark_email_read_outlined
              : Icons.mark_email_unread_outlined,
          color: bulletin.isRead
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.primary,
        ),
        title: Text(
          bulletin.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: bulletin.isRead ? null : FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${bulletin.author} • ${bulletin.date}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () => _showDetail(context, bulletin),
      ),
    );
  }

  void _showDetail(BuildContext context, PortalBulletin bulletin) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _BulletinDetailScreen(bulletin: bulletin),
      ),
    );
  }
}

class _BulletinDetailScreen extends StatelessWidget {
  const _BulletinDetailScreen({required this.bulletin});

  final PortalBulletin bulletin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.bulletins.detail)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bulletin.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  bulletin.author,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  bulletin.date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SelectableText(bulletin.content, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.campaign_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          t.bulletins.noBulletins,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}
