// lib/views/volunteer/event_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/enum_utils.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});
  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventModel _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  Future<void> _showApplyDialog() async {
    final msgCtrl = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Apply for Event',
                style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(_event.title,
                style:
                    const TextStyle(color: AppTheme.textMedium, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message to organizer (optional)',
                hintText: 'Share why you want to join...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit Application'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final vm = context.read<EventViewModel>();
      final authVm = context.read<AuthViewModel>();
      final ok = await vm.applyForEvent(
        eventId: _event.id,
        eventTitle: _event.title,
        volunteer: authVm.currentUser!,
        message: msgCtrl.text.trim().isEmpty ? null : msgCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Application submitted successfully.'
              : (vm.error ?? 'Unable to submit application.')),
          backgroundColor: ok ? AppTheme.success : AppTheme.warning,
        ));
        if (ok) {
          setState(() {
            _event = _event.copyWith(
                currentVolunteers: _event.currentVolunteers + 1);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;
    final catColor = CategoryHelper.getColor(_event.category);
    final isVolunteer =
        user != null && enumValueName(user.role) == 'volunteer';
    final hasApplied = isVolunteer && vm.hasApplied(_event.id, user!.id);
    final appStatus =
        isVolunteer ? vm.getApplicationStatus(_event.id, user!.id) : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: catColor,
            flexibleSpace: FlexibleSpaceBar(
              background: EventBannerImage(
                imageUrl: _event.imageUrl,
                category: _event.category,
                borderRadius: BorderRadius.zero,
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CategoryHelper.getIcon(_event.category),
                                size: 12, color: catColor),
                            const SizedBox(width: 4),
                            Text(CategoryHelper.getName(_event.category),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: catColor)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (hasApplied && appStatus != null)
                        StatusBadge(status: appStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_event.title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 12),

                  // Info chips
                  _InfoRow(
                      icon: Icons.location_on_outlined, text: _event.location),
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: DateFormat('d MMM yyyy, h:mm a')
                          .format(_event.startDate)),
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.access_time_outlined,
                      text:
                          'Until ${DateFormat('h:mm a').format(_event.endDate)}'),
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.business_outlined,
                      text: _event.organizerName),
                  const SizedBox(height: 16),

                  // Volunteer count
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
                            const Text('Volunteer Spots',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark)),
                            Text(
                                '${_event.currentVolunteers}/${_event.maxVolunteers}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: catColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _event.fillRate.clamp(0.0, 1.0),
                            backgroundColor: AppTheme.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _event.isFull ? Colors.red.shade600 : catColor),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                            _event.isFull
                                ? 'Fully booked'
                                : '${_event.spotsLeft} spots remaining',
                            style: TextStyle(
                                fontSize: 12,
                                color: _event.isFull
                                    ? Colors.red.shade600
                                    : AppTheme.textMedium)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text('About this Event',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  Text(_event.description,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMedium,
                          height: 1.6)),
                  const SizedBox(height: 20),

                  if (_event.requirements.isNotEmpty) ...[
                    const Text('Requirements',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 10),
                    ..._event.requirements.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: catColor, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(r,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textMedium))),
                          ]),
                        )),
                    const SizedBox(height: 16),
                  ],

                  if (_event.benefits.isNotEmpty) ...[
                    const Text('What You Get',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 10),
                    ..._event.benefits.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            Icon(Icons.check_circle, color: catColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(b,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textMedium))),
                          ]),
                        )),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isVolunteer
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.divider)),
              ),
              child: hasApplied
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.success.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.success, size: 18),
                          SizedBox(width: 8),
                          Text('Application Submitted',
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _event.isFull ? null : _showApplyDialog,
                      icon: const Icon(Icons.volunteer_activism, size: 18),
                      label: Text(
                          _event.isFull ? 'Event Full' : 'Apply to Volunteer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _event.isFull
                            ? AppTheme.textLight
                            : AppTheme.primary,
                      ),
                    ),
            )
          : null,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppTheme.textLight),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textMedium))),
    ]);
  }
}
