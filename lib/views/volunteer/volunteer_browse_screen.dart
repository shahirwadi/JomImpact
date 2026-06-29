// lib/views/volunteer/volunteer_browse_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/malaysia_states.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';
import 'event_detail_screen.dart';
import 'organizer_public_profile_screen.dart';

enum _DiscoverTab { events, organizers }

class VolunteerBrowseScreen extends StatefulWidget {
  const VolunteerBrowseScreen({super.key});
  @override
  State<VolunteerBrowseScreen> createState() => _VolunteerBrowseScreenState();
}

class _VolunteerBrowseScreenState extends State<VolunteerBrowseScreen> {
  final _searchCtrl = TextEditingController();
  _DiscoverTab _selectedTab = _DiscoverTab.events;
  bool _filtersExpanded = false;

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
    final hasActiveFilters = _searchCtrl.text.isNotEmpty ||
        vm.selectedState != null ||
        vm.selectedCategory != null;
    final selectedFilterCount = (vm.selectedState != null ? 1 : 0) +
        (vm.selectedCategory != null ? 1 : 0);

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
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textDark)),
                              const Text('Find your next volunteer opportunity',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMedium)),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: AppTheme.primary, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<_DiscoverTab>(
                        segments: const [
                          ButtonSegment(
                            value: _DiscoverTab.events,
                            icon: Icon(Icons.event_available_outlined),
                            label: Text('Events'),
                          ),
                          ButtonSegment(
                            value: _DiscoverTab.organizers,
                            icon: Icon(Icons.business_outlined),
                            label: Text('Organizers'),
                          ),
                        ],
                        selected: {_selectedTab},
                        onSelectionChanged: (selection) {
                          setState(() => _selectedTab = selection.first);
                        },
                      ),
                    ),
                    if (_selectedTab == _DiscoverTab.events) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Find opportunities',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _searchCtrl,
                              onChanged: vm.setSearchQuery,
                              decoration: InputDecoration(
                                hintText: 'Search events or locations',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppTheme.textLight,
                                ),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Clear search',
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          vm.setSearchQuery('');
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          color: AppTheme.textLight,
                                          size: 18,
                                        ),
                                      )
                                    : null,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Material(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => setState(
                                  () => _filtersExpanded = !_filtersExpanded,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.divider),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.tune,
                                        size: 18,
                                        color: AppTheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        selectedFilterCount == 0
                                            ? 'Filters'
                                            : 'Filters ($selectedFilterCount)',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _filtersExpanded ? 'Hide' : 'Show',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _filtersExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 20,
                                        color: AppTheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              child: _filtersExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                'Refine results',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textMedium,
                                                ),
                                              ),
                                              const Spacer(),
                                              if (hasActiveFilters)
                                                TextButton(
                                                  onPressed: () {
                                                    _searchCtrl.clear();
                                                    vm.setSearchQuery('');
                                                    vm.setStateFilter(null);
                                                    vm.setCategory(null);
                                                  },
                                                  style: TextButton.styleFrom(
                                                    minimumSize: Size.zero,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: const Text('Reset'),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<String>(
                                            value: vm.selectedState ?? '',
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              prefixIcon: Icon(
                                                Icons.location_on_outlined,
                                                color: AppTheme.textLight,
                                                size: 20,
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                            ),
                                            items: [
                                              const DropdownMenuItem<String>(
                                                value: '',
                                                child: Text(
                                                    'Anywhere in Malaysia'),
                                              ),
                                              ...malaysiaStates.map(
                                                (state) => DropdownMenuItem(
                                                  value: state,
                                                  child: Text(state),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) =>
                                                vm.setStateFilter(
                                              value?.isEmpty == true
                                                  ? null
                                                  : value,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Category',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textMedium,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 36,
                                            child: ListView(
                                              scrollDirection: Axis.horizontal,
                                              children: [
                                                _CategoryChip(
                                                  label: 'All',
                                                  selected:
                                                      vm.selectedCategory ==
                                                          null,
                                                  onTap: () =>
                                                      vm.setCategory(null),
                                                ),
                                                ...EventCategory.values.map(
                                                  (cat) => _CategoryChip(
                                                    label:
                                                        CategoryHelper.getName(
                                                            cat),
                                                    icon:
                                                        CategoryHelper.getIcon(
                                                            cat),
                                                    color:
                                                        CategoryHelper.getColor(
                                                            cat),
                                                    selected:
                                                        vm.selectedCategory ==
                                                            cat,
                                                    onTap: () => vm.setCategory(
                                                      vm.selectedCategory == cat
                                                          ? null
                                                          : cat,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (vm.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryLight,
                  ),
                ),
              )
            else if (_selectedTab == _DiscoverTab.events &&
                vm.allEvents.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'No events found',
                  message: 'Try adjusting your search or filters',
                  actionLabel: 'Clear Filters',
                  onAction: () {
                    vm.setCategory(null);
                    vm.setStateFilter(null);
                    vm.setSearchQuery('');
                    _searchCtrl.clear();
                  },
                ),
              )
            else if (_selectedTab == _DiscoverTab.events)
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
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(event: event),
                          ),
                        ),
                      );
                    },
                    childCount: vm.allEvents.length,
                  ),
                ),
              )
            else if (vm.getAllOrganizers().isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.business,
                  title: 'No organizers yet',
                  message: 'Check back soon!',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index.isOdd) return const SizedBox(height: 12);
                      final org = vm.getAllOrganizers()[index ~/ 2];
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
                    childCount: vm.getAllOrganizers().length * 2 - 1,
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

  const _CategoryChip(
      {required this.label,
      this.icon,
      this.color,
      required this.selected,
      required this.onTap});

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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textMedium)),
          ],
        ),
      ),
    );
  }
}
