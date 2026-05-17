// lib/views/organizer/organizer_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';
import 'organizer_event_detail_screen.dart';
import 'create_event_screen.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});
  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<EventViewModel>().loadOrganizerEvents(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final vm = context.watch<EventViewModel>();
    final user = authVm.currentUser!;

    final published = vm.organizerEvents
        .where((e) => e.status == EventStatus.published)
        .length;
    final totalApplicants =
        vm.organizerEvents.fold(0, (sum, e) => sum + e.currentVolunteers);
    final recentEvents = vm.organizerEvents.take(3).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back,',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMedium)),
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateEventScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text('New Event',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(children: [
                _DashStat(
                  label: 'Total Events',
                  value: '${vm.organizerEvents.length}',
                  icon: Icons.event,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 12),
                _DashStat(
                  label: 'Published',
                  value: '$published',
                  icon: Icons.public,
                  color: const Color(0xFF1565C0),
                ),
                const SizedBox(width: 12),
                _DashStat(
                  label: 'Volunteers',
                  value: '$totalApplicants',
                  icon: Icons.people,
                  color: AppTheme.secondary,
                ),
              ]),
              const SizedBox(height: 24),

              // Quick actions
              const Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 12),
              Row(children: [
                _QuickAction(
                  icon: Icons.add_circle_outline,
                  label: 'Create Event',
                  color: AppTheme.primary,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateEventScreen())),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.bar_chart,
                  label: 'View Stats',
                  color: const Color(0xFF6A1B9A),
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.people_outline,
                  label: 'Applicants',
                  color: AppTheme.secondary,
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 24),

              // Recent events
              SectionHeader(
                title: 'Recent Events',
                action: 'See All',
                onAction: () {},
              ),
              const SizedBox(height: 12),
              if (vm.isLoading)
                const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryLight))
              else if (vm.organizerEvents.isEmpty)
                EmptyState(
                  icon: Icons.event_outlined,
                  title: 'No events yet',
                  message:
                      'Create your first event to start attracting volunteers',
                  actionLabel: 'Create Event',
                  onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateEventScreen())),
                )
              else
                ...recentEvents.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OrgEventTile(
                        event: e,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    OrganizerEventDetailScreen(event: e))),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _DashStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgEventTile extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  const _OrgEventTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryHelper.getColor(event.category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(CategoryHelper.getIcon(event.category),
                  color: catColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.people,
                        size: 12, color: AppTheme.textLight),
                    const SizedBox(width: 3),
                    Text(
                        '${event.currentVolunteers}/${event.maxVolunteers} volunteers',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textLight)),
                  ]),
                ],
              ),
            ),
            EventStatusBadge(status: event.status),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppTheme.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}
