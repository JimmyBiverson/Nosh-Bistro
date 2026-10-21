import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../state/menu_catalog.dart';
import '../../theme/nosh_theme.dart';
import '../../widgets/food_image.dart';
import '../auth/login_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _tab = 0;
  String _category = 'All';
  String _menuQuery = '';

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
    final pages = [
      _DashboardTab(onNavigate: (tab) => setState(() => _tab = tab)),
      _MenuManagementTab(
        items: menuCatalog.items,
        category: _category,
        query: _menuQuery,
        onCategoryChanged: (category) => setState(() => _category = category),
        onQueryChanged: (query) => setState(() => _menuQuery = query),
        onAvailabilityChanged: menuCatalog.setAvailability,
        onAddDish: menuCatalog.add,
      ),
      const _AnalyticsTab(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        backgroundColor: NoshTheme.surface,
        indicatorColor: NoshTheme.primary.withValues(alpha: 0.16),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nosh Bistro',
                        style: TextStyle(
                          color: NoshTheme.primarySoft,
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Good evening, Chef',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: () => _signOut(context),
                  style: IconButton.styleFrom(
                    backgroundColor: NoshTheme.surfaceHigh,
                  ),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A2410), Color(0xFF7F3513)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TONIGHT AT A GLANCE',
                          style: TextStyle(
                            color: NoshTheme.primarySoft,
                            fontSize: 9,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Service is looking good.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Keep an eye on today’s kitchen tickets.',
                          style: TextStyle(
                            color: Color(0xFFE5C7B6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0x33FFB692),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: NoshTheme.primarySoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: const SliverToBoxAdapter(child: _DashboardMetrics()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 9),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent orders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigate(2),
                  child: const Text('View analytics'),
                ),
              ],
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverToBoxAdapter(child: _RecentOrders()),
        ),
      ],
    );
  }
}

class _DashboardMetrics extends StatelessWidget {
  const _DashboardMetrics();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(500)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: NoshTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Today’s metrics are unavailable. Check the Firestore connection and access rules.',
              style: TextStyle(color: NoshTheme.muted, fontSize: 12),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 110,
            child: Center(
              child: CircularProgressIndicator(color: NoshTheme.primary),
            ),
          );
        }
        final now = DateTime.now();
        final todayOrders = (snapshot.data?.docs ?? []).where((document) {
          final createdAt = document.data()['createdAt'];
          final date = createdAt is Timestamp ? createdAt.toDate() : null;
          return date != null &&
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList();
        final revenue = todayOrders.fold<double>(
          0,
          (total, order) =>
              total + ((order.data()['total'] as num?)?.toDouble() ?? 0),
        );
        final active = todayOrders
            .where((order) => order.data()['status'] != 'Delivered')
            .length;
        final average = todayOrders.isEmpty ? 0 : revenue / todayOrders.length;
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 11,
          crossAxisSpacing: 11,
          childAspectRatio: 1.7,
          children: [
            _MetricCard(
              title: 'TODAY’S REVENUE',
              value: '\$${revenue.toStringAsFixed(0)}',
              delta: 'Today',
              icon: Icons.payments_outlined,
              positive: true,
            ),
            _MetricCard(
              title: 'ORDERS TODAY',
              value: '${todayOrders.length}',
              delta: 'Today',
              icon: Icons.receipt_long_outlined,
              positive: true,
            ),
            _MetricCard(
              title: 'AVG. ORDER',
              value: '\$${average.toStringAsFixed(2)}',
              delta: 'Today',
              icon: Icons.shopping_bag_outlined,
              positive: true,
            ),
            _MetricCard(
              title: 'ACTIVE ORDERS',
              value: '$active',
              delta: 'In progress',
              icon: Icons.delivery_dining_rounded,
              positive: true,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.positive,
  });

  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NoshTheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: NoshTheme.outline.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: NoshTheme.primarySoft),
              const Spacer(),
              Icon(
                positive ? Icons.trending_up_rounded : Icons.trending_down,
                color: positive ? const Color(0xFF9DDAAC) : NoshTheme.error,
                size: 15,
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NoshTheme.muted,
                    fontSize: 8,
                    letterSpacing: 0.45,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                delta,
                style: TextStyle(
                  color: positive ? const Color(0xFF9DDAAC) : NoshTheme.error,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: NoshTheme.surface,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Text(
              'Recent orders are unavailable. Check the Firestore connection and access rules.',
              style: TextStyle(color: NoshTheme.muted, fontSize: 12),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(22),
            child: Center(
              child: CircularProgressIndicator(color: NoshTheme.primary),
            ),
          );
        }
        final orders = snapshot.data?.docs ?? [];
        if (orders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NoshTheme.surface,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Row(
              children: [
                Icon(Icons.inbox_outlined, color: NoshTheme.primarySoft),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'New orders will appear here.',
                    style: TextStyle(color: NoshTheme.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: orders.map((order) {
            final data = order.data();
            final items = (data['items'] as List<dynamic>? ?? [])
                .map(
                  (entry) =>
                      entry is Map ? entry['name']?.toString() ?? '' : '',
                )
                .where((name) => name.isNotEmpty)
                .take(2)
                .join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: NoshTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: NoshTheme.surfaceHigh,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: NoshTheme.primarySoft,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items.isEmpty ? 'New order' : items,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Order #${_shortId(order.id)}',
                                style: const TextStyle(
                                  color: NoshTheme.muted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${((data['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['status']?.toString() ?? 'Preparing',
                              style: const TextStyle(
                                color: NoshTheme.primarySoft,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: data['status'] == 'Delivered'
                            ? null
                            : () => _advanceOrder(
                                context,
                                order.reference,
                                data['status']?.toString() ?? 'Pending',
                              ),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                        ),
                        label: Text(switch ((data['status']?.toString() ??
                                'Pending')
                            .toLowerCase()) {
                          'pending' => 'Accept in kitchen',
                          'preparing' => 'Mark ready for pickup',
                          'ready for pickup' ||
                          'on the way' => 'Complete delivery',
                          _ => 'Delivered',
                        }),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NoshTheme.primarySoft,
                          side: const BorderSide(color: NoshTheme.outline),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          textStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MenuManagementTab extends StatelessWidget {
  const _MenuManagementTab({
    required this.items,
    required this.category,
    required this.query,
    required this.onCategoryChanged,
    required this.onQueryChanged,
    required this.onAvailabilityChanged,
    required this.onAddDish,
  });

  final List<MenuItem> items;
  final String category;
  final String query;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onQueryChanged;
  final void Function(String itemId, bool available) onAvailabilityChanged;
  final void Function({
    required String name,
    required String category,
    required double price,
  })
  onAddDish;

  @override
  Widget build(BuildContext context) {
    final itemEntries = items.where((item) {
      final matchesCategory = category == 'All' || item.category == category;
      final normalizedQuery = query.toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty ||
          item.name.toLowerCase().contains(normalizedQuery) ||
          item.description.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesQuery;
    }).toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MENU MANAGEMENT',
                        style: TextStyle(
                          color: NoshTheme.primarySoft,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your menu',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddDish(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: NoshTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text(
                    'Add dish',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
          sliver: SliverToBoxAdapter(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search menu items',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: onQueryChanged,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 49,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              scrollDirection: Axis.horizontal,
              itemCount: MenuItem.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final itemCategory = MenuItem.categories[index];
                return ChoiceChip(
                  label: Text(itemCategory),
                  selected: itemCategory == category,
                  onSelected: (_) => onCategoryChanged(itemCategory),
                  selectedColor: NoshTheme.primary,
                  backgroundColor: NoshTheme.surface,
                  labelStyle: TextStyle(
                    color: itemCategory == category
                        ? Colors.white
                        : NoshTheme.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: itemCategory == category
                        ? NoshTheme.primary
                        : NoshTheme.outline,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 24),
          sliver: SliverList.separated(
            itemCount: itemEntries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = itemEntries[index];
              final available = item.isAvailable;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NoshTheme.surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: NoshTheme.outline.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  children: [
                    FoodImage(
                      url: item.imageUrl,
                      height: 66,
                      width: 66,
                      borderRadius: 13,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.category}  ·  \$${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: NoshTheme.muted,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            available ? 'AVAILABLE' : 'SOLD OUT',
                            style: TextStyle(
                              color: available
                                  ? const Color(0xFF9DDAAC)
                                  : NoshTheme.muted,
                              fontSize: 8,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: available,
                      activeThumbColor: NoshTheme.primary,
                      onChanged: (value) =>
                          onAvailabilityChanged(item.id, value),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDish(BuildContext context) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedCategory = 'Pizza';
    final shouldAdd = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NoshTheme.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          22,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add a menu item',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Dish name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setSheetState) =>
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: MenuItem.categories
                          .where((category) => category != 'All')
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedCategory = value);
                        }
                      },
                    ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (value) {
                  final price = double.tryParse(value ?? '');
                  return price == null || price <= 0
                      ? 'Enter a valid price'
                      : null;
                },
              ),
              const SizedBox(height: 15),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop(true);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: NoshTheme.primary,
                ),
                child: const Text('Add to menu'),
              ),
            ],
          ),
        ),
      ),
    );
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text);
    nameController.dispose();
    priceController.dispose();
    if (shouldAdd == true && price != null && context.mounted) {
      onAddDish(name: name, category: selectedCategory, price: price);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dish added to the menu.')));
    }
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(500)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'Analytics are unavailable. Check the Firestore connection and access rules.',
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
        final orders = snapshot.data?.docs ?? [];
        final now = DateTime.now();
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        final weekOrders = orders.where((order) {
          final createdAt = order.data()['createdAt'];
          final date = createdAt is Timestamp ? createdAt.toDate() : null;
          return date != null && !date.isBefore(weekStart);
        }).toList();
        final dailyRevenue = List<double>.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          return weekOrders
              .where((order) {
                final createdAt = order.data()['createdAt'];
                if (createdAt is! Timestamp) return false;
                final date = createdAt.toDate();
                return date.year == day.year &&
                    date.month == day.month &&
                    date.day == day.day;
              })
              .fold<double>(
                0,
                (total, order) =>
                    total + ((order.data()['total'] as num?)?.toDouble() ?? 0),
              );
        });
        final weekRevenue = dailyRevenue.fold<double>(
          0,
          (total, amount) => total + amount,
        );
        final dishCounts = <String, int>{};
        for (final order in weekOrders) {
          for (final entry in (order.data()['items'] as List<dynamic>? ?? [])) {
            if (entry is! Map) continue;
            final name = entry['name']?.toString();
            if (name == null || name.isEmpty) continue;
            final count = (entry['quantity'] as num?)?.toInt() ?? 1;
            dishCounts.update(
              name,
              (current) => current + count,
              ifAbsent: () => count,
            );
          }
        }
        final topDishes = dishCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR RESTAURANT',
                      style: TextStyle(
                        color: NoshTheme.primarySoft,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Analytics',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: NoshTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: NoshTheme.outline.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Revenue overview',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Last 7 days  ·  ${weekOrders.length} orders',
                                  style: TextStyle(
                                    color: NoshTheme.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF438B5B,
                              ).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Color(0xFF9DDAAC),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '\$${weekRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _RevenueChartPainter(values: dailyRevenue),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          7,
                          (index) => _ChartLabel(
                            const [
                              'MON',
                              'TUE',
                              'WED',
                              'THU',
                              'FRI',
                              'SAT',
                              'SUN',
                            ][(weekStart.weekday - 1 + index) % 7],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 19, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Top-performing dishes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.separated(
                itemCount: topDishes.isEmpty ? 1 : topDishes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  if (topDishes.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NoshTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Dish sales will appear after the first orders are placed.',
                        style: TextStyle(color: NoshTheme.muted, fontSize: 11),
                      ),
                    );
                  }
                  final entry = topDishes[index];
                  final item = MenuItem.samples.firstWhere(
                    (menuItem) => menuItem.name == entry.key,
                    orElse: () => MenuItem.samples.first,
                  );
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NoshTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        FoodImage(
                          url: item.imageUrl,
                          height: 48,
                          width: 48,
                          borderRadius: 12,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} sold',
                          style: const TextStyle(
                            color: NoshTheme.primarySoft,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartLabel extends StatelessWidget {
  const _ChartLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: NoshTheme.muted,
      fontSize: 8,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _RevenueChartPainter extends CustomPainter {
  const _RevenueChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );
    final points = List<Offset>.generate(values.length, (index) {
      final x = values.length <= 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final relative = peak == 0 ? 0.0 : values[index] / peak;
      final y = size.height * (.88 - relative * .68);
      return Offset(x, y);
    });
    final gridPaint = Paint()
      ..color = NoshTheme.outline.withValues(alpha: .45)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = i * size.height / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final middleX = (previous.dx + current.dx) / 2;
      path.cubicTo(
        middleX,
        previous.dy,
        middleX,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x55FF6D00), Color(0x00FF6D00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = NoshTheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final dotPaint = Paint()..color = NoshTheme.primarySoft;
    canvas.drawCircle(points.last, 4.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) =>
      oldDelegate.values != values;
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

Future<void> _advanceOrder(
  BuildContext context,
  DocumentReference<Map<String, dynamic>> order,
  String status,
) async {
  final nextStatus = switch (status.toLowerCase()) {
    'pending' => 'Preparing',
    'preparing' => 'Ready for pickup',
    'ready for pickup' || 'on the way' => 'Delivered',
    _ => null,
  };
  if (nextStatus == null) return;
  try {
    await order.update({
      'status': nextStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order status updated to $nextStatus.')),
    );
  } on FirebaseException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not update order: ${error.message ?? error.code}'),
      ),
    );
  }
}

String _shortId(String id) => id.substring(0, id.length > 7 ? 7 : id.length);
