import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const _SectionLabel('通知'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: '募集のお知らせ',
            subtitle: '締切・開催間近の募集を通知一覧に表示',
            onTap: () => _showInfo(
              context,
              title: '募集のお知らせ',
              message: '締切や開催まで24時間以内の募集が通知一覧に表示されます。',
            ),
          ),
          const Divider(height: 1, indent: 72),
          _SettingsTile(
            icon: Icons.inventory_2_outlined,
            title: 'アーカイブ',
            subtitle: '終了した募集を自動的に移動',
            onTap: () => _showInfo(
              context,
              title: 'アーカイブ',
              message: '締切または手動で終了した募集は、自動的にアーカイブへ移動します。',
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('アプリについて'),
          const _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Himite',
            subtitle: 'バージョン 1.0.0',
          ),
        ],
      ),
    );
  }

  Future<void> _showInfo(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF66736D),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(icon, size: 21),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
