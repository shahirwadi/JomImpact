// lib/views/organizer/organizer_events_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';
import 'organizer_event_detail_screen.dart';
import 'create_event_screen.dart';

class OrganizerEventsScreen extends StatefulWidget {
  const OrganizerEventsScreen({super.key});
  @override
  State<OrganizerEventsScreen> createState() => _OrganizerEventsScreenState();
}

class _OrganizerEventsScreenState extends State<OrganizerEventsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null)
        context.read<EventViewModel>().loadOrganizerEvents(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Events'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen())),
            icon: const Icon(Icons.add),
            tooltip: 'Create Event',
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryLight))
          : vm.organizerEvents.isEmpty
              ? EmptyState(
                  icon: Icons.event_outlined,
                  title: 'No events yet',
                  message:
                      'Create your first event to start attracting volunteers!',
                  actionLabel: 'Create Event',
                  onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateEventScreen())),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: vm.organizerEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final event = vm.organizerEvents[i];
                    final catColor = CategoryHelper.getColor(event.category);
                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  OrganizerEventDetailScreen(event: event))),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: catColor,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(event.title,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textDark),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      const SizedBox(width: 8),
                                      EventStatusBadge(status: event.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 12, color: AppTheme.textLight),
                                    const SizedBox(width: 4),
                                    Expanded(
                                        child: Text(event.location,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textLight),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)),
                                  ]),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _MiniStat(
                                        icon: Icons.people_outline,
                                        value:
                                            '${event.currentVolunteers}/${event.maxVolunteers}',
                                        label: 'Volunteers',
                                        color: catColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value:
                                                event.fillRate.clamp(0.0, 1.0),
                                            backgroundColor: AppTheme.divider,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    catColor),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MiniStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
      ],
    );
  }
}
