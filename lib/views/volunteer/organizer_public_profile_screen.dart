// lib/views/volunteer/organizer_public_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';
import 'event_detail_screen.dart';

class OrganizerPublicProfileScreen extends StatelessWidget {
  final UserModel organizer;
  const OrganizerPublicProfileScreen({super.key, required this.organizer});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final events =
        vm.allEvents.where((e) => e.organizerId == organizer.id).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                  ),
                ),
                child: Center(
                    child: Icon(Icons.business,
                        color: Colors.white.withOpacity(0.15), size: 100)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Org header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        NetworkAvatar(
                          imageUrl: organizer.photoUrl,
                          size: 60,
                          fallbackIcon: Icons.business,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(organizer.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textDark)),
                              if (organizer.organization != null)
                                Text(organizer.organization!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textMedium)),
                              if (organizer.location != null)
                                Row(children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 12, color: AppTheme.textLight),
                                  const SizedBox(width: 2),
                                  Text(
                                      [organizer.location, organizer.state]
                                          .whereType<String>()
                                          .where((value) => value.isNotEmpty)
                                          .join(', '),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textLight)),
                                ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(children: [
                    _StatBox(
                        value: '${organizer.totalEvents ?? 0}',
                        label: 'Events\nHosted'),
                    const SizedBox(width: 12),
                    const _StatBox(value: '4.9', label: 'Average\nRating'),
                    const SizedBox(width: 12),
                    _StatBox(
                        value: '${(organizer.totalEvents ?? 0) * 18}',
                        label: 'Volunteers\nImpacted'),
                  ]),
                  const SizedBox(height: 20),

                  if (organizer.bio != null) ...[
                    const Text('About',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 8),
                    Text(organizer.bio!,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                            height: 1.6)),
                    const SizedBox(height: 20),
                  ],

                  const SectionHeader(title: 'Active Events'),
                  const SizedBox(height: 12),
                  if (events.isEmpty)
                    const EmptyState(
                        icon: Icons.event,
                        title: 'No events',
                        message: 'This organizer has no active events.')
                  else
                    ...events.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EventCard(
                              event: e,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          EventDetailScreen(event: e)))),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 10, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }
}
