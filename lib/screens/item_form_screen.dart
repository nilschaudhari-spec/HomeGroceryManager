import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/grocery_database.dart';
import '../models/grocery_item.dart';
import '../services/app_language_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_input_modal.dart';

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.item});
  final GroceryItem? item;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minimumController;
  late final TextEditingController _consumptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _notesController;

  String _category = 'Staples';
  String _unit = 'kg';
  bool _reminder = true;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _saving = false;

  static const List<String> _units = [
    'kg',
    'g',
    'L',
    'ml',
    'pcs',
    'pack',
    'bottle',
    'dozen',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController = TextEditingController(
      text: item == null ? '' : item.quantity.toString(),
    );
    _minimumController = TextEditingController(
      text: item == null ? '1' : item.minimumQuantity.toString(),
    );
    _consumptionController = TextEditingController(
      text: item == null ? '0' : item.dailyConsumption.toString(),
    );
    _priceController = TextEditingController(
      text: item == null ? '0' : item.pricePerUnit.toString(),
    );
    _notesController = TextEditingController(text: item?.notes ?? '');

    _category = item?.category ?? 'Staples';
    if (!CategoryMeta.all.containsKey(_category)) {
      _category = 'Other';
    }

    _unit = item?.unit ?? 'kg';
    if (!_units.contains(_unit)) {
      _unit = 'pcs';
    }

    _reminder = item?.reminderEnabled ?? true;
    _time = TimeOfDay(
      hour: item?.reminderHour ?? 9,
      minute: item?.reminderMinute ?? 0,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minimumController.dispose();
    _consumptionController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _number(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final old = widget.item;
      final item = GroceryItem(
        id: old?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        category: _category,
        quantity: _number(_quantityController),
        unit: _unit,
        minimumQuantity: _number(_minimumController),
        dailyConsumption: _number(_consumptionController),
        reminderEnabled: _reminder,
        reminderHour: _time.hour,
        reminderMinute: _time.minute,
        updatedAt: DateTime.now(),
        lastPurchasedAt: old?.lastPurchasedAt,
        pricePerUnit: _number(_priceController),
        notes: _notesController.text.trim(),
        onShoppingList: old?.onShoppingList ?? false,
      );

      if (old == null) {
        await GroceryDatabase.instance.save(item);
      } else {
        await GroceryDatabase.instance.update(item);
      }

      await NotificationService.instance.schedule(item);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            old == null
                ? AppLanguageService.t('added_to_pantry', params: {'name': item.name})
                : AppLanguageService.t('saved_updates', params: {'name': item.name}),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final qty = _number(_quantityController);
    final consumption = _number(_consumptionController);
    final daysLeft = consumption > 0 ? (qty / consumption) : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? AppLanguageService.t('edit_grocery') : AppLanguageService.t('add_grocery'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _saving
                  ? 'Saving...'
                  : (isEdit ? AppLanguageService.t('save_changes') : AppLanguageService.t('add_to_inventory')),
            ),
            onPressed: _saving ? null : _save,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Section 1: Item & Category
            _formCard(
              title: AppLanguageService.t('grocery_name'),
              icon: Icons.inventory_2_outlined,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: AppLanguageService.t('grocery_name'),
                    hintText: AppLanguageService.t('grocery_name_hint'),
                    prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20),
                    suffixIcon: IconButton(
                      tooltip: AppLanguageService.t('voice_input'),
                      icon: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 22),
                      onPressed: () async {
                        final result = await VoiceInputModal.show(
                          context,
                          initialText: _nameController.text,
                          title: AppLanguageService.t('voice_input'),
                          hint: AppLanguageService.t('speech_listening_hint'),
                        );
                        if (result != null && mounted) {
                          setState(() {
                            _nameController.text = result;
                          });
                        }
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  AppLanguageService.t('category'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryMeta.all.keys.map((cat) {
                    final isSelected = _category == cat;
                    final meta = CategoryMeta.get(cat);
                    final catLabel = AppLanguageService.t('cat_$cat');
                    return ChoiceChip(
                      showCheckmark: false,
                      avatar: Text(meta.emoji),
                      label: Text(catLabel),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                      onSelected: (_) => setState(() => _category = cat),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Section 2: Quantity & Unit
            _formCard(
              title: AppLanguageService.t('current_quantity'),
              icon: Icons.scale_outlined,
              children: [
                Text(
                  AppLanguageService.t('unit'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _units.map((u) {
                    final isSelected = _unit == u;
                    return ChoiceChip(
                      showCheckmark: false,
                      label: Text(u),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                      onSelected: (_) => setState(() => _unit = u),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: AppLanguageService.t('current_quantity'),
                          suffixText: _unit,
                          prefixIcon: const Icon(Icons.kitchen_outlined, size: 20),
                        ),
                        validator: (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          if (n == null || n < 0) return 'Invalid number';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minimumController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: AppLanguageService.t('min_quantity'),
                          suffixText: _unit,
                          prefixIcon: const Icon(Icons.warning_amber_rounded, size: 20),
                        ),
                        validator: (v) {
                          final n = double.tryParse(v?.trim() ?? '');
                          if (n == null || n < 0) return 'Invalid number';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Section 3: Smart Consumption & Runout
            _formCard(
              title: AppLanguageService.t('daily_consumption'),
              icon: Icons.timelapse_rounded,
              children: [
                TextFormField(
                  controller: _consumptionController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${AppLanguageService.t('daily_consumption')} ($_unit / day)',
                    hintText: 'e.g. 0.5',
                    prefixIcon: const Icon(Icons.trending_down_rounded, size: 20),
                    helperText: AppLanguageService.t('consumption_hint'),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (consumption > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: daysLeft <= 3 ? AppColors.warningBg : AppColors.mintLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          daysLeft <= 3 ? Icons.warning_amber_rounded : Icons.info_outline,
                          size: 20,
                          color: daysLeft <= 3 ? const Color(0xFFB45309) : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            daysLeft.isFinite
                                ? AppLanguageService.t('days_left', params: {'days': daysLeft.toStringAsFixed(1)})
                                : AppLanguageService.t('rate_not_set'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: daysLeft <= 3 ? const Color(0xFFB45309) : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Section 4: Pricing & Notes
            _formCard(
              title: AppLanguageService.t('price_per_unit'),
              icon: Icons.notes_rounded,
              children: [
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLanguageService.t('price_per_unit'),
                    prefixText: '₹ ',
                    suffixText: '/ $_unit',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: AppLanguageService.t('notes'),
                    hintText: 'e.g. Second shelf, Brand: Fortune',
                    prefixIcon: const Icon(Icons.edit_note_rounded, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Section 5: Daily Reminder Time
            _formCard(
              title: AppLanguageService.t('reminder_title'),
              icon: Icons.notifications_active_outlined,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppLanguageService.t('reminder_title'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    _reminder
                        ? '${AppLanguageService.t('reminder_subtitle')} (${_time.format(context)})'
                        : 'Notifications disabled for this item',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: _reminder,
                  activeTrackColor: AppColors.accentMint,
                  onChanged: (v) => setState(() => _reminder = v),
                ),
                if (_reminder) ...[
                  const Divider(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _pickTime,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('${AppLanguageService.t('reminder_time')}:', style: const TextStyle(fontSize: 13)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.mintLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _time.format(context),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _formCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
