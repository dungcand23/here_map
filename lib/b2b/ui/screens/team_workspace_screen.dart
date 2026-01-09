import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../b2b_notifier.dart';
import '../../models/b2b_role.dart';

class TeamWorkspaceScreen extends StatefulWidget {
  const TeamWorkspaceScreen({super.key});

  @override
  State<TeamWorkspaceScreen> createState() => _TeamWorkspaceScreenState();
}

class _TeamWorkspaceScreenState extends State<TeamWorkspaceScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _teamName = TextEditingController();
  final _joinCode = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _teamName.dispose();
    _joinCode.dispose();
    super.dispose();
  }

  Future<void> _signIn(B2BNotifier b2b) async {
    final email = _email.text.trim();
    final name = _name.text.trim();
    if (email.isEmpty) return;
    await b2b.signIn(email: email, displayName: name.isEmpty ? email : name);
  }

  Future<void> _createTeam(B2BNotifier b2b) async {
    final name = _teamName.text.trim();
    if (name.isEmpty) return;
    await b2b.createTeam(name);
  }

  Future<void> _joinTeam(B2BNotifier b2b) async {
    final code = _joinCode.text.trim();
    if (code.isEmpty) return;
    final team = await b2b.joinTeamByCode(code);
    if (team == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy team theo join code')));
    }
  }

  Future<void> _pickRole(B2BNotifier b2b, String userId) async {
    final role = await showModalBottomSheet<B2BRole>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Owner'),
                subtitle: const Text('Toàn quyền quản trị'),
                onTap: () => Navigator.pop(ctx, B2BRole.owner),
              ),
              ListTile(
                title: const Text('Dispatcher'),
                subtitle: const Text('Tạo/chỉnh tuyến, xem team'),
                onTap: () => Navigator.pop(ctx, B2BRole.dispatcher),
              ),
              ListTile(
                title: const Text('Driver'),
                subtitle: const Text('Chỉ xem & chạy tuyến'),
                onTap: () => Navigator.pop(ctx, B2BRole.driver),
              ),
            ],
          ),
        );
      },
    );

    if (role != null) {
      final ok = await b2b.updateMemberRole(userId, role);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn không có quyền đổi role')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b2b = context.watch<B2BNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team workspace'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => b2b.refresh(),
            icon: const Icon(Icons.refresh),
          ),
          if (b2b.isSignedIn)
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => b2b.signOut(),
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!b2b.isSignedIn) ...[
            const Text('Đăng nhập (local) để dùng B2B-lite'),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _signIn(b2b),
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập'),
            ),
          ] else ...[
            Text('User: ${b2b.user!.displayName} (${b2b.user!.email})'),
            const SizedBox(height: 12),
            if (!b2b.hasTeam) ...[
              const Text('Tạo team mới hoặc join team bằng code'),
              const SizedBox(height: 12),
              TextField(
                controller: _teamName,
                decoration: const InputDecoration(labelText: 'Tên team'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _createTeam(b2b),
                icon: const Icon(Icons.group_add),
                label: const Text('Tạo team'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _joinCode,
                decoration: const InputDecoration(labelText: 'Join code'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _joinTeam(b2b),
                icon: const Icon(Icons.key),
                label: const Text('Join team'),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team: ${b2b.team!.name}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Join code: ${b2b.team!.joinCode}'),
                      const SizedBox(height: 4),
                      Text('Role của bạn: ${b2b.role?.value ?? 'driver'}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: b2b.team!.joinCode));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã copy join code')));
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy join code'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => b2b.leaveTeam(),
                            icon: const Icon(Icons.exit_to_app),
                            label: const Text('Rời team'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Members (${b2b.members.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...b2b.members.map(
                (m) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(m.displayName),
                  subtitle: Text('${m.email} • ${m.role.value}'),
                  trailing: b2b.canManageTeam ? IconButton(onPressed: () => _pickRole(b2b, m.userId), icon: const Icon(Icons.manage_accounts)) : null,
                ),
              ),
              const Divider(height: 24),
              Text('Team routes (${b2b.routes.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (b2b.routes.isEmpty)
                const Text('Chưa có tuyến nào trong team. Tạo ở Home -> Lưu team.'),
              ...b2b.routes.map(
                (r) => ListTile(
                  leading: const Icon(Icons.alt_route),
                  title: Text(r.name),
                  subtitle: Text('${r.distanceKm.toStringAsFixed(1)} km • ${r.durationMin.toStringAsFixed(0)} phút'),
                  trailing: b2b.canEditRoutes
                      ? IconButton(
                          tooltip: 'Xóa',
                          onPressed: () => b2b.deleteTeamRoute(r.id),
                          icon: const Icon(Icons.delete_outline),
                        )
                      : null,
                ),
              ),
            ],
          ]
        ],
      ),
    );
  }
}
