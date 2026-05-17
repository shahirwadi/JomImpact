import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../shared/widgets.dart';

class AdminOrganizerRequestsScreen extends StatefulWidget {
  const AdminOrganizerRequestsScreen({super.key});

  @override
  State<AdminOrganizerRequestsScreen> createState() =>
      _AdminOrganizerRequestsScreenState();
}

class _AdminOrganizerRequestsScreenState
    extends State<AdminOrganizerRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().loadPendingOrganizerRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Organizer Requests'),
        automaticallyImplyLeading: false,
      ),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : vm.pendingOrganizerRequests.isEmpty
              ? EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'No pending requests',
                  message:
                      'New organizer registrations will appear here for review.',
                  actionLabel: 'Refresh',
                  onAction: vm.loadPendingOrganizerRequests,
                )
              : RefreshIndicator(
                  onRefresh: vm.loadPendingOrganizerRequests,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: vm.pendingOrganizerRequests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = vm.pendingOrganizerRequests[index];
                      return _OrganizerRequestCard(user: user);
                    },
                  ),
                ),
    );
  }
}

class _OrganizerRequestCard extends StatelessWidget {
  final UserModel user;

  const _OrganizerRequestCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final notesCtrl = TextEditingController(text: user.approvalNotes ?? '');
    final vm = context.read<AuthViewModel>();

    Future<void> review(OrganizerApprovalStatus status) async {
      final ok = await vm.reviewOrganizerRequest(
        userId: user.id,
        status: status,
        approvalNotes: notesCtrl.text.trim().isEmpty
            ? null
            : notesCtrl.text.trim(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? status == OrganizerApprovalStatus.approved
                    ? 'Organizer approved.'
                    : 'Organizer request rejected.'
                : (vm.error ?? 'Unable to review request.'),
          ),
          backgroundColor: ok ? AppTheme.success : AppTheme.error,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(user.email,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
          if ((user.organization ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.organization!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: notesCtrl,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Admin notes',
              hintText: 'Optional note for approval or rejection',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => review(OrganizerApprovalStatus.rejected),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => review(OrganizerApprovalStatus.approved),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
