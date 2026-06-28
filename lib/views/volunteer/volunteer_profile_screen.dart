// lib/views/volunteer/volunteer_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/cloudinary_image_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/malaysia_states.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/profile_post_history.dart';
import '../shared/widgets.dart';

class VolunteerProfileScreen extends StatelessWidget {
  const VolunteerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            title: const Text('My Profile'),
            actions: [
              IconButton(
                onPressed: () => _showEditDialog(context, user, authVm),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              authVm.logout();
                            },
                            child: const Text('Sign Out',
                                style: TextStyle(color: AppTheme.error))),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    child: NetworkAvatar(
                      imageUrl: user.photoUrl,
                      size: 88,
                      fallbackIcon: Icons.person,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Volunteer',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 20),

                  StreamBuilder<ImpactSummary>(
                    stream: context
                        .read<EventViewModel>()
                        .impactSummaryStream(user.id),
                    initialData:
                        const ImpactSummary(points: 0, hours: 0, events: 0),
                    builder: (context, snapshot) {
                      final impact = snapshot.data ??
                          const ImpactSummary(points: 0, hours: 0, events: 0);
                      return Column(children: [
                        _ImpactProgressCard(summary: impact),
                        const SizedBox(height: 16),
                        Row(children: [
                          _StatCard(
                              value: '${impact.points}',
                              label: 'Impact\nPoints',
                              icon: Icons.bolt),
                          const SizedBox(width: 12),
                          _StatCard(
                              value: '${impact.hours}',
                              label: 'Verified\nHours',
                              icon: Icons.schedule),
                          const SizedBox(width: 12),
                          _StatCard(
                              value: '${impact.events}',
                              label: 'Events\nCompleted',
                              icon: Icons.event_available),
                        ]),
                      ]);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('About Me',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark)),
                        const SizedBox(height: 8),
                        Text(
                            user.bio ??
                                'No bio added yet. Tap Edit to add one.',
                            style: TextStyle(
                                fontSize: 13,
                                color: user.bio != null
                                    ? AppTheme.textMedium
                                    : AppTheme.textLight,
                                fontStyle: user.bio == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                height: 1.5)),
                        if (user.location != null) ...[
                          const Divider(color: AppTheme.divider, height: 20),
                          Row(children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppTheme.textLight),
                            const SizedBox(width: 6),
                            Text(
                                [
                                  user.location,
                                  user.state,
                                ].whereType<String>().join(', '),
                                style: const TextStyle(
                                    fontSize: 13, color: AppTheme.textMedium)),
                          ]),
                        ],
                        if (user.email.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.email_outlined,
                                size: 14, color: AppTheme.textLight),
                            const SizedBox(width: 6),
                            Text(user.email,
                                style: const TextStyle(
                                    fontSize: 13, color: AppTheme.textMedium)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skills
                  if (user.skills.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Skills',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.skills
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            AppTheme.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppTheme.primary
                                                .withOpacity(0.2)),
                                      ),
                                      child: Text(s,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w600)),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ProfilePostHistory(user: user),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, UserModel user, AuthViewModel authVm) {
    final nameCtrl = TextEditingController(text: user.name);
    final bioCtrl = TextEditingController(text: user.bio);
    final locationCtrl = TextEditingController(text: user.location);
    final phoneCtrl = TextEditingController(text: user.phone);
    String? selectedState = isMalaysiaState(user.state) ? user.state : null;
    final photoCtrl = TextEditingController(text: user.photoUrl);
    final picker = ImagePicker();
    final imageService = CloudinaryImageService();
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
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
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: NetworkAvatar(
                        imageUrl: photoCtrl.text.trim().isEmpty
                            ? null
                            : photoCtrl.text,
                        size: 88,
                        fallbackIcon: Icons.person,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );
                              if (file == null) return;
                              setModalState(() => isUploading = true);
                              try {
                                final imageUrl = await imageService.uploadImage(
                                  file: file,
                                  folder: 'jomimpact/profiles',
                                );
                                photoCtrl.text = imageUrl;
                                setModalState(() {});
                              } finally {
                                setModalState(() => isUploading = false);
                              }
                            },
                      icon: isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_outlined),
                      label: const Text('Upload profile image'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: photoCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration:
                          const InputDecoration(labelText: 'Profile image URL'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationCtrl,
                      decoration:
                          const InputDecoration(labelText: 'City / Area *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedState,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'State / Federal Territory *'),
                      items: malaysiaStates
                          .map((state) => DropdownMenuItem(
                              value: state, child: Text(state)))
                          .toList(),
                      onChanged: (value) =>
                          setModalState(() => selectedState = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (locationCtrl.text.trim().isEmpty ||
                            selectedState == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Location and state are required.'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                          return;
                        }
                        final updated = user.copyWith(
                          name: nameCtrl.text.trim(),
                          photoUrl: photoCtrl.text.trim().isEmpty
                              ? null
                              : photoCtrl.text.trim(),
                          clearPhotoUrl: photoCtrl.text.trim().isEmpty,
                          bio: bioCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
                          state: selectedState,
                          phone: phoneCtrl.text.trim(),
                        );
                        await authVm.updateProfile(updated);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ImpactProgressCard extends StatelessWidget {
  final ImpactSummary summary;
  const _ImpactProgressCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final badge = _badgeName(summary.badge);
    final color = _badgeColor(summary.badge);
    final remaining = (summary.nextThreshold - summary.points).clamp(0, 1500);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.workspace_premium, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$badge badge',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                Text(
                    summary.badge == ImpactBadge.gold
                        ? 'Highest badge achieved'
                        : '$remaining points to the next badge',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textLight)),
              ],
            ),
          ),
          Text('${summary.points} pts',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (summary.points / ImpactSummary.goldPoints).clamp(0, 1),
            minHeight: 10,
            backgroundColor: AppTheme.divider,
            color: color,
          ),
        ),
        const SizedBox(height: 7),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bronze 250',
                style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
            Text('Silver 750',
                style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
            Text('Gold 1500',
                style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
          ],
        ),
      ]),
    );
  }

  String _badgeName(ImpactBadge badge) {
    switch (badge) {
      case ImpactBadge.starter:
        return 'Starter';
      case ImpactBadge.bronze:
        return 'Bronze';
      case ImpactBadge.silver:
        return 'Silver';
      case ImpactBadge.gold:
        return 'Gold';
    }
  }

  Color _badgeColor(ImpactBadge badge) {
    switch (badge) {
      case ImpactBadge.starter:
        return AppTheme.textLight;
      case ImpactBadge.bronze:
        return const Color(0xFFB06B32);
      case ImpactBadge.silver:
        return const Color(0xFF718096);
      case ImpactBadge.gold:
        return const Color(0xFFD69E2E);
    }
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textLight, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
