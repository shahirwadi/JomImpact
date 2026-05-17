// lib/views/organizer/organizer_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/cloudinary_image_service.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/event_viewmodel.dart';
import '../shared/widgets.dart';

class OrganizerProfileScreen extends StatelessWidget {
  const OrganizerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final vm = context.watch<EventViewModel>();
    final user = authVm.currentUser!;
    final totalApplicants =
        vm.organizerEvents.fold(0, (sum, e) => sum + e.currentVolunteers);

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
                onPressed: () => showDialog(
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
                ),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryDark, AppTheme.primary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4), width: 2),
                          ),
                          child: NetworkAvatar(
                            imageUrl: user.photoUrl,
                            size: 72,
                            fallbackIcon: Icons.business,
                            color: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(user.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        if (user.organization != null)
                          Text(user.organization!,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Event Organizer',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(children: [
                    _OrgStatCard(
                        value: '${vm.organizerEvents.length}',
                        label: 'Events\nCreated',
                        icon: Icons.event),
                    const SizedBox(width: 12),
                    _OrgStatCard(
                        value: '$totalApplicants',
                        label: 'Volunteers\nImpacted',
                        icon: Icons.people),
                    const SizedBox(width: 12),
                    const _OrgStatCard(
                        value: '4.9', label: 'Avg\nRating', icon: Icons.star),
                  ]),
                  const SizedBox(height: 16),

                  // Details
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
                        const Text('About',
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
                        const Divider(color: AppTheme.divider, height: 20),
                        _ProfileInfo(
                            icon: Icons.email_outlined, value: user.email),
                        if (user.location != null)
                          _ProfileInfo(
                              icon: Icons.location_on_outlined,
                              value: user.location!),
                        if (user.phone != null)
                          _ProfileInfo(
                              icon: Icons.phone_outlined, value: user.phone!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Achievements
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
                        const Text('Achievements',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark)),
                        const SizedBox(height: 12),
                        _AchievementTile(
                            icon: Icons.military_tech,
                            label: 'First Event Created',
                            earned: vm.organizerEvents.isNotEmpty,
                            color: AppTheme.secondary),
                        _AchievementTile(
                            icon: Icons.emoji_events,
                            label: 'Community Champion',
                            earned: (user.totalEvents ?? 0) >= 10,
                            color: Colors.amber),
                        _AchievementTile(
                            icon: Icons.stars,
                            label: 'Impact Maker',
                            earned: totalApplicants >= 50,
                            color: AppTheme.primary),
                      ],
                    ),
                  ),
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
    final orgCtrl = TextEditingController(text: user.organization);
    final bioCtrl = TextEditingController(text: user.bio);
    final locationCtrl = TextEditingController(text: user.location);
    final phoneCtrl = TextEditingController(text: user.phone);
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
                        imageUrl:
                            photoCtrl.text.trim().isEmpty ? null : photoCtrl.text,
                        size: 88,
                        fallbackIcon: Icons.business,
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
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: orgCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Organization Name'),
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
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final updated = user.copyWith(
                          name: nameCtrl.text.trim(),
                          photoUrl: photoCtrl.text.trim().isEmpty
                              ? null
                              : photoCtrl.text.trim(),
                          clearPhotoUrl: photoCtrl.text.trim().isEmpty,
                          organization: orgCtrl.text.trim(),
                          bio: bioCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
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

class _ProfileInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  const _ProfileInfo({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 14, color: AppTheme.textLight),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
        ]),
      );
}

class _OrgStatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _OrgStatCard(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
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

class _AchievementTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool earned;
  final Color color;
  const _AchievementTile(
      {required this.icon,
      required this.label,
      required this.earned,
      required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: earned ? color.withOpacity(0.12) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 18, color: earned ? color : Colors.grey.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: earned ? AppTheme.textDark : AppTheme.textLight))),
          if (earned)
            const Icon(Icons.check_circle, color: AppTheme.success, size: 16)
          else
            const Text('Locked',
                style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
        ]),
      );
}
