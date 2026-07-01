// lib/views/shared/widgets.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/event_model.dart';
import '../../utils/app_theme.dart';

class ReferenceBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const ReferenceBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withOpacity(0.16),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.secondary,
          unselectedItemColor: AppTheme.textDark,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool compact;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryHelper.getColor(event.category);
    final catIcon = CategoryHelper.getIcon(event.category);
    final catName = CategoryHelper.getName(event.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              height: compact ? 80 : 110,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: EventBannerImage(
                      imageUrl: event.imageUrl,
                      category: event.category,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catIcon, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(catName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  if (event.isFull)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('FULL',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${event.currentVolunteers}/${event.maxVolunteers}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppTheme.textLight),
                    const SizedBox(width: 3),
                    Expanded(
                        child: Text(
                            [event.location, event.state]
                                .whereType<String>()
                                .where((value) => value.isNotEmpty)
                                .join(', '),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppTheme.textLight),
                    const SizedBox(width: 3),
                    Text(DateFormat('d MMM yyyy').format(event.startDate),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textLight)),
                  ]),
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    // Fill bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: event.fillRate.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            event.isFull ? Colors.red.shade600 : catColor),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        event.isFull
                            ? 'Fully booked'
                            : '${event.spotsLeft} spots left',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                event.isFull ? Colors.red.shade600 : catColor)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NetworkAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final IconData fallbackIcon;
  final Color color;
  final Color backgroundColor;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const NetworkAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.fallbackIcon,
    this.color = AppTheme.primary,
    this.backgroundColor = const Color(0xFFEAF4FF),
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Icon(fallbackIcon, color: color, size: size * 0.45),
            )
          : Icon(fallbackIcon, color: color, size: size * 0.45),
    );
  }
}

class EventBannerImage extends StatelessWidget {
  final String? imageUrl;
  final EventCategory category;
  final BorderRadius borderRadius;

  const EventBannerImage({
    super.key,
    required this.imageUrl,
    required this.category,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryHelper.getColor(category);
    final catIcon = CategoryHelper.getIcon(category);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: borderRadius,
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _EventBannerFallback(
                    color: catColor,
                    icon: catIcon,
                  ),
                ),
                Container(color: Colors.black.withOpacity(0.2)),
              ],
            )
          : _EventBannerFallback(color: catColor, icon: catIcon),
    );
  }
}

class _EventBannerFallback extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _EventBannerFallback({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.85), color],
        ),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white.withOpacity(0.2), size: 72),
      ),
    );
  }
}

class OrganizerCard extends StatelessWidget {
  final dynamic organizer;
  final int eventCount;
  final VoidCallback onTap;

  const OrganizerCard({
    super.key,
    required this.organizer,
    required this.eventCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            NetworkAvatar(
              imageUrl: organizer.photoUrl,
              size: 52,
              fallbackIcon: Icons.business,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(organizer.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  if (organizer.organization != null)
                    Text(organizer.organization!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMedium)),
                  if (organizer.location != null)
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppTheme.textLight),
                      const SizedBox(width: 2),
                      Text(
                          [organizer.location, organizer.state]
                              .whereType<String>()
                              .where((value) => value.isNotEmpty)
                              .join(', '),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textLight)),
                    ]),
                ],
              ),
            ),
            Column(
              children: [
                Text('$eventCount',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
                const Text('events',
                    style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final ApplicationStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;
    switch (status) {
      case ApplicationStatus.pending:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        label = 'New';
        icon = Icons.fiber_new;
        break;
      case ApplicationStatus.reviewing:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = 'Reviewing';
        icon = Icons.manage_search;
        break;
      case ApplicationStatus.accepted:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Accepted';
        icon = Icons.check_circle;
        break;
      case ApplicationStatus.rejected:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      case ApplicationStatus.waitlisted:
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        label = 'Waitlisted';
        icon = Icons.hourglass_bottom;
        break;
      case ApplicationStatus.withdrawn:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'Withdrawn';
        icon = Icons.undo;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }
}

class EventStatusBadge extends StatelessWidget {
  final EventStatus status;
  const EventStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case EventStatus.draft:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'Draft';
        break;
      case EventStatus.published:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Published';
        break;
      case EventStatus.ongoing:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = 'Ongoing';
        break;
      case EventStatus.completed:
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        label = 'Completed';
        break;
      case EventStatus.finalized:
        bg = Colors.indigo.shade50;
        fg = Colors.indigo.shade700;
        label = 'Finalized';
        break;
      case EventStatus.cancelled:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Cancelled';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(
      {super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!,
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay(
      {super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      if (isLoading)
        Container(
          color: Colors.black.withOpacity(0.3),
          child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryLight)),
        ),
    ]);
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.divider),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 14, color: AppTheme.textMedium)),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
