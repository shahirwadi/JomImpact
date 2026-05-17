// lib/views/volunteer/volunteer_browse_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';
import 'event_detail_screen.dart';

class VolunteerBrowseScreen extends StatefulWidget {
  const VolunteerBrowseScreen({super.key});
  @override
  State<VolunteerBrowseScreen> createState() => _VolunteerBrowseScreenState();
}

class _VolunteerBrowseScreenState extends State<VolunteerBrowseScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventViewModel>().loadAllEvents();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hello, ${user.name.split(' ')[0]}! 👋',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                              const Text('Find your next volunteer opportunity',
                                style: TextStyle(fontSize: 13, color: AppTheme.textMedium)),
                            ],
                          ),
                        ),
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.notifications_outlined, color: AppTheme.primary, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    TextField(
                      controller: _searchCtrl,
                      onChanged: vm.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search events, locations...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                onPressed: () { _searchCtrl.clear(); vm.setSearchQuery(''); },
                                icon: const Icon(Icons.close, color: AppTheme.textLight, size: 18))
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Category chips
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _CategoryChip(label: 'All', selected: vm.selectedCategory == null, onTap: () => vm.setCategory(null)),
                          ...EventCategory.values.map((cat) => _CategoryChip(
                            label: CategoryHelper.getName(cat),
                            icon: CategoryHelper.getIcon(cat),
                            color: CategoryHelper.getColor(cat),
                            selected: vm.selectedCategory == cat,
                            onTap: () => vm.setCategory(vm.selectedCategory == cat ? null : cat),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            if (vm.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryLight)))
            else if (vm.allEvents.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'No events found',
                  message: 'Try adjusting your search or filters',
                  actionLabel: 'Clear Filters',
                  onAction: () { vm.setCategory(null); vm.setSearchQuery(''); _searchCtrl.clear(); },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final event = vm.allEvents[i];
                      return EventCard(
                        event: event,
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
                      );
                    },
                    childCount: vm.allEvents.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, this.icon, this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? Colors.white : c),
              const SizedBox(width: 4),
            ],
            Text(label,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textMedium)),
          ],
        ),
      ),
    );
  }
}
