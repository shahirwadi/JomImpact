import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class OrganizerApprovalScreen extends StatelessWidget {
  const OrganizerApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser!;
    final isRejected =
        user.organizerApprovalStatus == OrganizerApprovalStatus.rejected;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isRejected
                      ? AppTheme.error.withOpacity(0.1)
                      : AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.cancel_outlined : Icons.pending_actions,
                  size: 42,
                  color: isRejected ? AppTheme.error : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isRejected
                    ? 'Organizer access not approved'
                    : 'Organizer account pending approval',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isRejected
                    ? 'An admin rejected your organizer registration. You can review the note below and register again later if needed.'
                    : 'An admin needs to approve your organizer account before you can publish and manage events.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textMedium,
                ),
              ),
              if ((user.approvalNotes ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin note',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.approvalNotes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMedium,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: authVm.refreshCurrentUser,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Approval Status'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: authVm.logout,
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
