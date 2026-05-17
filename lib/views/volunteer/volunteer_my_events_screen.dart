// lib/views/volunteer/volunteer_my_events_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';

class VolunteerMyEventsScreen extends StatefulWidget {
  const VolunteerMyEventsScreen({super.key});
  @override
  State<VolunteerMyEventsScreen> createState() => _VolunteerMyEventsScreenState();
}

class _VolunteerMyEventsScreenState extends State<VolunteerMyEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) context.read<EventViewModel>().loadVolunteerApplications(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Applications'),
        automaticallyImplyLeading: false,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
          : vm.applications.isEmpty
              ? const EmptyState(
                  icon: Icons.bookmark_outline,
                  title: 'No applications yet',
                  message: 'Browse events and apply to start volunteering!')
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: vm.applications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final app = vm.applications[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(app.eventTitle,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                              ),
                              StatusBadge(status: app.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textLight),
                            const SizedBox(width: 4),
                            Text('Applied ${DateFormat('d MMM yyyy').format(app.appliedAt)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                          ]),
                          if (app.message != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.format_quote, size: 14, color: AppTheme.textLight),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(app.message!,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMedium, fontStyle: FontStyle.italic))),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
