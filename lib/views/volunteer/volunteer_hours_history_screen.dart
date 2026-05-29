import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/event_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';

class VolunteerHoursHistoryScreen extends StatefulWidget {
  const VolunteerHoursHistoryScreen({super.key});

  @override
  State<VolunteerHoursHistoryScreen> createState() =>
      _VolunteerHoursHistoryScreenState();
}

class _VolunteerHoursHistoryScreenState
    extends State<VolunteerHoursHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<EventViewModel>().loadVolunteerHourHistory(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final totalHours = vm.volunteerHourHistory.fold<int>(
      0,
      (sum, record) => sum + record.hours,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Volunteer Hours'),
      ),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryLight),
            )
          : vm.volunteerHourHistory.isEmpty
              ? const EmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'No approved hours yet',
                  message:
                      'Your approved volunteer hour history will appear here after organizers finalize completed events.',
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Approved volunteer hours',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMedium,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$totalHours hours',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vm.volunteerHourHistory.length} completed event${vm.volunteerHourHistory.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: vm.volunteerHourHistory.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final record = vm.volunteerHourHistory[index];
                          return _HourHistoryCard(record: record);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _HourHistoryCard extends StatelessWidget {
  final VolunteerHourRecord record;

  const _HourHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  record.eventTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${record.hours} hour${record.hours == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.event_available,
                size: 14,
                color: AppTheme.textLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Event ended ${DateFormat('d MMM yyyy, h:mm a').format(record.eventEndDate)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 14,
                color: AppTheme.textLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Approved ${DateFormat('d MMM yyyy').format(record.approvedAt ?? record.assignedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
