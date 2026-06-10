// lib/views/admin/admin_marketplace_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/marketplace_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../shared/widgets.dart';

class AdminMarketplaceRequestsScreen extends StatelessWidget {
  const AdminMarketplaceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MarketplaceViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Marketplace Requests'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<MarketplaceItemModel>>(
        stream: vm.service.pendingItemsStream(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load listings',
              message: snapshot.error.toString(),
            );
          }
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'No pending listings',
              message: 'Organizer marketplace requests will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _MarketplaceRequestCard(item: items[index]);
            },
          );
        },
      ),
    );
  }
}

class _MarketplaceRequestCard extends StatelessWidget {
  final MarketplaceItemModel item;

  const _MarketplaceRequestCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final notesCtrl = TextEditingController(text: item.adminNotes ?? '');
    final vm = context.read<MarketplaceViewModel>();
    final admin = context.read<AuthViewModel>().currentUser!;

    Future<void> review(MarketplaceItemStatus status) async {
      final ok = await vm.reviewItem(
        itemId: item.id,
        adminId: admin.id,
        status: status,
        adminNotes:
            notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? status == MarketplaceItemStatus.approved
                  ? 'Listing approved.'
                  : 'Listing rejected.'
              : vm.error ?? 'Unable to review listing.'),
          backgroundColor: ok ? AppTheme.success : AppTheme.error,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkAvatar(
                imageUrl: item.imageUrl,
                size: 64,
                fallbackIcon: Icons.inventory_2_outlined,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
                backgroundColor: AppTheme.surface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.organizerName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'RM ${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesCtrl,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Admin notes',
              hintText: 'Optional reason or feedback',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => review(MarketplaceItemStatus.rejected),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => review(MarketplaceItemStatus.approved),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
