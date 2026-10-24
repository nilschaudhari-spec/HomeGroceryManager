import 'package:flutter_test/flutter_test.dart';
import 'package:home_grocery_manager/models/grocery_item.dart';

GroceryItem item({double quantity=2,double min=1,double daily=.5})=>GroceryItem(id:'rice',name:'Rice',category:'Staples',quantity:quantity,unit:'kg',minimumQuantity:min,dailyConsumption:daily,reminderEnabled:true,reminderHour:9,reminderMinute:0,updatedAt:DateTime(2026,1,1));
void main(){
 test('predicts days remaining from quantity and consumption',(){expect(item(quantity:2,daily:.5).daysRemaining,4);});
 test('flags quantity at or below minimum as low stock',(){expect(item(quantity:1,min:1).isLowStock,isTrue);expect(item(quantity:2,min:1,daily:0).isLowStock,isFalse);});
 test('flags predicted runout within three days',(){expect(item(quantity:1.5,min:1,daily:.5).isLowStock,isTrue);});
 test('does not divide by zero for consumption estimate',(){expect(item(daily:0).daysRemaining.isInfinite,isTrue);expect(item(daily:0).predictedRunout,isNull);});
 test('serializes to and from map',(){final original=item();final restored=GroceryItem.fromMap(original.toMap());expect(restored.name,original.name);expect(restored.quantity,original.quantity);expect(restored.reminderEnabled,isTrue);});
}
