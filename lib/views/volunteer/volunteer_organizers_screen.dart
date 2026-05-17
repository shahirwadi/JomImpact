// lib/views/volunteer/volunteer_organizers_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_theme.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';
import 'organizer_public_profile_screen.dart';

class VolunteerOrganizersScreen extends StatefulWidget {
  const VolunteerOrganizersScreen({super.key});

  @override
  State<VolunteerOrganizersScreen> createState() =>
      _VolunteerOrganizersScreenState();
}

class _VolunteerOrganizersScreenState extends State<VolunteerOrganizersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventViewModel>().loadOrganizers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final organizers = vm.getAllOrganizers();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Organizers'),
        automaticallyImplyLeading: false,
      ),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : organizers.isEmpty
              ? const EmptyState(
                  icon: Icons.business,
                  title: 'No organizers yet',
                  message: 'Check back soon!')
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: organizers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final org = organizers[i];
                    return OrganizerCard(
                      organizer: org,
                      eventCount: org.totalEvents ?? 0,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrganizerPublicProfileScreen(organizer: org),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
