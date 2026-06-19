// lib/views/volunteer/volunteer_my_events_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';

class VolunteerMyEventsScreen extends StatefulWidget {
  const VolunteerMyEventsScreen({super.key});
  @override
  State<VolunteerMyEventsScreen> createState() =>
      _VolunteerMyEventsScreenState();
}

class _VolunteerMyEventsScreenState extends State<VolunteerMyEventsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<EventViewModel>().loadVolunteerApplications(user.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final query = _searchQuery.trim().toLowerCase();
    final applications = query.isEmpty
        ? vm.applications
        : vm.applications.where((app) {
            final status = _applicationStatusLabel(app.status).toLowerCase();
            final attendance =
                _attendanceLabel(app.attendanceStatus).toLowerCase();
            return app.eventTitle.toLowerCase().contains(query) ||
                status.contains(query) ||
                attendance.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Applications'),
        automaticallyImplyLeading: false,
      ),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryLight))
          : vm.applications.isEmpty
              ? const EmptyState(
                  icon: Icons.bookmark_outline,
                  title: 'No applications yet',
                  message: 'Browse events and apply to start volunteering!')
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search applications or status',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: applications.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off,
                              title: 'No matching applications',
                              message:
                                  'Try another event, status, or attendance result.',
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 20),
                              itemCount: applications.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (ctx, i) {
                                final app = applications[i];
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.divider),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(app.eventTitle,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textDark)),
                                          ),
                                          StatusBadge(status: app.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 12,
                                            color: AppTheme.textLight),
                                        const SizedBox(width: 4),
                                        Text(
                                            'Applied ${DateFormat('d MMM yyyy').format(app.appliedAt)}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textLight)),
                                      ]),
                                      if (app.message != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surface,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.format_quote,
                                                  size: 14,
                                                  color: AppTheme.textLight),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                  child: Text(app.message!,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AppTheme
                                                              .textMedium,
                                                          fontStyle: FontStyle
                                                              .italic))),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (app.attendanceStatus !=
                                          AttendanceStatus.pending) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.06),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(children: [
                                            const Icon(Icons.verified_outlined,
                                                size: 16,
                                                color: AppTheme.primary),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${_attendanceLabel(app.attendanceStatus)} · ${app.verifiedHours} verified hours',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.textMedium),
                                              ),
                                            ),
                                            if (app.pointsAwardedAt != null)
                                              Text('+${app.impactPoints} pts',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppTheme.primary)),
                                          ]),
                                        ),
                                      ],
                                      if (app.status !=
                                              ApplicationStatus.withdrawn &&
                                          app.status !=
                                              ApplicationStatus.rejected) ...[
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                _withdraw(context, vm, app.id),
                                            icon: const Icon(Icons.undo,
                                                size: 16),
                                            label: const Text(
                                                'Withdraw application'),
                                            style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppTheme.error),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _withdraw(
      BuildContext context, EventViewModel vm, String appId) async {
    final volunteerId = context.read<AuthViewModel>().currentUser!.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw application?'),
        content: const Text(
            'The organizer will see that you withdrew. You cannot apply again to this event.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep application')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Withdraw')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await vm.withdrawApplication(appId, volunteerId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          ok ? 'Application withdrawn' : (vm.error ?? 'Unable to withdraw')),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    ));
  }

  String _attendanceLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.pending:
        return 'Pending';
      case AttendanceStatus.attended:
        return 'Attended';
      case AttendanceStatus.partial:
        return 'Partially attended';
      case AttendanceStatus.noShow:
        return 'No-show';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  String _applicationStatusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'New';
      case ApplicationStatus.reviewing:
        return 'Reviewing';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.waitlisted:
        return 'Waitlisted';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}
