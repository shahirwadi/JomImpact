// lib/views/organizer/organizer_event_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';
import 'create_event_screen.dart';

class OrganizerEventDetailScreen extends StatefulWidget {
  final EventModel event;
  const OrganizerEventDetailScreen({super.key, required this.event});
  @override
  State<OrganizerEventDetailScreen> createState() =>
      _OrganizerEventDetailScreenState();
}

class _OrganizerEventDetailScreenState extends State<OrganizerEventDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EventModel _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventViewModel>().loadApplicationsForEvent(_event.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final authVm = context.read<AuthViewModel>();
      final vm = context.read<EventViewModel>();
      await vm.deleteEvent(_event.id, authVm.currentUser!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _markCompleted() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete event?'),
        content: const Text(
            'Applications will close and attendance review will begin.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Complete event')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final vm = context.read<EventViewModel>();
    final ok = await vm.markEventCompleted(_event.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _event = _event.copyWith(status: EventStatus.completed));
      _tabController.animateTo(2);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Attendance review is now open'
          : (vm.error ?? 'Unable to complete event')),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final catColor = CategoryHelper.getColor(_event.category);
    final pending = vm.applications
        .where((a) => a.status == ApplicationStatus.pending)
        .length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: catColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CreateEventScreen(eventToEdit: _event))),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _deleteEvent,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  EventBannerImage(
                    imageUrl: _event.imageUrl,
                    category: _event.category,
                    borderRadius: BorderRadius.zero,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        EventStatusBadge(status: _event.status),
                        const SizedBox(height: 6),
                        Text(_event.title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                const Tab(text: 'Overview'),
                Tab(
                    text: pending > 0
                        ? 'Applicants ($pending pending)'
                        : 'Applicants'),
                const Tab(text: 'Attendance'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Overview Tab ──
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(children: [
                    _EventStat(
                        label: 'Volunteers',
                        value: '${_event.currentVolunteers}',
                        icon: Icons.people,
                        color: catColor),
                    const SizedBox(width: 10),
                    _EventStat(
                        label: 'Capacity',
                        value: '${_event.maxVolunteers}',
                        icon: Icons.event_seat,
                        color: const Color(0xFF1565C0)),
                    const SizedBox(width: 10),
                    _EventStat(
                        label: 'Spots Left',
                        value: '${_event.spotsLeft}',
                        icon: Icons.chair_outlined,
                        color:
                            _event.isFull ? AppTheme.error : AppTheme.success),
                  ]),
                  const SizedBox(height: 16),

                  // Fill progress
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Registration Progress',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(
                                '${(_event.fillRate * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: catColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _event.fillRate.clamp(0.0, 1.0),
                            backgroundColor: AppTheme.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(catColor),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: [_event.location, _event.state]
                                .whereType<String>()
                                .where((value) => value.isNotEmpty)
                                .join(', ')),
                        _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Start',
                            value: DateFormat('d MMM yyyy, h:mm a')
                                .format(_event.startDate)),
                        _DetailRow(
                            icon: Icons.access_time,
                            label: 'End',
                            value: DateFormat('d MMM yyyy, h:mm a')
                                .format(_event.endDate)),
                        _DetailRow(
                            icon: CategoryHelper.getIcon(_event.category),
                            label: 'Category',
                            value: CategoryHelper.getName(_event.category)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Description',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  Text(_event.description,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMedium,
                          height: 1.6)),
                  if (_event.status != EventStatus.completed &&
                      _event.status != EventStatus.finalized &&
                      _event.status != EventStatus.cancelled) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _markCompleted,
                      icon: const Icon(Icons.task_alt),
                      label: const Text('Mark Event Completed'),
                    ),
                  ],
                ],
              ),
            ),

            // ── Applicants Tab ──
            _ApplicationPipeline(event: _event),
            _AttendanceReview(
              event: _event,
              onFinalized: () => setState(() => _event = _event.copyWith(
                  status: EventStatus.finalized, finalizedAt: DateTime.now())),
            ),
            if (_showLegacyApplicants)
              vm.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryLight))
                  : vm.applications.isEmpty
                      ? const EmptyState(
                          icon: Icons.people_outline,
                          title: 'No applicants yet',
                          message:
                              'Applications will appear here once volunteers apply')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: vm.applications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
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
                                      NetworkAvatar(
                                        imageUrl: app.volunteerPhotoUrl,
                                        size: 40,
                                        fallbackIcon: Icons.person,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(app.volunteerName,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textDark)),
                                            Text(
                                                DateFormat('d MMM yyyy')
                                                    .format(app.appliedAt),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.textLight)),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(status: app.status),
                                    ],
                                  ),
                                  if (app.volunteerBio != null) ...[
                                    const SizedBox(height: 8),
                                    Text(app.volunteerBio!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMedium),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                  if (app.message != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('"${app.message!}"',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMedium,
                                              fontStyle: FontStyle.italic)),
                                    ),
                                  ],
                                  if (app.status ==
                                      ApplicationStatus.pending) ...[
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              vm.updateApplicationStatus(
                                                  app.id,
                                                  ApplicationStatus.rejected,
                                                  _event.id,
                                                  reviewedBy: context
                                                      .read<AuthViewModel>()
                                                      .currentUser!
                                                      .id),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 36),
                                            foregroundColor: AppTheme.error,
                                            side: const BorderSide(
                                                color: AppTheme.error),
                                          ),
                                          child: const Text('Reject',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              vm.updateApplicationStatus(
                                                  app.id,
                                                  ApplicationStatus.accepted,
                                                  _event.id,
                                                  reviewedBy: context
                                                      .read<AuthViewModel>()
                                                      .currentUser!
                                                      .id),
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(0, 36),
                                            backgroundColor: AppTheme.success,
                                          ),
                                          child: const Text('Accept',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                    ]),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationPipeline extends StatefulWidget {
  final EventModel event;
  const _ApplicationPipeline({required this.event});

  @override
  State<_ApplicationPipeline> createState() => _ApplicationPipelineState();
}

bool get _showLegacyApplicants => false;

class _AttendanceReview extends StatelessWidget {
  final EventModel event;
  final VoidCallback onFinalized;

  const _AttendanceReview({
    required this.event,
    required this.onFinalized,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final accepted = vm.applications
        .where((app) => app.status == ApplicationStatus.accepted)
        .toList();
    final reviewed = accepted
        .where((app) => app.attendanceStatus != AttendanceStatus.pending)
        .length;

    if (event.status != EventStatus.completed &&
        event.status != EventStatus.finalized) {
      return const EmptyState(
        icon: Icons.fact_check_outlined,
        title: 'Attendance opens after completion',
        message: 'Mark the event completed when it has finished.',
      );
    }

    return Column(children: [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.status == EventStatus.finalized
                    ? 'Awards finalized'
                    : '$reviewed of ${accepted.length} reviewed'),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: accepted.isEmpty ? 1 : reviewed / accepted.length,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(7),
                  backgroundColor: AppTheme.divider,
                  color: AppTheme.success,
                ),
              ],
            ),
          ),
          if (event.status == EventStatus.completed) ...[
            const SizedBox(width: 12),
            FilledButton(
              onPressed: reviewed == accepted.length
                  ? () => _finalize(context, vm)
                  : null,
              child: const Text('Finalize'),
            ),
          ],
        ]),
      ),
      Expanded(
        child: accepted.isEmpty
            ? const EmptyState(
                icon: Icons.people_outline,
                title: 'No accepted volunteers',
                message: 'This event can be finalized without awards.')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: accepted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final app = accepted[index];
                  final points =
                      app.attendanceStatus == AttendanceStatus.attended ||
                              app.attendanceStatus == AttendanceStatus.partial
                          ? app.verifiedHours * 10
                          : 0;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(children: [
                      NetworkAvatar(
                          imageUrl: app.volunteerPhotoUrl,
                          size: 40,
                          fallbackIcon: Icons.person),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app.volunteerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark)),
                            const SizedBox(height: 3),
                            Text(
                              app.attendanceStatus == AttendanceStatus.pending
                                  ? 'Not reviewed'
                                  : '${_attendanceLabel(app.attendanceStatus)} · ${app.verifiedHours}h · $points pts',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      ),
                      if (event.status == EventStatus.completed)
                        TextButton(
                          onPressed: () => _review(context, vm, app),
                          child: Text(
                              app.attendanceStatus == AttendanceStatus.pending
                                  ? 'Review'
                                  : 'Edit'),
                        )
                      else
                        const Icon(Icons.verified,
                            color: AppTheme.success, size: 20),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  Future<void> _review(
      BuildContext context, EventViewModel vm, ApplicationModel app) async {
    var status = app.attendanceStatus == AttendanceStatus.pending
        ? AttendanceStatus.attended
        : app.attendanceStatus;
    final eventHours = event.endDate.difference(event.startDate).inMinutes / 60;
    final hours = TextEditingController(
        text: app.verifiedHours > 0
            ? app.verifiedHours.toString()
            : eventHours.ceil().toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Review ${app.volunteerName}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<AttendanceStatus>(
              value: status,
              decoration: const InputDecoration(labelText: 'Attendance'),
              items: AttendanceStatus.values
                  .where((item) => item != AttendanceStatus.pending)
                  .map((item) => DropdownMenuItem(
                      value: item, child: Text(_attendanceLabel(item))))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() {
                  status = value;
                  if (value == AttendanceStatus.noShow ||
                      value == AttendanceStatus.excused) {
                    hours.text = '0';
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hours,
              enabled: status == AttendanceStatus.attended ||
                  status == AttendanceStatus.partial,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Verified hours', suffixText: 'hours'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  '${(int.tryParse(hours.text) ?? 0) * 10} impact points',
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textLight)),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save review')),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await vm.reviewAttendance(
      appId: app.id,
      attendanceStatus: status,
      verifiedHours: int.tryParse(hours.text) ?? 0,
      reviewedBy: context.read<AuthViewModel>().currentUser!.id,
      eventId: event.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Attendance saved' : (vm.error ?? 'Unable to save')),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    ));
  }

  Future<void> _finalize(BuildContext context, EventViewModel vm) async {
    final organizerId = context.read<AuthViewModel>().currentUser!.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalize awards?'),
        content: const Text(
            'Verified hours and impact points will be locked and issued. This cannot be edited afterward.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Finalize awards')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await vm.finalizeEvent(event.id, organizerId);
    if (!context.mounted) return;
    if (ok) onFinalized();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          ok ? 'Impact awards issued' : (vm.error ?? 'Unable to finalize')),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    ));
  }

  static String _attendanceLabel(AttendanceStatus status) {
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
}

class _ApplicationPipelineState extends State<_ApplicationPipeline> {
  ApplicationStatus? _filter;
  String _query = '';
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final reviewerId = context.read<AuthViewModel>().currentUser!.id;
    final filteredApplications = vm.applications
        .where((app) => _filter == null || app.status == _filter)
        .toList();
    final applications = filteredApplications.where((app) {
      final query = _query.trim().toLowerCase();
      return query.isEmpty ||
          app.volunteerName.toLowerCase().contains(query) ||
          (app.volunteerBio?.toLowerCase().contains(query) ?? false);
    }).toList();
    final canAccept = vm.applications
            .where((app) => app.status == ApplicationStatus.accepted)
            .length <
        widget.event.maxVolunteers;

    if (vm.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryLight));
    }
    if (vm.applications.isEmpty) {
      return const EmptyState(
          icon: Icons.people_outline,
          title: 'No applicants yet',
          message: 'Applications will appear here once volunteers apply');
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
              hintText: 'Search applicants',
              prefixIcon: Icon(Icons.search),
              isDense: true),
        ),
      ),
      SizedBox(
        height: 46,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            _filterChip(null, 'All', vm.applications.length),
            for (final status in ApplicationStatus.values)
              _filterChip(status, _statusLabel(status),
                  vm.applications.where((a) => a.status == status).length),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        child: OutlinedButton.icon(
          onPressed: filteredApplications.isEmpty || _isExporting
              ? null
              : () => _export(context, vm, filteredApplications),
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_outlined),
          label: Text(
            'Download ${_activeFilterLabel()} (${filteredApplications.length})',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 42),
          ),
        ),
      ),
      Expanded(
        child: applications.isEmpty
            ? const EmptyState(
                icon: Icons.filter_alt_off,
                title: 'No matching applicants',
                message: 'Try another status or search term')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: applications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _applicantCard(
                    context, vm, applications[index], reviewerId, canAccept),
              ),
      ),
    ]);
  }

  Widget _filterChip(ApplicationStatus? status, String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: _filter == status,
        label: Text('$label $count'),
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    EventViewModel vm,
    List<ApplicationModel> applications,
  ) async {
    setState(() => _isExporting = true);
    try {
      await vm.exportApplications(
        event: widget.event,
        applications: applications,
        filterLabel: _activeFilterLabel(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '${_activeFilterLabel()} volunteer list downloaded.',
        ),
        backgroundColor: AppTheme.success,
      ));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unable to download volunteer list: $error'),
        backgroundColor: AppTheme.error,
      ));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _activeFilterLabel() =>
      _filter == null ? 'All' : _statusLabel(_filter!);

  Widget _applicantCard(BuildContext context, EventViewModel vm,
      ApplicationModel app, String reviewerId, bool canAccept) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          NetworkAvatar(
              imageUrl: app.volunteerPhotoUrl,
              size: 40,
              fallbackIcon: Icons.person),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.volunteerName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                Text(
                    'Applied ${DateFormat('d MMM yyyy').format(app.appliedAt)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textLight)),
              ],
            ),
          ),
          StatusBadge(status: app.status),
          if (app.status != ApplicationStatus.withdrawn &&
              widget.event.status != EventStatus.completed &&
              widget.event.status != EventStatus.finalized)
            PopupMenuButton<ApplicationStatus>(
              tooltip: 'Change status',
              onSelected: (status) =>
                  _review(context, vm, app, status, reviewerId),
              itemBuilder: (_) => ApplicationStatus.values
                  .where((status) =>
                      status != ApplicationStatus.withdrawn &&
                      status != app.status)
                  .map((status) => PopupMenuItem(
                        value: status,
                        enabled: status != ApplicationStatus.accepted ||
                            app.status == ApplicationStatus.accepted ||
                            canAccept,
                        child: Text(_statusLabel(status)),
                      ))
                  .toList(),
            ),
        ]),
        if (app.volunteerBio?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(app.volunteerBio!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
        ],
        if (app.message?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text('"${app.message}"',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMedium,
                  fontStyle: FontStyle.italic)),
        ],
        if (app.reviewNotes?.isNotEmpty == true) ...[
          const Divider(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.lock_outline, size: 14, color: AppTheme.textLight),
            const SizedBox(width: 6),
            Expanded(
                child: Text(app.reviewNotes!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMedium))),
          ]),
        ],
        if (app.reviewedAt != null) ...[
          const SizedBox(height: 6),
          Text(
              'Updated ${DateFormat('d MMM yyyy, h:mm a').format(app.reviewedAt!)}',
              style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
        ],
      ]),
    );
  }

  Future<void> _review(BuildContext context, EventViewModel vm,
      ApplicationModel app, ApplicationStatus status, String reviewerId) async {
    final notes = TextEditingController(text: app.reviewNotes);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Move to ${_statusLabel(status)}'),
        content: TextField(
          controller: notes,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
              labelText: 'Private review notes (optional)',
              alignLabelWithHint: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Update')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await vm.updateApplicationStatus(app.id, status, widget.event.id,
        reviewedBy: reviewerId, reviewNotes: notes.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Application updated' : (vm.error ?? 'Update failed')),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    ));
  }

  String _statusLabel(ApplicationStatus status) {
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

class _EventStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _EventStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textLight),
          const SizedBox(width: 10),
          SizedBox(
              width: 72,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMedium))),
          Expanded(
              child: Text(value,
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textDark))),
        ],
      ),
    );
  }
}
