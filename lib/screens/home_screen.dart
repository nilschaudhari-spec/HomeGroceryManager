import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../data/grocery_database.dart';
import '../models/grocery_item.dart';
import '../services/ads_service.dart';
import '../services/notification_service.dart';
import 'item_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GroceryItem> _items = [];
  String _search = '';
  bool _shoppingOnly = false;
  BannerAd? _banner;
  bool _bannerLoaded = false;
  int _restockCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    if (!kIsWeb && !const bool.fromEnvironment('FLUTTER_TEST')) {
      _initBanner();
    }
  }

  void _initBanner() {
    _banner = AdsService.instance.createBanner(
      onLoaded: () {
        if (mounted) setState(() => _bannerLoaded = true);
      },
      onFailed: (error) {
        debugPrint('[HomeScreen] Banner ad failed: $error');
        if (mounted) setState(() => _bannerLoaded = false);
      },
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await GroceryDatabase.instance.all(search: _search);
    if (!mounted) return;
    setState(() {
      _items = _shoppingOnly
          ? rows.where((e) => e.onShoppingList).toList()
          : rows;
    });
  }

  Future<void> _add() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ItemFormScreen()),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _edit(GroceryItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _toggleShopping(GroceryItem item, bool value) async {
    final updated = item.copyWith(onShoppingList: value);
    await GroceryDatabase.instance.update(updated);
    if (value && item.isLowStock) {
      await NotificationService.instance.lowStock(item);
    }
    if (!mounted) return;
    await _load();
  }

  Future<void> _purchased(GroceryItem item) async {
    final controller = TextEditingController(
      text: item.minimumQuantity.toString(),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current: ${item.quantity} ${item.unit}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'New quantity (${item.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              Navigator.pop(ctx, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (amount != null && amount >= 0) {
      final updated = item.copyWith(
        quantity: amount,
        onShoppingList: false,
        lastPurchasedAt: DateTime.now(),
      );
      await GroceryDatabase.instance.update(updated);
      await NotificationService.instance.schedule(updated);

      _restockCount++;
      if (_restockCount % 3 == 0) {
        await AdsService.instance.showInterstitialIfReady(onFinished: () {});
      }
      if (!mounted) return;
      await _load();
    }
  }

  Future<void> _deleteItem(GroceryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        content: const Text('This will remove the item from your inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GroceryDatabase.instance.delete(item.id);
      await NotificationService.instance.cancel(item.id);
      if (!mounted) return;
      await _load();
    }
  }

  void _showAboutAndPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF26734D)),
            SizedBox(width: 8),
            Text('About & Privacy'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Home Grocery Manager v1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Offline-First: All grocery items, quantities, categories, and reminder schedules are stored exclusively on your device in a local SQLite database.',
              ),
              SizedBox(height: 6),
              Text(
                '• No Account or Cloud Sync: Your household inventory data never leaves your device and is not sent to external servers.',
              ),
              SizedBox(height: 6),
              Text(
                '• Local Notifications: Reminders and low-stock alerts are triggered locally by your device operating system without requiring an internet connection.',
              ),
              SizedBox(height: 6),
              Text(
                '• Advertising & Monetization: This application integrates Google AdMob for banner and interstitial ads. Ads require internet access and comply with Google Mobile Ads policies.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _items.where((e) => e.isLowStock).length;
    final dueSoonCount = _items
        .where((e) => e.dailyConsumption > 0 && e.daysRemaining <= 7)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Grocery Manager'),
        actions: [
          IconButton(
            tooltip: 'Notification permissions',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () async {
              await NotificationService.instance.requestPermissions();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification permission requested.'),
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'About & Privacy',
            icon: const Icon(Icons.info_outline),
            onPressed: _showAboutAndPrivacyDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add Grocery'),
      ),
      bottomNavigationBar: _bannerLoaded && _banner != null
          ? SafeArea(
              child: SizedBox(
                height: _banner!.size.height.toDouble(),
                width: _banner!.size.width.toDouble(),
                child: AdWidget(ad: _banner!),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Overview Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pantry & Household Stock',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track consumption and smart restock advisory.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statCard(
                        'Total items',
                        '${_items.length}',
                        Icons.inventory_2_outlined,
                      ),
                      const SizedBox(width: 8),
                      _statCard(
                        'Low stock',
                        '$lowStockCount',
                        Icons.warning_amber_rounded,
                        isWarning: lowStockCount > 0,
                      ),
                      const SizedBox(width: 8),
                      _statCard(
                        'Due ≤7 days',
                        '$dueSoonCount',
                        Icons.event_available_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by grocery or category',
                border: OutlineInputBorder(),
                filled: true,
              ),
              onChanged: (v) {
                _search = v;
                _load();
              },
            ),
            const SizedBox(height: 12),

            // Filter Chips
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All groceries'),
                  selected: !_shoppingOnly,
                  onSelected: (_) {
                    setState(() => _shoppingOnly = false);
                    _load();
                  },
                ),
                FilterChip(
                  avatar: const Icon(Icons.shopping_cart_outlined, size: 16),
                  label: const Text('Shopping list'),
                  selected: _shoppingOnly,
                  onSelected: (_) {
                    setState(() => _shoppingOnly = true);
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item List or Empty State
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  children: [
                    Icon(
                      _shoppingOnly
                          ? Icons.shopping_basket_outlined
                          : Icons.kitchen_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _shoppingOnly
                          ? 'Your shopping list is empty'
                          : 'No groceries recorded yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _shoppingOnly
                          ? 'Add low-stock items or check off groceries.'
                          : 'Tap "Add Grocery" below to add household items.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              )
            else
              ..._items.map(_groceryTile),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon, {
    bool isWarning = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: isWarning
              ? Border.all(color: Colors.amber.shade700, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: isWarning ? Colors.amber.shade800 : null,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isWarning ? Colors.amber.shade900 : null,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _groceryTile(GroceryItem item) {
    final subtitleBuffer = StringBuffer();
    subtitleBuffer.write('${item.quantity} ${item.unit} left');

    if (item.dailyConsumption > 0) {
      if (item.daysRemaining.isFinite) {
        subtitleBuffer.write(
          ' • ~${item.daysRemaining.toStringAsFixed(1)} days left',
        );
      }
    } else {
      subtitleBuffer.write(' • Daily use not set');
    }

    if (item.pricePerUnit > 0) {
      subtitleBuffer.write(' • ₹${item.pricePerUnit}/${item.unit}');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isLowStock
              ? Colors.amber.shade400
              : Colors.grey.shade300,
          width: item.isLowStock ? 1.5 : 0.8,
        ),
      ),
      child: ListTile(
        onTap: () => _edit(item),
        leading: CircleAvatar(
          backgroundColor: item.isLowStock
              ? Colors.amber.shade100
              : Colors.green.shade50,
          child: Icon(
            item.isLowStock
                ? Icons.warning_amber_rounded
                : Icons.kitchen_outlined,
            color: item.isLowStock
                ? Colors.amber.shade800
                : Colors.green.shade800,
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitleBuffer.toString(),
              style: const TextStyle(fontSize: 12),
            ),
            if (item.isLowStock)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LOW STOCK (Reorder ~${item.estimatedReorderQuantity} ${item.unit})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: item.isLowStock,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                item.onShoppingList
                    ? Icons.shopping_cart
                    : Icons.add_shopping_cart_outlined,
                color: item.onShoppingList
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              tooltip: item.onShoppingList
                  ? 'Remove from shopping list'
                  : 'Add to shopping list',
              onPressed: () => _toggleShopping(item, !item.onShoppingList),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'shopping') {
                  await _toggleShopping(item, !item.onShoppingList);
                } else if (v == 'purchased') {
                  await _purchased(item);
                } else if (v == 'delete') {
                  await _deleteItem(item);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'shopping',
                  child: Text(
                    item.onShoppingList
                        ? 'Remove from shopping list'
                        : 'Add to shopping list',
                  ),
                ),
                const PopupMenuItem(
                  value: 'purchased',
                  child: Text('Restocked / Purchased'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete item', style: TextStyle(color: Colors.red)),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }
}
