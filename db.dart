
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'maharaja.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE vehicles('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'customer_name TEXT,'
          'mobile TEXT,'
          'vehicle_number TEXT,'
          'insurance_expiry INTEGER,'
          'fitness_expiry INTEGER,'
          'puc_expiry INTEGER'
          ')',
        );
      },
    );
  }

  Future<int> insertVehicle(Vehicle v) async =>
      await _db!.insert('vehicles', v.toMap());

  Future<int> updateVehicle(Vehicle v) async =>
      await _db!.update('vehicles', v.toMap(), where: 'id = ?', whereArgs: [v.id]);

  Future<void> deleteVehicle(int id) async =>
      await _db!.delete('vehicles', where: 'id = ?', whereArgs: [id]);

  Future<List<Vehicle>> getVehicles() async {
    final rows = await _db!.query('vehicles', orderBy: 'id DESC');
    return rows.map((e) => Vehicle.fromMap(e)).toList();
  }

  Future<List<Vehicle>> getExpiringOn(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;
    final rows = await _db!.rawQuery(
      'SELECT * FROM vehicles '
      'WHERE (insurance_expiry BETWEEN ? AND ?) '
      'OR (fitness_expiry BETWEEN ? AND ?) '
      'OR (puc_expiry BETWEEN ? AND ?)',
      [start, end, start, end, start, end],
    );
    return rows.map((e) => Vehicle.fromMap(e)).toList();
  }
}
