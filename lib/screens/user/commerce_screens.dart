import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../services/store_settings.dart';
import '../../state/menu_catalog.dart';
import '../../state/order_cart.dart';
import '../../theme/nosh_theme.dart';
import '../../widgets/food_image.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({this.initialCategory = 'All', super.key});

  final String initialCategory;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late String _category;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    menuCatalog.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    menuCatalog.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = menuCatalog.availableItems.where((item) {
      final inCategory = _category == 'All' || item.category == _category;
      final query = _search.toLowerCase();
      final matches =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return inCategory && matches;
    }).toList();
    final categories = MenuItem.categoriesFor(menuCatalog.availableItems);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Full menu',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                hintText: 'Search the menu',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 43,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                  selectedColor: NoshTheme.primary,
                  backgroundColor: NoshTheme.surface,
                  labelStyle: TextStyle(
                    color: _category == category
                        ? Colors.white
                        : NoshTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: _category == category
                        ? NoshTheme.primary
                        : NoshTheme.outline,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No dishes found.',
                      style: TextStyle(color: NoshTheme.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _MenuListTile(item: items[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([StoreSettings.instance, menuCatalog]),
      builder: (context, _) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: NoshTheme.background,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    FoodImage(
                      url: StoreSettings.instance.heroImageUrl,
                      borderRadius: 0,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.76),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 22,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            StoreSettings.instance.restaurantName.toUpperCase(),
                            style: TextStyle(
                              color: NoshTheme.primarySoft,
                              letterSpacing: 1.6,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            StoreSettings.instance.tagline,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: NoshTheme.amber,
                          size: 19,
                        ),
                        SizedBox(width: 4),
                        const Text(
                          '4.9',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(width: 6),
                        const Text(
                          '(1.2k reviews)',
                          style: TextStyle(color: NoshTheme.muted),
                        ),
                        Spacer(),
                        Text(
                          StoreSettings.instance.businessHours,
                          style: TextStyle(
                            color: NoshTheme.primarySoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      StoreSettings.instance.description,
                      style: TextStyle(color: NoshTheme.muted, height: 1.55),
                    ),
                    if (StoreSettings.instance.phone.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Contact: ${StoreSettings.instance.phone}',
                        style: const TextStyle(
                          color: NoshTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    const Text(
                      'Today’s favorites',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
              sliver: SliverList.separated(
                itemCount: menuCatalog.availableItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _MenuListTile(item: menuCatalog.availableItems[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DishDetailScreen extends StatefulWidget {
  const DishDetailScreen({required this.item, super.key});

  final MenuItem item;

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    menuCatalog.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    menuCatalog.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = menuCatalog.items
        .where((entry) => entry.id == widget.item.id)
        .firstOrNull;
    final item = currentItem ?? widget.item;
    final itemAvailable = currentItem?.isAvailable == true;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: NoshTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              background: FoodImage(url: item.imageUrl, borderRadius: 0),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: NoshTheme.amber,
                        size: 19,
                      ),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: NoshTheme.primarySoft,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: NoshTheme.muted,
                      height: 1.55,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 23),
                  const Divider(color: NoshTheme.outline),
                  const SizedBox(height: 12),
                  const Text(
                    'Made with care',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prepared fresh to order with ingredients selected by our kitchen. Tell us about any allergies or dietary needs at checkout.',
                    style: TextStyle(
                      color: NoshTheme.muted,
                      height: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NoshTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_outlined,
                          color: NoshTheme.primarySoft,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Allergen note: Please contact us before ordering if you have a food allergy.',
                            style: TextStyle(
                              color: NoshTheme.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: Row(
          children: [
            _QuantityControl(
              quantity: _quantity,
              onDecrease: () =>
                  setState(() => _quantity = (_quantity - 1).clamp(1, 99)),
              onIncrease: () => setState(() => _quantity++),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed:
                    StoreSettings.instance.orderingEnabled && itemAvailable
                    ? () {
                        for (var i = 0; i < _quantity; i++) {
                          orderCart.add(item);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} added to your cart'),
                          ),
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: NoshTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  StoreSettings.instance.orderingEnabled && itemAvailable
                      ? 'Add to cart  ·  \$${(item.price * _quantity).toStringAsFixed(2)}'
                      : itemAvailable
                      ? 'Ordering is currently paused'
                      : 'Currently unavailable',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your cart',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          AnimatedBuilder(
            animation: orderCart,
            builder: (context, _) => orderCart.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: orderCart.clear,
                    child: const Text('Clear'),
                  ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([orderCart, StoreSettings.instance]),
        builder: (context, _) {
          if (orderCart.isEmpty) {
            return const _EmptyCart();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: NoshTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: NoshTheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: NoshTheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        StoreSettings.instance.restaurantName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      StoreSettings.instance.estimatedDeliveryTime,
                      style: TextStyle(color: NoshTheme.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...orderCart.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CartLineTile(line: line),
                ),
              ),
              const SizedBox(height: 8),
              _BillDetails(
                subtotal: orderCart.subtotal,
                deliveryFee: orderCart.deliveryFee,
                tax: orderCart.tax,
                total: orderCart.total,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: StoreSettings.instance.orderingEnabled
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CheckoutScreen(),
                        ),
                      )
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: NoshTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  StoreSettings.instance.orderingEnabled
                      ? 'Continue to checkout  ·  \$${orderCart.total.toStringAsFixed(2)}'
                      : 'Ordering is currently paused',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 54,
              color: NoshTheme.primarySoft,
            ),
            const SizedBox(height: 15),
            const Text(
              'Your cart is taking a breather',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            const Text(
              'Add something delicious to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NoshTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(backgroundColor: NoshTheme.primary),
              child: const Text('Explore the menu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: NoshTheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: NoshTheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          FoodImage(
            url: line.item.imageUrl,
            width: 76,
            height: 76,
            borderRadius: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${line.item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: NoshTheme.primarySoft,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                _QuantityControl(
                  quantity: line.quantity,
                  onDecrease: () => orderCart.removeOne(line.item.id),
                  onIncrease: () => orderCart.add(line.item),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove ${line.item.name}',
            onPressed: () => orderCart.remove(line.item.id),
            icon: const Icon(
              Icons.close_rounded,
              color: NoshTheme.muted,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _paymentMethod = 'Card ending in 4242';
  bool _placingOrder = false;

  @override
  void initState() {
    super.initState();
    StoreSettings.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    StoreSettings.instance.removeListener(_refresh);
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            const _CheckoutSectionTitle(
              icon: Icons.location_on_outlined,
              title: 'Delivery address',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Street address',
                hintText: 'Enter your delivery address',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (value) => (value == null || value.trim().length < 5)
                  ? 'Enter a complete delivery address'
                  : null,
            ),
            const SizedBox(height: 11),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: 'For delivery updates',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) => (value == null || value.trim().length < 7)
                  ? 'Enter a valid phone number'
                  : null,
            ),
            const SizedBox(height: 24),
            const _CheckoutSectionTitle(
              icon: Icons.credit_card_rounded,
              title: 'Payment method',
            ),
            const SizedBox(height: 10),
            _PaymentOption(
              icon: Icons.credit_card_rounded,
              title: 'Card ending in 4242',
              detail: 'Expires 08/28',
              selected: _paymentMethod == 'Card ending in 4242',
              onTap: () =>
                  setState(() => _paymentMethod = 'Card ending in 4242'),
            ),
            const SizedBox(height: 9),
            _PaymentOption(
              icon: Icons.payments_outlined,
              title: 'Cash on delivery',
              detail: 'Pay when your food arrives',
              selected: _paymentMethod == 'Cash on delivery',
              onTap: () => setState(() => _paymentMethod = 'Cash on delivery'),
            ),
            const SizedBox(height: 24),
            const _CheckoutSectionTitle(
              icon: Icons.receipt_outlined,
              title: 'Order summary',
            ),
            const SizedBox(height: 10),
            ...orderCart.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${line.quantity} × ${line.item.name}',
                      style: const TextStyle(
                        color: NoshTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${line.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            _BillDetails(
              subtotal: orderCart.subtotal,
              deliveryFee: orderCart.deliveryFee,
              tax: orderCart.tax,
              total: orderCart.total,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed:
                  _placingOrder || !StoreSettings.instance.orderingEnabled
                  ? null
                  : _placeOrder,
              style: FilledButton.styleFrom(
                backgroundColor: NoshTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _placingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      StoreSettings.instance.orderingEnabled
                          ? 'Place order  ·  \$${orderCart.total.toStringAsFixed(2)}'
                          : 'Ordering is currently paused',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
            const SizedBox(height: 10),
            const Text(
              'By placing this order, you agree to our terms and refund policy.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NoshTheme.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!StoreSettings.instance.orderingEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordering is currently paused.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (orderCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty. Add a dish first.')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before placing an order.'),
        ),
      );
      return;
    }
    setState(() => _placingOrder = true);
    try {
      final order = await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'restaurantName': StoreSettings.instance.restaurantName,
        'status': 'Preparing',
        'createdAt': FieldValue.serverTimestamp(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'paymentMethod': _paymentMethod,
        'items': orderCart.lines
            .map(
              (line) => {
                'id': line.item.id,
                'name': line.item.name,
                'price': line.item.price,
                'quantity': line.quantity,
              },
            )
            .toList(),
        'subtotal': orderCart.subtotal,
        'deliveryFee': orderCart.deliveryFee,
        'tax': orderCart.tax,
        'total': orderCart.total,
      });
      orderCart.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              OrderTrackingScreen(orderId: order.id, status: 'Preparing'),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your order could not be placed: ${error.message ?? error.code}',
          ),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: ScaffoldMessenger.of(context).hideCurrentSnackBar,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }
}

class _CheckoutSectionTitle extends StatelessWidget {
  const _CheckoutSectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: NoshTheme.primarySoft, size: 20),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: selected
            ? NoshTheme.primary.withValues(alpha: 0.1)
            : NoshTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? NoshTheme.primary : NoshTheme.outline,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? NoshTheme.primarySoft : NoshTheme.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(color: NoshTheme.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? NoshTheme.primary : NoshTheme.muted,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({
    required this.orderId,
    this.status = 'Preparing',
    super.key,
  });

  final String orderId;
  final String status;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots(),
      builder: (context, snapshot) {
        final currentStatus =
            snapshot.data?.data()?['status']?.toString() ?? status;
        return _buildTracking(context, currentStatus);
      },
    );
  }

  Widget _buildTracking(BuildContext context, String currentStatus) {
    final steps = [
      ('Order received', 'The kitchen has your order.', Icons.receipt_rounded),
      (
        'Being prepared',
        'Freshly made by our chefs.',
        Icons.soup_kitchen_rounded,
      ),
      (
        'On its way',
        'Your courier is heading to you.',
        Icons.delivery_dining_rounded,
      ),
      ('Delivered', 'Time to enjoy your meal.', Icons.check_circle_rounded),
    ];
    final activeStep = switch (currentStatus.toLowerCase()) {
      'delivered' => 3,
      'on the way' || 'out for delivery' => 2,
      _ => 1,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Track your order',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3D1E10), Color(0xFF673017)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR ORDER IS',
                  style: TextStyle(
                    color: NoshTheme.primarySoft,
                    fontSize: 10,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  currentStatus,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Order #${_shortId(orderId)}  ·  ${StoreSettings.instance.restaurantName}',
                  style: const TextStyle(
                    color: Color(0xFFE5C7B6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: NoshTheme.primarySoft,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Estimated arrival',
                      style: TextStyle(color: Color(0xFFE5C7B6)),
                    ),
                    Spacer(),
                    Text(
                      StoreSettings.instance.estimatedDeliveryTime,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Order progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final complete = index <= activeStep;
            final current = index == activeStep;
            final step = steps[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 43,
                  child: Column(
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: complete
                              ? NoshTheme.primary.withValues(alpha: 0.18)
                              : NoshTheme.surfaceHigh,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: complete
                                ? NoshTheme.primary
                                : NoshTheme.outline,
                          ),
                        ),
                        child: Icon(
                          step.$3,
                          size: 18,
                          color: complete
                              ? NoshTheme.primarySoft
                              : NoshTheme.muted,
                        ),
                      ),
                      if (index != steps.length - 1)
                        Container(
                          width: 2,
                          height: 35,
                          color: index < activeStep
                              ? NoshTheme.primary
                              : NoshTheme.outline,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3, bottom: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: complete ? NoshTheme.text : NoshTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.$2,
                          style: const TextStyle(
                            color: NoshTheme.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (current)
                  const Text(
                    'NOW',
                    style: TextStyle(
                      color: NoshTheme.primarySoft,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            );
          }),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: NoshTheme.surface,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: NoshTheme.surfaceHigh,
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: NoshTheme.primarySoft,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need a hand?',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Our team is here for you.',
                        style: TextStyle(color: NoshTheme.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: NoshTheme.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order history',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Sign in to view your order history.',
                style: TextStyle(color: NoshTheme.muted),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'Order history could not be loaded. Check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: NoshTheme.muted),
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: NoshTheme.primary),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No past orders yet.',
                      style: TextStyle(color: NoshTheme.muted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final orderItems = (data['items'] as List<dynamic>? ?? [])
                        .map(
                          (entry) => entry is Map
                              ? entry['name']?.toString() ?? ''
                              : '',
                        )
                        .where((name) => name.isNotEmpty)
                        .join(', ');
                    final total = (data['total'] as num?)?.toDouble() ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: NoshTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: NoshTheme.outline.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORDER #${_shortId(doc.id)}',
                            style: const TextStyle(
                              color: NoshTheme.muted,
                              fontSize: 10,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            orderItems.isEmpty
                                ? StoreSettings.instance.restaurantName
                                : orderItems,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: NoshTheme.primarySoft,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                data['status']?.toString() ?? 'Preparing',
                                style: const TextStyle(
                                  color: NoshTheme.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _MenuListTile extends StatelessWidget {
  const _MenuListTile({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: NoshTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NoshTheme.outline.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          FoodImage(
            url: item.imageUrl,
            height: 88,
            width: 88,
            borderRadius: 14,
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
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: NoshTheme.amber,
                      size: 15,
                    ),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NoshTheme.muted,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: NoshTheme.primarySoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: StoreSettings.instance.orderingEnabled
                          ? () {
                              orderCart.add(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} added to cart'),
                                ),
                              );
                            }
                          : null,
                      child: const CircleAvatar(
                        radius: 15,
                        backgroundColor: NoshTheme.primary,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.add_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      decoration: BoxDecoration(
        color: NoshTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrease,
            borderRadius: BorderRadius.circular(9),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.remove_rounded, size: 17),
            ),
          ),
          SizedBox(
            width: 25,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          InkWell(
            onTap: onIncrease,
            borderRadius: BorderRadius.circular(9),
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.add_rounded, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillDetails extends StatelessWidget {
  const _BillDetails({
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
  });
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: NoshTheme.surface,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          _BillRow(label: 'Subtotal', amount: subtotal),
          const SizedBox(height: 9),
          _BillRow(
            label: 'Delivery',
            amount: deliveryFee,
            suffix: deliveryFee == 0 ? 'FREE' : null,
          ),
          const SizedBox(height: 9),
          _BillRow(label: 'Tax', amount: tax),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: NoshTheme.outline),
          ),
          _BillRow(label: 'Total', amount: total, isTotal: true),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.suffix,
  });
  final String label;
  final double amount;
  final bool isTotal;
  final String? suffix;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: TextStyle(
          color: isTotal ? NoshTheme.text : NoshTheme.muted,
          fontSize: isTotal ? 14 : 11,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      const Spacer(),
      if (suffix != null)
        Text(
          suffix!,
          style: const TextStyle(
            color: Color(0xFF92D1A0),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        )
      else
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isTotal ? NoshTheme.primarySoft : NoshTheme.text,
            fontSize: isTotal ? 16 : 11,
            fontWeight: FontWeight.w800,
          ),
        ),
    ],
  );
}

String _shortId(String id) => id.substring(0, id.length > 7 ? 7 : id.length);
