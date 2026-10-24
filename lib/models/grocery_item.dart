class GroceryItem {
  const GroceryItem({required this.id, required this.name, required this.category, required this.quantity, required this.unit, required this.minimumQuantity, required this.dailyConsumption, required this.reminderEnabled, required this.reminderHour, required this.reminderMinute, required this.updatedAt, this.lastPurchasedAt, this.pricePerUnit = 0, this.notes = '', this.onShoppingList = false});
  final String id, name, category, unit, notes;
  final double quantity, minimumQuantity, dailyConsumption, pricePerUnit;
  final bool reminderEnabled, onShoppingList;
  final int reminderHour, reminderMinute;
  final DateTime updatedAt;
  final DateTime? lastPurchasedAt;

  double get daysRemaining => dailyConsumption <= 0 ? double.infinity : quantity / dailyConsumption;
  bool get isLowStock => quantity <= minimumQuantity || (dailyConsumption > 0 && daysRemaining <= 3);
  DateTime? get predictedRunout => dailyConsumption <= 0 ? null : DateTime.now().add(Duration(minutes: (daysRemaining * 1440).ceil()));
  double get estimatedReorderQuantity => (minimumQuantity * 2 - quantity).clamp(0, double.infinity).toDouble();

  Map<String, Object?> toMap() => {'id':id,'name':name,'category':category,'quantity':quantity,'unit':unit,'minimum_quantity':minimumQuantity,'daily_consumption':dailyConsumption,'reminder_enabled':reminderEnabled?1:0,'reminder_hour':reminderHour,'reminder_minute':reminderMinute,'updated_at':updatedAt.toIso8601String(),'last_purchased_at':lastPurchasedAt?.toIso8601String(),'price_per_unit':pricePerUnit,'notes':notes,'on_shopping_list':onShoppingList?1:0};
  factory GroceryItem.fromMap(Map<String,Object?> m) => GroceryItem(id:m['id'] as String,name:m['name'] as String,category:m['category'] as String,quantity:(m['quantity'] as num).toDouble(),unit:m['unit'] as String,minimumQuantity:(m['minimum_quantity'] as num).toDouble(),dailyConsumption:(m['daily_consumption'] as num).toDouble(),reminderEnabled:(m['reminder_enabled'] as int)==1,reminderHour:m['reminder_hour'] as int,reminderMinute:m['reminder_minute'] as int,updatedAt:DateTime.parse(m['updated_at'] as String),lastPurchasedAt:m['last_purchased_at']==null?null:DateTime.parse(m['last_purchased_at'] as String),pricePerUnit:(m['price_per_unit'] as num).toDouble(),notes:(m['notes'] as String?)??'',onShoppingList:(m['on_shopping_list'] as int)==1);
  GroceryItem copyWith({String? name,String? category,double? quantity,String? unit,double? minimumQuantity,double? dailyConsumption,bool? reminderEnabled,int? reminderHour,int? reminderMinute,double? pricePerUnit,String? notes,bool? onShoppingList,DateTime? lastPurchasedAt}) => GroceryItem(id:id,name:name??this.name,category:category??this.category,quantity:quantity??this.quantity,unit:unit??this.unit,minimumQuantity:minimumQuantity??this.minimumQuantity,dailyConsumption:dailyConsumption??this.dailyConsumption,reminderEnabled:reminderEnabled??this.reminderEnabled,reminderHour:reminderHour??this.reminderHour,reminderMinute:reminderMinute??this.reminderMinute,updatedAt:DateTime.now(),lastPurchasedAt:lastPurchasedAt??this.lastPurchasedAt,pricePerUnit:pricePerUnit??this.pricePerUnit,notes:notes??this.notes,onShoppingList:onShoppingList??this.onShoppingList);
}
