import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        ? _OrganizerMarketplace(user: user)
        : _VolunteerMarketplace(user: user);
  }
}

class _VolunteerMarketplace extends StatelessWidget {
  final UserModel user;
  const _VolunteerMarketplace({required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: const _MarketplaceAppBar(
          tabs: [Tab(text: 'Shop'), Tab(text: 'My orders')],
        ),
        body: TabBarView(
          children: [_ShopTab(user: user), _BuyerOrdersTab(user: user)],
        ),
      ),
    );
  }
}

class _OrganizerMarketplace extends StatelessWidget {
  final UserModel user;
  const _OrganizerMarketplace({required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _MarketplaceAppBar(
          tabs: const [Tab(text: 'Listings'), Tab(text: 'Orders')],
          actions: [
            IconButton(
              tooltip: 'Request new listing',
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MarketplaceCreateListingScreen(
                    organizer: user,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _OrganizerListingsTab(user: user),
            _OrganizerOrdersTab(user: user),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final List<Widget> tabs;
  final List<Widget>? actions;
  const _MarketplaceAppBar({required this.tabs, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(104);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Marketplace'),
      actions: actions,
      bottom: TabBar(
        tabs: tabs,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
      ),
    );
  }
}

class _ShopTab extends StatelessWidget {
  final UserModel user;
  const _ShopTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MarketplaceViewModel>();
    return StreamBuilder<List<MarketplaceItemModel>>(
      stream: vm.service.approvedItemsStream(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
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
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _MarketplaceItemCard(
              item: item,
              shopView: true,
              actionLabel: item.isAvailable ? 'Buy now' : null,
              onAction: item.isAvailable
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MarketplaceCheckoutScreen(
                            item: item,
                            buyer: user,
                          ),
                        ),
                      )
                  : null,
            );
          },
        );
      },
    );
  }
}

class _BuyerOrdersTab extends StatelessWidget {
  final UserModel user;
  const _BuyerOrdersTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketplacePurchaseModel>>(
      stream: context
          .watch<MarketplaceViewModel>()
          .service
          .buyerPurchasesStream(user.id),
      builder: (context, snapshot) => _OrdersList(
        snapshot: snapshot,
        isOrganizer: false,
        emptyTitle: 'No orders yet',
        emptyMessage: 'Your completed marketplace orders will appear here.',
      ),
    );
  }
}

class _OrganizerOrdersTab extends StatelessWidget {
  final UserModel user;
  const _OrganizerOrdersTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketplacePurchaseModel>>(
      stream: context
          .watch<MarketplaceViewModel>()
          .service
          .organizerPurchasesStream(user.id),
      builder: (context, snapshot) => _OrdersList(
        snapshot: snapshot,
        isOrganizer: true,
        emptyTitle: 'No orders received',
        emptyMessage: 'Orders for your marketplace listings will appear here.',
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final AsyncSnapshot<List<MarketplacePurchaseModel>> snapshot;
  final bool isOrganizer;
  final String emptyTitle;
  final String emptyMessage;
  const _OrdersList({
    required this.snapshot,
    required this.isOrganizer,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final orders = snapshot.data ?? [];
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Unable to load orders',
        message: snapshot.error.toString(),
      );
    }
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderCard(
        order: orders[index],
        isOrganizer: isOrganizer,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final MarketplacePurchaseModel order;
  final bool isOrganizer;
  const _OrderCard({required this.order, required this.isOrganizer});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MarketplaceOrderDetailScreen(
            order: order,
            isOrganizer: isOrganizer,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.itemTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                Text(
                  'RM ${order.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isOrganizer
                  ? '${order.recipientName} • #${order.orderNumber}'
                  : 'Order #${order.orderNumber}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatusPill(
                  label: _orderStatusLabel(order.status),
                  color: _orderStatusColor(order.status),
                ),
                const Spacer(),
                Text(
                  DateFormat('d MMM yyyy').format(order.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: AppTheme.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MarketplaceCheckoutScreen extends StatefulWidget {
  final MarketplaceItemModel item;
  final UserModel buyer;
  const MarketplaceCheckoutScreen({
    super.key,
    required this.item,
    required this.buyer,
  });

  @override
  State<MarketplaceCheckoutScreen> createState() =>
      _MarketplaceCheckoutScreenState();
}

class _MarketplaceCheckoutScreenState extends State<MarketplaceCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  late final TextEditingController _stateCtrl;
  final _postcodeCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.buyer.name);
    _phoneCtrl = TextEditingController(text: widget.buyer.phone ?? '');
    _stateCtrl = TextEditingController(text: widget.buyer.state ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _nameCtrl,
      _phoneCtrl,
      _address1Ctrl,
      _address2Ctrl,
      _cityCtrl,
      _stateCtrl,
      _postcodeCtrl,
      _instructionsCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<MarketplaceViewModel>();
    final order = await vm.placeOrder(
      item: widget.item,
      buyer: widget.buyer,
      recipientName: _nameCtrl.text,
      phone: _phoneCtrl.text,
      addressLine1: _address1Ctrl.text,
      addressLine2: _address2Ctrl.text,
      city: _cityCtrl.text,
      state: _stateCtrl.text,
      postcode: _postcodeCtrl.text,
      deliveryInstructions: _instructionsCtrl.text,
    );
    if (!mounted) return;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(vm.error ?? 'Unable to place this order.'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => MarketplaceOrderDetailScreen(
        order: order,
        isOrganizer: false,
        justPlaced: true,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<MarketplaceViewModel>().isLoading;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Postage details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ItemSummary(item: widget.item),
            const SizedBox(height: 14),
            const _PaymentNotice(),
            const SizedBox(height: 20),
            const _SectionTitle('Recipient information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Full name *'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneCtrl,
              validator: _required,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number *'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.buyer.email,
              enabled: false,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Delivery address'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address1Ctrl,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Address line 1 *'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _address2Ctrl,
              decoration:
                  const InputDecoration(labelText: 'Address line 2 (optional)'),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _postcodeCtrl,
                  validator: _required,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Postcode *'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _cityCtrl,
                  validator: _required,
                  decoration: const InputDecoration(labelText: 'City *'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextFormField(
              controller: _stateCtrl,
              validator: _required,
              decoration: const InputDecoration(labelText: 'State *'),
            ),
            const SizedBox(height: 10),
            const TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Country',
                hintText: 'Malaysia',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _instructionsCtrl,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Delivery instructions (optional)',
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: loading ? null : _submit,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(loading ? 'Placing order…' : 'Confirm order'),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketplaceOrderDetailScreen extends StatelessWidget {
  final MarketplacePurchaseModel order;
  final bool isOrganizer;
  final bool justPlaced;
  const MarketplaceOrderDetailScreen({
    super.key,
    required this.order,
    required this.isOrganizer,
    this.justPlaced = false,
  });

  Future<void> _updateStatus(
    BuildContext context,
    MarketplacePurchaseStatus status,
  ) async {
    final vm = context.read<MarketplaceViewModel>();
    final ok = await vm.updateOrderStatus(purchaseId: order.id, status: status);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          ok ? 'Order status updated.' : vm.error ?? 'Unable to update order.'),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    ));
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar:
          AppBar(title: Text(justPlaced ? 'Order confirmed' : 'Order details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (justPlaced) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: const Column(children: [
                Icon(Icons.check_circle, size: 42, color: AppTheme.success),
                SizedBox(height: 10),
                Text(
                  'Your order has been placed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track it anytime from Marketplace → My orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMedium),
                ),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          _DetailCard(title: 'Order summary', rows: [
            ('Order number', '#${order.orderNumber}'),
            ('Item', order.itemTitle),
            (
              'Order date',
              DateFormat('d MMM yyyy, h:mm a').format(order.createdAt)
            ),
            ('Total', 'RM ${order.price.toStringAsFixed(2)}'),
            ('Status', _orderStatusLabel(order.status)),
            ('Payment', 'Not collected'),
          ]),
          const SizedBox(height: 14),
          _DetailCard(title: 'Postage details', rows: [
            ('Recipient', order.recipientName),
            ('Phone', order.phone),
            ('Email', order.buyerEmail),
            ('Address', order.formattedAddress),
            if ((order.deliveryInstructions ?? '').isNotEmpty)
              ('Instructions', order.deliveryInstructions!),
          ]),
          const SizedBox(height: 14),
          const _PaymentNotice(),
          if (isOrganizer) ...[
            const SizedBox(height: 20),
            const _SectionTitle('Update order status'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MarketplacePurchaseStatus.values.map((status) {
                final selected = status == order.status;
                return ChoiceChip(
                  label: Text(_orderStatusLabel(status)),
                  selected: selected,
                  onSelected:
                      selected ? null : (_) => _updateStatus(context, status),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrganizerListingsTab extends StatelessWidget {
  final UserModel user;
  const _OrganizerListingsTab({required this.user});

  Future<void> _setAvailability(
    BuildContext context,
    MarketplaceItemModel item,
    bool available,
  ) async {
    final vm = context.read<MarketplaceViewModel>();
    final ok = await vm.updateItemAvailability(
      itemId: item.id,
      isAvailable: available,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '${item.title} is now ${available ? 'available' : 'out of stock'}.'
          : vm.error ?? 'Unable to update availability.'),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MarketplaceViewModel>();
    return StreamBuilder<List<MarketplaceItemModel>>(
      stream: vm.service.organizerItemsStream(user.id),
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
            icon: Icons.inventory_2_outlined,
            title: 'No listings yet',
            message: 'Your marketplace listings will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _MarketplaceItemCard(
              item: item,
              showAvailability: item.status == MarketplaceItemStatus.approved,
              availabilityLoading: vm.isLoading,
              onAvailabilityChanged: (value) =>
                  _setAvailability(context, item, value),
            );
          },
        );
      },
    );
  }
}

class MarketplaceCreateListingScreen extends StatefulWidget {
  final UserModel organizer;
  const MarketplaceCreateListingScreen({
    super.key,
    required this.organizer,
  });

  @override
  State<MarketplaceCreateListingScreen> createState() =>
      _MarketplaceCreateListingScreenState();
}

class _MarketplaceCreateListingScreenState
    extends State<MarketplaceCreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _price(String? value) {
    final price = double.tryParse(value?.trim() ?? '');
    return price == null || price <= 0 ? 'Enter a valid price' : null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<MarketplaceViewModel>();
    final ok = await vm.createItem(
      organizer: widget.organizer,
      title: _titleCtrl.text,
      description: _descriptionCtrl.text,
      price: double.parse(_priceCtrl.text.trim()),
      imageUrl: _imageUrlCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Listing submitted for admin review.'),
        backgroundColor: AppTheme.success,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(vm.error ?? 'Unable to submit listing.'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<MarketplaceViewModel>().isLoading;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Request listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SectionTitle('Listing details'),
            const SizedBox(height: 6),
            const Text(
              'Your listing will be published after admin approval.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleCtrl,
              validator: _required,
              decoration: const InputDecoration(labelText: 'Item name *'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              validator: _required,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description *'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              validator: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (RM) *'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlCtrl,
              keyboardType: TextInputType.url,
              decoration:
                  const InputDecoration(labelText: 'Image URL (optional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loading ? null : _submit,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(loading ? 'Submitting…' : 'Submit for review'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceItemCard extends StatelessWidget {
  final MarketplaceItemModel item;
  final bool shopView;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showAvailability;
  final bool availabilityLoading;
  final ValueChanged<bool>? onAvailabilityChanged;
  const _MarketplaceItemCard({
    required this.item,
    this.shopView = false,
    this.actionLabel,
    this.onAction,
    this.showAvailability = false,
    this.availabilityLoading = false,
    this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final listingColor = _listingStatusColor(item.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
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
                Row(children: [
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
                ]),
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
                Row(children: [
                  _StatusPill(
                    label: shopView
                        ? item.isAvailable
                            ? 'Available'
                            : 'Out of stock'
                        : item.status.name,
                    color: shopView
                        ? item.isAvailable
                            ? AppTheme.success
                            : AppTheme.textLight
                        : listingColor,
                  ),
                  const Spacer(),
                  if (actionLabel != null)
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: onAction,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(92, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text(actionLabel!),
                      ),
                    ),
                ]),
                if (showAvailability) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  Row(children: [
                    Expanded(
                      child: Text(
                        item.isAvailable ? 'Available' : 'Out of stock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.isAvailable
                              ? AppTheme.success
                              : AppTheme.textLight,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: item.isAvailable,
                      onChanged:
                          availabilityLoading ? null : onAvailabilityChanged,
                    ),
                  ]),
                ],
                if ((item.adminNotes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(item.adminNotes!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.warning)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSummary extends StatelessWidget {
  final MarketplaceItemModel item;
  const _ItemSummary({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(children: [
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
              Text(item.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              const SizedBox(height: 4),
              Text(item.organizerName,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMedium)),
            ],
          ),
        ),
        Text('RM ${item.price.toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppTheme.primary)),
      ]),
    );
  }
}

class _PaymentNotice extends StatelessWidget {
  const _PaymentNotice();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.25)),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline, color: AppTheme.secondary, size: 21),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Online payment is not collected yet. Stripe payment will be added later.',
            style: TextStyle(
                fontSize: 12, height: 1.4, color: AppTheme.textMedium),
          ),
        ),
      ]),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  const _DetailCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionTitle(title),
        const SizedBox(height: 12),
        ...rows.map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 104,
                  child: Text(row.$1,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textLight)),
                ),
                Expanded(
                  child: Text(row.$2,
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                ),
              ]),
            )),
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark));
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.divider),
    );

String _orderStatusLabel(MarketplacePurchaseStatus status) {
  switch (status) {
    case MarketplacePurchaseStatus.confirmed:
      return 'Confirmed';
    case MarketplacePurchaseStatus.processing:
      return 'Processing';
    case MarketplacePurchaseStatus.shipped:
      return 'Shipped';
    case MarketplacePurchaseStatus.delivered:
      return 'Delivered';
    case MarketplacePurchaseStatus.cancelled:
      return 'Cancelled';
  }
}

Color _orderStatusColor(MarketplacePurchaseStatus status) {
  switch (status) {
    case MarketplacePurchaseStatus.confirmed:
      return AppTheme.primary;
    case MarketplacePurchaseStatus.processing:
      return AppTheme.warning;
    case MarketplacePurchaseStatus.shipped:
      return const Color(0xFF1565C0);
    case MarketplacePurchaseStatus.delivered:
      return AppTheme.success;
    case MarketplacePurchaseStatus.cancelled:
      return AppTheme.error;
  }
}

Color _listingStatusColor(MarketplaceItemStatus status) {
  switch (status) {
    case MarketplaceItemStatus.approved:
      return AppTheme.success;
    case MarketplaceItemStatus.rejected:
      return AppTheme.error;
    case MarketplaceItemStatus.pending:
      return AppTheme.warning;
  }
}
