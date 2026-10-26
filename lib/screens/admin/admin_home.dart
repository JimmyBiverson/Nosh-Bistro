import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../services/store_settings.dart';
import '../../state/menu_catalog.dart';
import '../../theme/nosh_theme.dart';
import '../../widgets/food_image.dart';

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
    StoreSettings.instance.addListener(_refreshMenu);
  }

  void _refreshMenu() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    menuCatalog.removeListener(_refreshMenu);
    StoreSettings.instance.removeListener(_refreshMenu);
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
        onAvailabilityChanged: _setAvailability,
        onSaveDish: _saveDish,
        onDeleteDish: _deleteDish,
      ),
      const _AnalyticsTab(),
      const _SettingsTab(),
      const _AccountsTab(),
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
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            label: 'Accounts',
          ),
        ],
      ),
    );
  }

  Future<void> _setAvailability(String itemId, bool available) async {
    await _runAdminAction(() => menuCatalog.setAvailability(itemId, available));
  }

  Future<void> _saveDish(MenuItem item) async {
    await _runAdminAction(() async {
      if (item.id.isEmpty) {
        await menuCatalog.add(
          name: item.name,
          description: item.description,
          category: item.category,
          price: item.price,
          imageUrl: item.imageUrl,
          isPopular: item.isPopular,
        );
      } else {
        await menuCatalog.update(item);
      }
    });
  }

  Future<void> _deleteDish(String itemId) async {
    await _runAdminAction(() => menuCatalog.delete(itemId));
  }

  Future<void> _runAdminAction(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save changes: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (menuCatalog.error != null)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Menu data could not be refreshed. Check Firestore access and connection.',
                style: TextStyle(color: NoshTheme.error, fontSize: 12),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StoreSettings.instance.appName,
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
    required this.onSaveDish,
    required this.onDeleteDish,
  });

  final List<MenuItem> items;
  final String category;
  final String query;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onQueryChanged;
  final void Function(String itemId, bool available) onAvailabilityChanged;
  final ValueChanged<MenuItem> onSaveDish;
  final ValueChanged<String> onDeleteDish;

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
                  onPressed: () => _showDishForm(context),
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
              itemCount: MenuItem.categoriesFor(items).length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final itemCategory = MenuItem.categoriesFor(items)[index];
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
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showDishForm(context, item: item);
                        } else if (action == 'delete') {
                          _confirmDelete(context, item);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
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

  Future<void> _showDishForm(BuildContext context, {MenuItem? item}) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    final priceController = TextEditingController(
      text: item?.price.toStringAsFixed(2) ?? '',
    );
    final imageController = TextEditingController(text: item?.imageUrl ?? '');
    final formKey = GlobalKey<FormState>();
    var selectedCategory = item?.category ?? MenuItem.defaultCategories[1];
    var isPopular = item?.isPopular ?? false;
    final result = await showModalBottomSheet<MenuItem>(
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
        child: StatefulBuilder(
          builder: (context, setSheetState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item == null ? 'Add a menu item' : 'Edit menu item',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Dish name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a dish name'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a description'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: MenuItem.categoriesFor(items)
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Price'),
                    validator: (value) {
                      final price = double.tryParse(value ?? '');
                      return price == null || !price.isFinite || price <= 0
                          ? 'Enter a valid price'
                          : null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: imageController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Photo URL',
                      helperText: 'Use a public HTTPS image URL.',
                    ),
                    validator: (value) {
                      final uri = Uri.tryParse(value?.trim() ?? '');
                      return uri == null ||
                              uri.scheme != 'https' ||
                              uri.host.isEmpty
                          ? 'Enter a valid HTTPS image URL'
                          : null;
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Feature as popular'),
                    value: isPopular,
                    onChanged: (value) =>
                        setSheetState(() => isPopular = value),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final price = double.parse(priceController.text.trim());
                      Navigator.of(context).pop(
                        MenuItem(
                          id: item?.id ?? '',
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim(),
                          category: selectedCategory,
                          price: price,
                          imageUrl: imageController.text.trim(),
                          rating: item?.rating ?? 5,
                          isPopular: isPopular,
                          isAvailable: item?.isAvailable ?? true,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: NoshTheme.primary,
                    ),
                    child: Text(item == null ? 'Add to menu' : 'Save changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    imageController.dispose();
    if (result != null && context.mounted) {
      onSaveDish(result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, MenuItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete menu item?'),
        content: Text('“${item.name}” will no longer appear to customers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) onDeleteDish(item.id);
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late bool _orderingEnabled;
  late Color _primaryColor;
  late Color _backgroundColor;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = StoreSettings.instance;
    _controllers = {
      'appName': TextEditingController(text: settings.appName),
      'restaurantName': TextEditingController(text: settings.restaurantName),
      'tagline': TextEditingController(text: settings.tagline),
      'description': TextEditingController(text: settings.description),
      'heroImageUrl': TextEditingController(text: settings.heroImageUrl),
      'logoUrl': TextEditingController(text: settings.logoUrl),
      'phone': TextEditingController(text: settings.phone),
      'address': TextEditingController(text: settings.address),
      'businessHours': TextEditingController(text: settings.businessHours),
      'estimatedDeliveryTime': TextEditingController(
        text: settings.estimatedDeliveryTime,
      ),
      'deliveryFee': TextEditingController(
        text: settings.deliveryFee.toStringAsFixed(2),
      ),
      'freeDeliveryThreshold': TextEditingController(
        text: settings.freeDeliveryThreshold.toStringAsFixed(2),
      ),
      'taxRate': TextEditingController(
        text: (settings.taxRate * 100).toStringAsFixed(2),
      ),
    };
    _orderingEnabled = settings.orderingEnabled;
    _primaryColor = Color(settings.primaryColor);
    _backgroundColor = Color(settings.backgroundColor);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = StoreSettings.instance;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        children: [
          const Text(
            'Store settings',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'Changes publish to customer screens as soon as they are saved.',
            style: TextStyle(color: NoshTheme.muted, fontSize: 12),
          ),
          if (settings.error != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Store settings could not be loaded. Check Firestore access and connection.',
              style: TextStyle(color: NoshTheme.error),
            ),
          ],
          const SizedBox(height: 20),
          _field('appName', 'App display name'),
          _field('restaurantName', 'Restaurant name'),
          _field('tagline', 'Home page tagline'),
          _field('description', 'Restaurant description', maxLines: 3),
          _field(
            'heroImageUrl',
            'Home page cover photo URL',
            keyboardType: TextInputType.url,
            validateUrl: true,
          ),
          _field(
            'logoUrl',
            'App logo URL',
            keyboardType: TextInputType.url,
            validateUrl: true,
            optional: true,
          ),
          _field('phone', 'Contact phone'),
          _field('address', 'Restaurant / delivery area'),
          _field('businessHours', 'Business hours'),
          _field('estimatedDeliveryTime', 'Estimated delivery time'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers['deliveryFee'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Delivery fee'),
            validator: _validateNonNegativeNumber,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _controllers['freeDeliveryThreshold'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Free delivery minimum',
            ),
            validator: _validateNonNegativeNumber,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _controllers['taxRate'],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Tax rate (%)',
              helperText: 'Enter a percentage from 0 to 100.',
            ),
            validator: (value) {
              final number = double.tryParse(value ?? '');
              return number == null ||
                      !number.isFinite ||
                      number < 0 ||
                      number > 100
                  ? 'Enter a percentage between 0 and 100'
                  : null;
            },
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Accepting orders'),
            subtitle: const Text(
              'Turn this off to prevent customers from placing orders.',
            ),
            value: _orderingEnabled,
            onChanged: (value) => setState(() => _orderingEnabled = value),
          ),
          const SizedBox(height: 8),
          _colorTile(
            title: 'Accent color',
            color: _primaryColor,
            onTap: () => _chooseColor(primary: true),
          ),
          _colorTile(
            title: 'Background color',
            color: _backgroundColor,
            onTap: () => _chooseColor(primary: false),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Publish store changes'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Image uploads are not configured; use public HTTPS image URLs. Updating the native launcher icon or browser favicon requires a new app/web build.',
            style: TextStyle(color: NoshTheme.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool validateUrl = false,
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: _controllers[key],
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty && optional) return null;
        if (text.isEmpty) return 'This field is required';
        if (validateUrl && text.isNotEmpty) {
          final uri = Uri.tryParse(text);
          if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
            return 'Enter a valid HTTPS URL';
          }
        }
        return null;
      },
    ),
  );

  Widget _colorTile({
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
    ),
    trailing: CircleAvatar(backgroundColor: color, radius: 16),
    onTap: onTap,
  );

  Future<void> _chooseColor({required bool primary}) async {
    const colors = [
      Color(0xFFFF6D00),
      Color(0xFFE53935),
      Color(0xFF8E24AA),
      Color(0xFF3949AB),
      Color(0xFF00897B),
      Color(0xFF43A047),
      Color(0xFF6D4C41),
      Color(0xFF263238),
    ];
    final selected = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose a color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors
              .map(
                (color) => InkWell(
                  onTap: () => Navigator.pop(context, color),
                  child: CircleAvatar(backgroundColor: color, radius: 22),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        if (primary) {
          _primaryColor = selected;
        } else {
          _backgroundColor = selected;
        }
      });
    }
  }

  String? _validateNonNegativeNumber(String? value) {
    final number = double.tryParse(value ?? '');
    return number == null || !number.isFinite || number < 0
        ? 'Enter a valid non-negative amount'
        : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await StoreSettings.instance.save({
        for (final entry in _controllers.entries)
          if (!{
            'deliveryFee',
            'freeDeliveryThreshold',
            'taxRate',
          }.contains(entry.key))
            entry.key: entry.value.text.trim(),
        'deliveryFee': double.parse(_controllers['deliveryFee']!.text),
        'freeDeliveryThreshold': double.parse(
          _controllers['freeDeliveryThreshold']!.text,
        ),
        'taxRate': double.parse(_controllers['taxRate']!.text) / 100,
        'orderingEnabled': _orderingEnabled,
        'primaryColor': _primaryColor.toARGB32(),
        'backgroundColor': _backgroundColor.toARGB32(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store settings published.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settings could not be saved: ${error.message ?? error.code}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AccountsTab extends StatelessWidget {
  const _AccountsTab();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accounts',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 5),
                Text(
                  'Review customer profiles and manage app roles.',
                  style: TextStyle(color: NoshTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Accounts are unavailable. Check Firestore security rules and access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: NoshTheme.error),
                    ),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: NoshTheme.primary),
                );
              }
              final users = snapshot.data?.docs ?? [];
              if (users.isEmpty) {
                return const Center(child: Text('No user profiles yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data();
                  final isAdmin = data['role'] == 'admin';
                  final isSelf = user.id == currentUserId;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: NoshTheme.surface,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: NoshTheme.primary.withValues(
                            alpha: 0.16,
                          ),
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: NoshTheme.primarySoft,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['displayName']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? data['displayName'].toString()
                                    : 'Customer',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                data['email']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: NoshTheme.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit customer profile',
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () =>
                              _editProfile(context, user.reference, data),
                        ),
                        DropdownButton<String>(
                          value: isAdmin ? 'admin' : 'customer',
                          underline: const SizedBox.shrink(),
                          onChanged: isSelf
                              ? null
                              : (role) =>
                                    _changeRole(context, user.reference, role!),
                          items: const [
                            DropdownMenuItem(
                              value: 'customer',
                              child: Text('Customer'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
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
        ),
      ],
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data,
  ) async {
    final nameController = TextEditingController(
      text: data['displayName']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: data['phone']?.toString() ?? '',
    );
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit customer profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final displayName = nameController.text.trim();
    final phone = phoneController.text.trim();
    nameController.dispose();
    phoneController.dispose();
    if (shouldSave != true || !context.mounted) return;
    try {
      await reference.update({'displayName': displayName, 'phone': phone});
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile could not be saved: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  Future<void> _changeRole(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
    String role,
  ) async {
    try {
      await reference.update({'role': role});
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account role updated.')));
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account role could not be updated: ${error.message ?? error.code}',
          ),
        ),
      );
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
