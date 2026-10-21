import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../state/menu_catalog.dart';
import '../../state/order_cart.dart';
import '../../theme/nosh_theme.dart';
import '../../widgets/food_image.dart';
import '../auth/login_screen.dart';
import 'commerce_screens.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    menuCatalog.addListener(_refreshMenu);
  }

  void _refreshMenu() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    menuCatalog.removeListener(_refreshMenu);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomeTab(),
      const _DiscoverTab(),
      const _OrdersTab(),
      const _ProfileTab(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedTab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        backgroundColor: NoshTheme.surface,
        indicatorColor: NoshTheme.primary.withValues(alpha: 0.16),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final items = _category == 'All'
        ? menuCatalog.items
        : menuCatalog.items
              .where((item) => item.category == _category)
              .toList();
    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          sliver: SliverToBoxAdapter(child: _HomeHeader(onCart: _openCart)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(child: _Greeting()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(child: _HeroCard(onTap: _openRestaurant)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _SectionHeading(
              title: 'Explore categories',
              action: 'See all',
              onAction: () => _openCategories(context),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 104,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              scrollDirection: Axis.horizontal,
              itemCount: MenuItem.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = MenuItem.categories[index];
                final selected = category == _category;
                return _CategoryButton(
                  label: category,
                  selected: selected,
                  onTap: () => setState(() => _category = category),
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          sliver: SliverToBoxAdapter(
            child: _SectionHeading(
              title: _category == 'All' ? 'Popular right now' : _category,
              action: 'View menu',
              onAction: () =>
                  _openCategories(context, initialCategory: _category),
            ),
          ),
        ),
        if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'More delicious dishes coming soon.',
                style: TextStyle(color: NoshTheme.muted),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
            sliver: SliverGrid.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 270,
              ),
              itemBuilder: (context, index) => _DishCard(
                item: items[index],
                onTap: () => _openDish(context, items[index]),
              ),
            ),
          ),
      ],
    );
  }

  void _openCart() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const CartScreen()));

  void _openRestaurant() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const RestaurantScreen()));
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onCart});
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: NoshTheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: NoshTheme.primary,
            size: 25,
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOSH BISTRO',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'DELIVERING TO',
              style: TextStyle(
                color: NoshTheme.muted,
                fontSize: 9,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(width: 7),
        const Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Downtown, 10001',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: NoshTheme.primarySoft,
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: orderCart,
          builder: (context, _) =>
              _CartButton(count: orderCart.itemCount, onTap: onCart),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firstName =
        FirebaseAuth.instance.currentUser?.displayName
            ?.trim()
            .split(' ')
            .first ??
        '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firstName.isEmpty ? 'Good evening' : 'Good evening, $firstName',
          style: const TextStyle(
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'What are you craving today?',
          style: TextStyle(color: NoshTheme.muted, fontSize: 14),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 198,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF3D1E10), Color(0xFF8A3510), Color(0xFFB84912)],
            begin: Alignment.centerLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: NoshTheme.primary.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -12,
              bottom: -12,
              width: 190,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(
                  'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=700&q=85',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.local_pizza_rounded,
                    size: 130,
                    color: Color(0xFFFFC078),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3D1E10).withValues(alpha: 0.97),
                      const Color(0xFF3D1E10).withValues(alpha: 0.78),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: NoshTheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'THE FLAME BISTRO',
                      style: TextStyle(
                        color: Color(0xFFFFD2AE),
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'A little fire.\nA lot of flavor.',
                    style: TextStyle(
                      fontSize: 23,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: NoshTheme.amber,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '4.9',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 7),
                      Text(
                        '·  20–30 min  ·  \$\$',
                        style: TextStyle(
                          color: Color(0xFFE8C9B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const Positioned(
              right: 16,
              bottom: 16,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: NoshTheme.primary,
                foregroundColor: Colors.white,
                child: Icon(Icons.arrow_forward_rounded, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (label) {
    'Pizza' => Icons.local_pizza_rounded,
    'Burgers' => Icons.lunch_dining_rounded,
    'Bowls' => Icons.rice_bowl_rounded,
    'Sushi' => Icons.set_meal_rounded,
    'Pasta' => Icons.dinner_dining_rounded,
    'Small plates' => Icons.tapas_rounded,
    'Desserts' => Icons.icecream_rounded,
    'Drinks' => Icons.local_cafe_rounded,
    _ => Icons.restaurant_menu_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 67,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: selected
                    ? NoshTheme.primary
                    : NoshTheme.surfaceHigh.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? NoshTheme.primary : NoshTheme.outline,
                  width: selected ? 1.5 : 0.7,
                ),
              ),
              child: Icon(
                _icon,
                color: selected ? Colors.white : NoshTheme.primarySoft,
                size: 25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? NoshTheme.text : NoshTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.25,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            foregroundColor: NoshTheme.primarySoft,
          ),
          child: Text(action, style: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({required this.item, required this.onTap});
  final MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: NoshTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NoshTheme.outline.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                FoodImage(
                  url: item.imageUrl,
                  width: double.infinity,
                  height: 136,
                  borderRadius: 19,
                ),
                if (item.isPopular)
                  Positioned(
                    left: 9,
                    top: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: NoshTheme.background.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'BESTSELLER',
                        style: TextStyle(
                          color: NoshTheme.primarySoft,
                          fontWeight: FontWeight.w900,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: NoshTheme.amber,
                      ),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: NoshTheme.muted, fontSize: 9),
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
                        onTap: () {
                          orderCart.add(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} added to cart'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: 'Open cart',
      style: IconButton.styleFrom(
        backgroundColor: NoshTheme.surfaceHigh,
        foregroundColor: NoshTheme.text,
      ),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 9 ? '9+' : '$count'),
        backgroundColor: NoshTheme.primary,
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

class _DiscoverTab extends StatefulWidget {
  const _DiscoverTab();

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  final _searchController = TextEditingController();
  String _category = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = menuCatalog.items.where((item) {
      final matchesCategory = _category == 'All' || item.category == _category;
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
    return CustomScrollView(
      key: const PageStorageKey('discover-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Find something worth slowing down for.',
                  style: TextStyle(color: NoshTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search dishes, ingredients...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: MenuItem.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = MenuItem.categories[index];
                      final selected = category == _category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) => setState(() => _category = category),
                        selectedColor: NoshTheme.primary,
                        backgroundColor: NoshTheme.surface,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : NoshTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(
                          color: selected
                              ? NoshTheme.primary
                              : NoshTheme.outline,
                        ),
                        showCheckmark: false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${filtered.length} delicious picks',
                  style: const TextStyle(
                    color: NoshTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No dishes match that search.',
                style: TextStyle(color: NoshTheme.muted),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid.builder(
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 270,
              ),
              itemBuilder: (context, index) => _DishCard(
                item: filtered[index],
                onTap: () => _openDish(context, filtered[index]),
              ),
            ),
          ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    final orders = FirebaseAuth.instance.currentUser == null
        ? null
        : FirebaseFirestore.instance
              .collection('orders')
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .orderBy('createdAt', descending: true)
              .limit(20)
              .snapshots();
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 6),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your orders',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                Text(
                  'Every good meal has a story.',
                  style: TextStyle(color: NoshTheme.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        if (orders == null)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyOrders())
        else
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: orders,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    title: 'Orders are unavailable',
                    message: 'Please try again in a moment.',
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: NoshTheme.primary),
                  ),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyOrders(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                sliver: SliverList.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _OrderCard(
                    data: docs[index].data(),
                    orderId: docs[index].id,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: NoshTheme.surfaceHigh,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: NoshTheme.primarySoft,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your table is waiting',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            const Text(
              'Place your first order and it’ll show up right here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NoshTheme.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.data, required this.orderId});
  final Map<String, dynamic> data;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString() ?? 'Preparing';
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((item) => item is Map ? item['name']?.toString() ?? '' : '')
        .where((name) => name.isNotEmpty)
        .take(2)
        .join(', ');
    final amount = (data['total'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: NoshTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NoshTheme.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ORDER #${orderId.substring(0, orderId.length.clamp(0, 7)).toUpperCase()}',
                  style: const TextStyle(
                    color: NoshTheme.muted,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            items.isEmpty ? 'Your Nosh Bistro order' : items,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: NoshTheme.primarySoft,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        OrderTrackingScreen(orderId: orderId, status: status),
                  ),
                ),
                icon: const Icon(Icons.location_on_outlined, size: 16),
                label: const Text('Track'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Guest account';
    final initial = email.isEmpty ? 'N' : email[0].toUpperCase();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text(
          'Profile',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: NoshTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: NoshTheme.outline.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: NoshTheme.primary.withValues(alpha: 0.22),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: NoshTheme.primarySoft,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Nosh guest',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: NoshTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                color: NoshTheme.primarySoft,
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _ProfileSectionTitle('YOUR ACCOUNT'),
        _ProfileTile(
          icon: Icons.receipt_long_outlined,
          title: 'Order history',
          subtitle: 'Past orders and receipts',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
          ),
        ),
        const _ProfileTile(
          icon: Icons.location_on_outlined,
          title: 'Saved addresses',
          subtitle: 'Manage your delivery locations',
        ),
        const _ProfileTile(
          icon: Icons.favorite_border_rounded,
          title: 'Favorites',
          subtitle: 'Your saved dishes',
        ),
        const SizedBox(height: 18),
        const _ProfileSectionTitle('PREFERENCES'),
        const _ProfileTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Order updates and offers',
        ),
        const _ProfileTile(
          icon: Icons.help_outline_rounded,
          title: 'Help & support',
          subtitle: 'We’re always happy to help',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: user == null ? null : () => _signOut(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: NoshTheme.primarySoft,
            side: const BorderSide(color: NoshTheme.outline),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not sign out: ${error.message ?? error.code}'),
        ),
      );
    }
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 7),
    child: Text(
      title,
      style: const TextStyle(
        color: NoshTheme.muted,
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: NoshTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 20, color: NoshTheme.primarySoft),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: NoshTheme.muted, fontSize: 10),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: NoshTheme.muted,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final done = status.toLowerCase() == 'delivered';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (done ? const Color(0xFF438B5B) : NoshTheme.primary).withValues(
          alpha: 0.16,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: done ? const Color(0xFF9DDAAC) : NoshTheme.primarySoft,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: NoshTheme.primarySoft,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: NoshTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

void _openDish(BuildContext context, MenuItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => DishDetailScreen(item: item)));
}

void _openCategories(BuildContext context, {String initialCategory = 'All'}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MenuScreen(initialCategory: initialCategory),
    ),
  );
}
