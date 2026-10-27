import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../data/grocery_database.dart';
import '../models/grocery_item.dart';
import '../services/ads_service.dart';
import '../services/app_language_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/voice_input_modal.dart';
import 'item_form_screen.dart';

enum GrocerySortOption {
  runoutSoonest(Icons.timer_outlined, 'due_soonest'),
  lowestStock(Icons.trending_down_rounded, 'lowest_stock'),
  nameAsc(Icons.sort_by_alpha_rounded, 'name_az'),
  category(Icons.category_outlined, 'category');

  final IconData icon;
  final String keyName;
  const GrocerySortOption(this.icon, this.keyName);

  String get label => AppLanguageService.t(keyName);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GroceryItem> _allItems = [];
  String _search = '';
  String _selectedCategory = 'All';
  bool _shoppingOnly = false;
  GrocerySortOption _sortOption = GrocerySortOption.runoutSoonest;

  BannerAd? _banner;
  bool _bannerLoaded = false;
  int _restockCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    if (!kIsWeb && !const bool.fromEnvironment('FLUTTER_TEST')) {
      _initBanner();
    }
  }

  void _initBanner() {
    if (!AdsService.instance.ready) return;
    try {
      _banner = AdsService.instance.createBanner(
        onLoaded: () {
          if (mounted) setState(() => _bannerLoaded = true);
        },
        onFailed: (error) {
          debugPrint('[HomeScreen] Banner ad failed: $error');
          if (mounted) setState(() => _bannerLoaded = false);
        },
      )..load();
    } catch (e) {
      debugPrint('[HomeScreen] Banner creation error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _banner?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rows = await GroceryDatabase.instance.all();
      if (!mounted) return;
      setState(() => _allItems = rows);
    } catch (e) {
      debugPrint('[HomeScreen] Database load error: $e');
    }
  }

  List<GroceryItem> get _filteredAndSortedItems {
    var list = _allItems;

    // Shopping list filter
    if (_shoppingOnly) {
      list = list.where((e) => e.onShoppingList).toList();
    }

    // Category filter
    if (_selectedCategory != 'All') {
      list = list.where((e) => e.category == _selectedCategory).toList();
    }

    // Search query
    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((e) {
        return e.name.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query) ||
            e.notes.toLowerCase().contains(query);
      }).toList();
    }

    // Sorting
    list = List.of(list);
    switch (_sortOption) {
      case GrocerySortOption.runoutSoonest:
        list.sort((a, b) {
          // Put zero-stock first
          if (a.quantity <= 0 && b.quantity > 0) return -1;
          if (b.quantity <= 0 && a.quantity > 0) return 1;
          // Then by daysRemaining
          return a.daysRemaining.compareTo(b.daysRemaining);
        });
        break;
      case GrocerySortOption.lowestStock:
        list.sort((a, b) {
          final ratioA = a.minimumQuantity <= 0 ? 1.0 : a.quantity / a.minimumQuantity;
          final ratioB = b.minimumQuantity <= 0 ? 1.0 : b.quantity / b.minimumQuantity;
          return ratioA.compareTo(ratioB);
        });
        break;
      case GrocerySortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case GrocerySortOption.category:
        list.sort((a, b) {
          final catComp = a.category.compareTo(b.category);
          return catComp != 0 ? catComp : a.name.compareTo(b.name);
        });
        break;
    }

    return list;
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

  Future<void> _restockModal(GroceryItem item) async {
    final controller = TextEditingController(
      text: item.estimatedReorderQuantity > 0
          ? item.estimatedReorderQuantity.toString()
          : item.minimumQuantity.toString(),
    );

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CategoryMeta.get(item.category).bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        CategoryMeta.get(item.category).emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLanguageService.t('quick_restock_title', params: {'name': item.name}),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${AppLanguageService.t('current_quantity')}: ${item.quantity} ${item.unit} • ${AppLanguageService.t('min', params: {'qty': '${item.minimumQuantity} ${item.unit}'})}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  AppLanguageService.t('add_stock_qty'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 5, 10].map((addAmount) {
                    return ActionChip(
                      label: Text('+$addAmount ${item.unit}'),
                      onPressed: () {
                        final updatedAmount = (item.quantity + addAmount);
                        controller.text = updatedAmount.toString();
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${AppLanguageService.t('current_quantity')} (${item.unit})',
                    helperText: AppLanguageService.t('low_stock_alert', params: {'qty': item.estimatedReorderQuantity.toString(), 'unit': item.unit}),
                    suffixText: item.unit,
                  ),
                  onChanged: (_) => setModalState(() {}),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('${AppLanguageService.t('restock')} (${controller.text.isEmpty ? '0' : controller.text} ${item.unit})'),
                    onPressed: () {
                      final parsed = double.tryParse(controller.text.trim());
                      Navigator.pop(ctx, parsed);
                    },
                  ),
                ),
              ],
            ),
          );
        },
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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguageService.t('updated_stock_msg', params: {
              'name': item.name,
              'qty': amount.toString(),
              'unit': item.unit,
            }),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteItem(GroceryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLanguageService.t('delete_item_confirm', params: {'name': item.name})),
        content: Text(AppLanguageService.t('delete_item_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLanguageService.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLanguageService.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GroceryDatabase.instance.delete(item.id);
      await NotificationService.instance.cancel(item.id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLanguageService.t('deleted_msg', params: {'name': item.name})),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAboutAndPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 36,
                height: 36,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'About & Privacy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Home Grocery Manager v1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              SizedBox(height: 8),
              Text(
                '• 100% Offline-First: All grocery items, stock counts, and history stay safely on your device in a local SQLite database.',
              ),
              SizedBox(height: 6),
              Text(
                '• Privacy Guaranteed: No account or cloud sync needed. Your household consumption habits never leave your device.',
              ),
              SizedBox(height: 6),
              Text(
                '• Smart Reorder Engine: Calculates runout estimates automatically based on your daily consumption rate.',
              ),
              SizedBox(height: 6),
              Text(
                '• Local Notifications: Configurable reminder alerts scheduled locally by your operating system.',
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
    final lowStockCount = _allItems.where((e) => e.isLowStock).length;
    final dueSoonCount = _allItems
        .where((e) => e.dailyConsumption > 0 && e.daysRemaining <= 7)
        .length;
    final shoppingCount = _allItems.where((e) => e.onShoppingList).length;
    final displayedItems = _filteredAndSortedItems;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(
          AppLanguageService.t('add_grocery'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: _bannerLoaded && _banner != null
          ? SafeArea(
              top: false,
              child: Container(
                height: _banner!.size.height.toDouble() + 8,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                alignment: Alignment.center,
                child: SizedBox(
                  width: _banner!.size.width.toDouble(),
                  height: _banner!.size.height.toDouble(),
                  child: AdWidget(key: Key(_banner.hashCode.toString()), ad: _banner!),
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // Modern Header Sliver
          SliverToBoxAdapter(
            child: _buildHeroHeader(
              lowStockCount: lowStockCount,
              dueSoonCount: dueSoonCount,
              shoppingCount: shoppingCount,
            ),
          ),

          // Search & Filter Controls
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildTabToggle(shoppingCount: shoppingCount),
                  const SizedBox(height: 12),
                  _buildCategoryChips(),
                ],
              ),
            ),
          ),

          // Items List or Empty State
          if (displayedItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildGroceryCard(displayedItems[index]),
                  childCount: displayedItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader({
    required int lowStockCount,
    required int dueSoonCount,
    required int shoppingCount,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.kitchen_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLanguageService.t('app_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppLanguageService.instance.currentLanguage.nativeName,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: AppLanguageService.t('change_language'),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.translate_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                    onPressed: () => LanguagePickerSheet.show(context),
                  ),
                  IconButton(
                    tooltip: 'Notification reminders',
                    icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                    onPressed: () async {
                      await NotificationService.instance.requestPermissions();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification permissions checked.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: AppLanguageService.t('about_title'),
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: _showAboutAndPrivacyDialog,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Stat Cards
              Row(
                children: [
                  _headerStatTile(
                    AppLanguageService.t('in_stock'),
                    '${_allItems.length}',
                    Icons.inventory_2_outlined,
                  ),
                  const SizedBox(width: 8),
                  _headerStatTile(
                    AppLanguageService.t('low_stock'),
                    '$lowStockCount',
                    Icons.warning_amber_rounded,
                    isAlert: lowStockCount > 0,
                  ),
                  const SizedBox(width: 8),
                  _headerStatTile(
                    AppLanguageService.t('due_soon'),
                    '$dueSoonCount',
                    Icons.timelapse_rounded,
                  ),
                  const SizedBox(width: 8),
                  _headerStatTile(
                    AppLanguageService.t('shopping_list'),
                    '$shoppingCount',
                    Icons.shopping_bag_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerStatTile(
    String label,
    String value,
    IconData icon, {
    bool isAlert = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isAlert
              ? const Color(0xFFF59E0B).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAlert
                ? Colors.amber.shade200
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 16,
              color: isAlert ? const Color(0xFF78350F) : Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isAlert ? const Color(0xFF78350F) : Colors.white,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isAlert ? const Color(0xFF78350F) : const Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLanguageService.t('search_placeholder'),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_search.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    ),
                  IconButton(
                    tooltip: AppLanguageService.t('voice_search'),
                    icon: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 22),
                    onPressed: () async {
                      final result = await VoiceInputModal.show(
                        context,
                        initialText: _search,
                        title: AppLanguageService.t('voice_search'),
                        hint: AppLanguageService.t('speech_listening_hint'),
                      );
                      if (result != null && mounted) {
                        _searchController.text = result;
                        setState(() => _search = result);
                      }
                    },
                  ),
                ],
              ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<GrocerySortOption>(
          tooltip: 'Sort groceries',
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
          ),
          onSelected: (opt) => setState(() => _sortOption = opt),
          itemBuilder: (context) => GrocerySortOption.values.map((opt) {
            final isSelected = _sortOption == opt;
            return PopupMenuItem(
              value: opt,
              child: Row(
                children: [
                  Icon(
                    opt.icon,
                    size: 18,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTabToggle({required int shoppingCount}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _shoppingOnly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !_shoppingOnly ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_shoppingOnly
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: !_shoppingOnly ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLanguageService.t('all'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: !_shoppingOnly ? FontWeight.bold : FontWeight.w500,
                        color: !_shoppingOnly ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _shoppingOnly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _shoppingOnly ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _shoppingOnly
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 16,
                      color: _shoppingOnly ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${AppLanguageService.t('shopping_list')} ($shoppingCount)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _shoppingOnly ? FontWeight.bold : FontWeight.w500,
                        color: _shoppingOnly ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', ...CategoryMeta.all.keys];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          final meta = cat == 'All' ? null : CategoryMeta.get(cat);

          final count = cat == 'All'
              ? _allItems.length
              : _allItems.where((e) => e.category == cat).length;

          final labelText = cat == 'All'
              ? AppLanguageService.t('all')
              : AppLanguageService.t('cat_$cat');

          return ChoiceChip(
            showCheckmark: false,
            avatar: cat == 'All'
                ? const Icon(Icons.all_inclusive_rounded, size: 16)
                : Text(meta!.emoji, style: const TextStyle(fontSize: 14)),
            label: Text(
              '$labelText ($count)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (_) => setState(() => _selectedCategory = cat),
          );
        },
      ),
    );
  }

  Widget _buildGroceryCard(GroceryItem item) {
    final meta = CategoryMeta.get(item.category);
    final ratio = item.minimumQuantity <= 0
        ? (item.quantity > 0 ? 1.0 : 0.0)
        : (item.quantity / item.minimumQuantity).clamp(0.0, 2.0) / 2.0;

    final progressColor = item.quantity <= 0
        ? AppColors.danger
        : (item.isLowStock ? AppColors.warning : AppColors.accentMint);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _edit(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Emoji avatar, title, category, more menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: meta.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(meta.emoji, style: const TextStyle(fontSize: 22)),
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (item.pricePerUnit > 0)
                              Text(
                                '₹${item.pricePerUnit.toStringAsFixed(item.pricePerUnit.truncateToDouble() == item.pricePerUnit ? 0 : 2)}/${item.unit}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: meta.bgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: meta.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (item.reminderEnabled)
                              const Icon(
                                Icons.alarm_on_rounded,
                                size: 14,
                                color: AppColors.accentMint,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    onSelected: (val) async {
                      if (val == 'edit') {
                        await _edit(item);
                      } else if (val == 'restock') {
                        await _restockModal(item);
                      } else if (val == 'shopping') {
                        await _toggleShopping(item, !item.onShoppingList);
                      } else if (val == 'delete') {
                        await _deleteItem(item);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'restock',
                        child: Row(
                          children: [
                            const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(AppLanguageService.t('restock')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'shopping',
                        child: Row(
                          children: [
                            Icon(
                              item.onShoppingList
                                  ? Icons.remove_shopping_cart_outlined
                                  : Icons.add_shopping_cart_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(item.onShoppingList ? AppLanguageService.t('remove_from_list') : AppLanguageService.t('to_shopping_list')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(AppLanguageService.t('edit_grocery')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                            const SizedBox(width: 8),
                            Text(AppLanguageService.t('delete'), style: const TextStyle(color: AppColors.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Visual Stock Health Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 10),

              // Stock Status & Details Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '${item.quantity} ${item.unit} ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: '(${AppLanguageService.t('min', params: {'qty': '${item.minimumQuantity} ${item.unit}'})})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.dailyConsumption > 0 && item.daysRemaining.isFinite)
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          AppLanguageService.t('days_left', params: {'days': item.daysRemaining.toStringAsFixed(1)}),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.daysRemaining <= 3
                                ? AppColors.danger
                                : (item.daysRemaining <= 7 ? AppColors.warning : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      AppLanguageService.t('rate_not_set'),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                ],
              ),

              // Low Stock Pill Alert
              if (item.isLowStock) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warningBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.quantity <= 0
                              ? AppLanguageService.t('out_of_stock', params: {'qty': item.estimatedReorderQuantity.toString(), 'unit': item.unit})
                              : AppLanguageService.t('low_stock_alert', params: {'qty': item.estimatedReorderQuantity.toString(), 'unit': item.unit}),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Bottom Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: Icon(
                      item.onShoppingList ? Icons.shopping_cart : Icons.add_shopping_cart_outlined,
                      size: 16,
                      color: item.onShoppingList ? AppColors.primary : Colors.grey.shade700,
                    ),
                    label: Text(
                      item.onShoppingList ? AppLanguageService.t('in_shopping_list') : AppLanguageService.t('to_shopping_list'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item.onShoppingList ? AppColors.primary : Colors.grey.shade800,
                      ),
                    ),
                    onPressed: () => _toggleShopping(item, !item.onShoppingList),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mintLight,
                      foregroundColor: AppColors.mintDark,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      AppLanguageService.t('restock'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _restockModal(item),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.mintLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _shoppingOnly
                    ? Icons.shopping_cart_outlined
                    : Icons.kitchen_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _shoppingOnly ? AppLanguageService.t('shopping_empty_title') : AppLanguageService.t('pantry_empty_title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _shoppingOnly
                  ? AppLanguageService.t('shopping_empty_desc')
                  : AppLanguageService.t('pantry_empty_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(AppLanguageService.t('add_first_grocery')),
              onPressed: _add,
            ),
          ],
        ),
      ),
    );
  }
}
