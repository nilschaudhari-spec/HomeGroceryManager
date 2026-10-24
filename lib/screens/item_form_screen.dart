import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/grocery_database.dart';
import '../models/grocery_item.dart';
import '../services/notification_service.dart';

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

  static const List<String> _categories = [
    'Staples',
    'Dairy',
    'Vegetables',
    'Fruits',
    'Pulses',
    'Spices',
    'Snacks',
    'Beverages',
    'Cleaning',
    'Personal care',
    'Other',
  ];

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
    if (!_categories.contains(_category)) {
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

      await GroceryDatabase.instance.save(item);
      await NotificationService.instance.schedule(item);
      if (item.isLowStock && item.onShoppingList) {
        await NotificationService.instance.lowStock(item);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving grocery: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Grocery' : 'Edit Grocery'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Grocery name',
                hintText: 'e.g. Rice, Milk, Apples',
                prefixIcon: Icon(Icons.shopping_basket_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a grocery name' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _decimalField(
                    _quantityController,
                    'Current quantity',
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: _units
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _unit = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _decimalField(_minimumController, 'Minimum stock level'),
            const SizedBox(height: 16),
            _decimalField(
              _consumptionController,
              'Daily consumption (same unit)',
              hint: '0 = no estimation',
            ),
            const SizedBox(height: 6),
            Text(
              'Example: if you consume 0.2 kg daily, enter 0.2 when unit is kg.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            _decimalField(_priceController, 'Price per unit (optional)'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Brand preferences, storage instructions...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const Divider(height: 36),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily reorder reminder'),
              subtitle: const Text('Sends a local alert at your chosen time'),
              value: _reminder,
              onChanged: (v) => setState(() => _reminder = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reminder time'),
              subtitle: Text(_time.format(context)),
              trailing: const Icon(Icons.schedule),
              onTap: () async {
                final selected = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (selected != null) {
                  setState(() => _time = selected);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save Grocery'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decimalField(
    TextEditingController controller,
    String label, {
    bool required = false,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return 'Required';
        }
        final trimmed = (v ?? '').trim();
        if (trimmed.isNotEmpty) {
          final n = double.tryParse(trimmed);
          if (n == null || n < 0 || !n.isFinite) {
            return 'Enter a valid non-negative number';
          }
        }
        return null;
      },
    );
  }
}
