// lib/views/shared/marketplace_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/marketplace_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import 'widgets.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    if (user == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Sign in required',
          message: 'Please sign in to view the marketplace.',
        ),
      );
    }

    return user.role == UserRole.organizer
        ? const _OrganizerMarketplaceView()
        : const _VolunteerMarketplaceView();
  }
}

class _OrganizerMarketplaceView extends StatefulWidget {
  const _OrganizerMarketplaceView();

  @override
  State<_OrganizerMarketplaceView> createState() =>
      _OrganizerMarketplaceViewState();
}

class _OrganizerMarketplaceViewState extends State<_OrganizerMarketplaceView> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _imageUrlCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(UserModel user) async {
    final vm = context.read<MarketplaceViewModel>();
    final ok = await vm.createItem(
      organizer: user,
      title: _titleCtrl.text,
      description: _descriptionCtrl.text,
      price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
      imageUrl: _imageUrlCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      _titleCtrl.clear();
      _descriptionCtrl.clear();
      _priceCtrl.clear();
      _imageUrlCtrl.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Listing submitted for admin review.'
            : vm.error ?? 'Unable to submit listing.'),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser!;
    final vm = context.watch<MarketplaceViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Marketplace')),
      body: StreamBuilder<List<MarketplaceItemModel>>(
        stream: vm.service.organizerItemsStream(user.id),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final filteredItems = _filterMarketplaceItems(items, _searchQuery);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ListingForm(
                titleCtrl: _titleCtrl,
                descriptionCtrl: _descriptionCtrl,
                priceCtrl: _priceCtrl,
                imageUrlCtrl: _imageUrlCtrl,
                isLoading: vm.isLoading,
                onSubmit: () => _submit(user),
              ),
              const SizedBox(height: 20),
              _MarketplaceSearchField(
                controller: _searchCtrl,
                query: _searchQuery,
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Listings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                SizedBox(
                  height: 260,
                  child: EmptyState(
                    icon: Icons.error_outline,
                    title: 'Unable to load listings',
                    message: snapshot.error.toString(),
                  ),
                )
              else if (items.isEmpty)
                const SizedBox(
                  height: 260,
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No listings yet',
                    message: 'Submit your first item for admin review.',
                  ),
                )
              else if (filteredItems.isEmpty)
                const SizedBox(
                  height: 220,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No matching listings',
                    message: 'Try another title, description, or organizer.',
                  ),
                )
              else
                ...filteredItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MarketplaceItemCard(item: item),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _VolunteerMarketplaceView extends StatefulWidget {
  const _VolunteerMarketplaceView();

  @override
  State<_VolunteerMarketplaceView> createState() =>
      _VolunteerMarketplaceViewState();
}

class _VolunteerMarketplaceViewState extends State<_VolunteerMarketplaceView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _buy(BuildContext context, MarketplaceItemModel item) async {
    final user = context.read<AuthViewModel>().currentUser!;
    final vm = context.read<MarketplaceViewModel>();
    final ok = await vm.buyItem(item: item, buyer: user);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Purchase request saved. Payment setup is coming soon.'
            : vm.error ?? 'Unable to buy this item.'),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MarketplaceViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Marketplace')),
      body: StreamBuilder<List<MarketplaceItemModel>>(
        stream: vm.service.approvedItemsStream(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final filteredItems = _filterMarketplaceItems(items, _searchQuery);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Unable to load marketplace',
              message: snapshot.error.toString(),
            );
          }
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No items yet',
              message: 'Approved marketplace items will appear here.',
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: _MarketplaceSearchField(
                  controller: _searchCtrl,
                  query: _searchQuery,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'No matching listings',
                        message:
                            'Try another title, description, or organizer.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _MarketplaceItemCard(
                            item: item,
                            actionLabel: 'Buy',
                            isLoading: vm.isLoading,
                            onAction: () => _buy(context, item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

List<MarketplaceItemModel> _filterMarketplaceItems(
    List<MarketplaceItemModel> items, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return items;
  return items
      .where((item) =>
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.organizerName.toLowerCase().contains(query))
      .toList();
}

class _MarketplaceSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _MarketplaceSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search marketplace',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}

class _ListingForm extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController imageUrlCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _ListingForm({
    required this.titleCtrl,
    required this.descriptionCtrl,
    required this.priceCtrl,
    required this.imageUrlCtrl,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Request a Listing',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Item name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descriptionCtrl,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Price'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: imageUrlCtrl,
            decoration:
                const InputDecoration(labelText: 'Image URL (optional)'),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onSubmit,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_outlined),
            label: const Text('Submit for Review'),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceItemCard extends StatelessWidget {
  final MarketplaceItemModel item;
  final String? actionLabel;
  final bool isLoading;
  final VoidCallback? onAction;

  const _MarketplaceItemCard({
    required this.item,
    this.actionLabel,
    this.isLoading = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkAvatar(
            imageUrl: item.imageUrl,
            size: 72,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Text(
                      'RM ${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.organizerName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (actionLabel != null)
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : onAction,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(84, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: Text(actionLabel!),
                        ),
                      ),
                  ],
                ),
                if ((item.adminNotes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.adminNotes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(MarketplaceItemStatus status) {
    switch (status) {
      case MarketplaceItemStatus.approved:
        return AppTheme.success;
      case MarketplaceItemStatus.rejected:
        return AppTheme.error;
      case MarketplaceItemStatus.pending:
        return AppTheme.warning;
    }
  }
}
