import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/grocery_item.dart';

class GroceryDatabase {
  GroceryDatabase._();
  static final GroceryDatabase instance = GroceryDatabase._();
  Database? _db;
  Future<Database> get database async => _db ??= await _open();
  Future<Database> _open() async => openDatabase(p.join(await getDatabasesPath(),'home_grocery_manager.db'),version:1,onCreate:(db,_) async {
    await db.execute("CREATE TABLE groceries (id TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, quantity REAL NOT NULL, unit TEXT NOT NULL, minimum_quantity REAL NOT NULL, daily_consumption REAL NOT NULL, reminder_enabled INTEGER NOT NULL, reminder_hour INTEGER NOT NULL, reminder_minute INTEGER NOT NULL, updated_at TEXT NOT NULL, last_purchased_at TEXT, price_per_unit REAL NOT NULL DEFAULT 0, notes TEXT NOT NULL DEFAULT '', on_shopping_list INTEGER NOT NULL DEFAULT 0)");
    await db.execute('CREATE INDEX idx_groceries_name ON groceries(name COLLATE NOCASE)');
  });
  Future<List<GroceryItem>> all({String search=''}) async { final db=await database; final rows=await db.query('groceries',where:search.trim().isEmpty?null:'name LIKE ? OR category LIKE ?',whereArgs:search.trim().isEmpty?null:['%${search.trim()}%','%${search.trim()}%'],orderBy:'name COLLATE NOCASE'); return rows.map(GroceryItem.fromMap).toList(); }
  Future<void> save(GroceryItem item) async => (await database).insert('groceries',item.toMap(),conflictAlgorithm:ConflictAlgorithm.replace);
  Future<void> delete(String id) async => (await database).delete('groceries',where:'id = ?',whereArgs:[id]);
  Future<void> update(GroceryItem item) async => (await database).update('groceries',item.toMap(),where:'id = ?',whereArgs:[item.id]);
  Future<void> close() async { await _db?.close(); _db=null; }
}
