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
  State<OrganizerEventDetailScreen> createState() => _OrganizerEventDetailScreenState();
}

class _OrganizerEventDetailScreenState extends State<OrganizerEventDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EventModel _event;

  bool get _isEventFinished =>
      _event.status == EventStatus.completed ||
      DateTime.now().isAfter(_event.endDate);

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshEventData();
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
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

  Future<void> _refreshEventData() async {
    final vm = context.read<EventViewModel>();
    await vm.loadApplicationsForEvent(_event.id);
    await vm.loadVolunteerHourRecordsForEvent(_event.id);
  }

  Future<void> _markEventCompleted() async {
    final vm = context.read<EventViewModel>();
    final updated = _event.copyWith(status: EventStatus.completed);
    final success = await vm.updateEvent(updated);
    if (!mounted) return;
    if (success) {
      setState(() => _event = updated);
      await vm.loadVolunteerHourRecordsForEvent(_event.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event marked as completed.')),
      );
    } else if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error!)),
      );
    }
  }

  Future<void> _showSetHoursDialog(ApplicationModel app) async {
    final vm = context.read<EventViewModel>();
    final existingRecord = vm.getHourRecordForVolunteer(app.volunteerId);
    final hoursCtrl = TextEditingController(
      text: existingRecord?.hours.toString() ?? '',
    );

    final hours = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existingRecord == null
              ? 'Set Volunteer Hours'
              : 'Update Volunteer Hours',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign hours for ${app.volunteerName} after this event.',
              style: const TextStyle(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hoursCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Volunteer hours',
                hintText: 'e.g. 4',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(hoursCtrl.text.trim());
              Navigator.pop(ctx, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (hours == null) return;

    final success = await vm.setVolunteerHours(
      event: _event,
      application: app,
      hours: hours,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Volunteer hours saved. Approve them when you are ready.'
              : (vm.error ?? 'Unable to save volunteer hours.'),
        ),
      ),
    );
  }

  Future<void> _approveHours(VolunteerHourRecord record) async {
    final vm = context.read<EventViewModel>();
    final success = await vm.approveVolunteerHours(
      recordId: record.id,
      eventId: _event.id,
      volunteerId: record.volunteerId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Volunteer hours approved and added to the profile.'
              : (vm.error ?? 'Unable to approve volunteer hours.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final catColor = CategoryHelper.getColor(_event.category);
    final pending = vm.applications.where((a) => a.status == ApplicationStatus.pending).length;

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
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CreateEventScreen(eventToEdit: _event))),
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
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        EventStatusBadge(status: _event.status),
                        const SizedBox(height: 6),
                        Text(_event.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
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
                Tab(text: pending > 0 ? 'Applicants ($pending pending)' : 'Applicants'),
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
                    _EventStat(label: 'Volunteers', value: '${_event.currentVolunteers}', icon: Icons.people, color: catColor),
                    const SizedBox(width: 10),
                    _EventStat(label: 'Capacity', value: '${_event.maxVolunteers}', icon: Icons.event_seat, color: const Color(0xFF1565C0)),
                    const SizedBox(width: 10),
                    _EventStat(label: 'Spots Left', value: '${_event.spotsLeft}', icon: Icons.chair_outlined,
                      color: _event.isFull ? AppTheme.error : AppTheme.success),
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
                            const Text('Registration Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('${(_event.fillRate * 100).toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: catColor)),
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

                  if (_event.status != EventStatus.completed &&
                      _event.status != EventStatus.cancelled &&
                      DateTime.now().isAfter(_event.endDate)) ...[
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
                          const Text(
                            'Event finished',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Mark this event as completed before finalizing volunteer hours.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: vm.isLoading ? null : _markEventCompleted,
                            icon: const Icon(Icons.task_alt),
                            label: const Text('Mark Event Completed'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                        _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: _event.location),
                        _DetailRow(icon: Icons.calendar_today_outlined, label: 'Start', value: DateFormat('d MMM yyyy, h:mm a').format(_event.startDate)),
                        _DetailRow(icon: Icons.access_time, label: 'End', value: DateFormat('d MMM yyyy, h:mm a').format(_event.endDate)),
                        _DetailRow(icon: CategoryHelper.getIcon(_event.category), label: 'Category', value: CategoryHelper.getName(_event.category)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  Text(_event.description, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium, height: 1.6)),
                ],
              ),
            ),

            // ── Applicants Tab ──
            vm.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
                : vm.applications.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline,
                        title: 'No applicants yet',
                        message: 'Applications will appear here once volunteers apply')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.applications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final app = vm.applications[i];
                          final hourRecord =
                              vm.getHourRecordForVolunteer(app.volunteerId);
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(app.volunteerName,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                                          Text(DateFormat('d MMM yyyy').format(app.appliedAt),
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(status: app.status),
                                  ],
                                ),
                                if (app.volunteerBio != null) ...[
                                  const SizedBox(height: 8),
                                  Text(app.volunteerBio!,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
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
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMedium, fontStyle: FontStyle.italic)),
                                  ),
                                ],
                                if (app.status == ApplicationStatus.pending) ...[
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => vm.updateApplicationStatus(app.id, ApplicationStatus.rejected, _event.id),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 36),
                                          foregroundColor: AppTheme.error,
                                          side: const BorderSide(color: AppTheme.error),
                                        ),
                                        child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => vm.updateApplicationStatus(app.id, ApplicationStatus.accepted, _event.id),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(0, 36),
                                          backgroundColor: AppTheme.success,
                                        ),
                                        child: const Text('Accept', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ]),
                                ],
                                if (app.status == ApplicationStatus.accepted &&
                                    _isEventFinished) ...[
                                  const SizedBox(height: 12),
                                  Builder(
                                    builder: (_) {
                                      final record = hourRecord;
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.schedule_outlined,
                                                  size: 16,
                                                  color: AppTheme.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    record == null
                                                        ? 'Volunteer hours not set yet'
                                                        : '${record.hours} volunteer hour${record.hours == 1 ? '' : 's'}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppTheme.textDark,
                                                    ),
                                                  ),
                                                ),
                                                if (record != null)
                                                  _HourApprovalBadge(
                                                    status: record.status,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed:
                                                        record?.isApproved ==
                                                                true
                                                            ? null
                                                            : () =>
                                                                _showSetHoursDialog(
                                                                  app,
                                                                ),
                                                    child: Text(
                                                      record == null
                                                          ? 'Set Hours'
                                                          : 'Edit Hours',
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: record == null ||
                                                            record.isApproved
                                                        ? null
                                                        : () => _approveHours(
                                                              record,
                                                            ),
                                                    child: Text(
                                                      record?.isApproved ==
                                                              true
                                                          ? 'Approved'
                                                          : 'Approve Hours',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
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

class _HourApprovalBadge extends StatelessWidget {
  final VolunteerHourApprovalStatus status;

  const _HourApprovalBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isApproved = status == VolunteerHourApprovalStatus.approved;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isApproved ? 'Approved' : 'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isApproved ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}

class _EventStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _EventStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textLight),
          const SizedBox(width: 10),
          SizedBox(width: 72, child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMedium))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
        ],
      ),
    );
  }
}
