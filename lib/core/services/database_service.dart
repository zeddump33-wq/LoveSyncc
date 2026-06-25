import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as p;
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast_web/sembast_web.dart';
import '../constants/app_constants.dart';
import '../constants/db_constants.dart';

class DatabaseService {
  // Native: sqflite database
  static sqflite.Database? _nativeDb;
  // Web: sembast database (pure Dart, IndexedDB, no WASM)
  static sembast.Database? _webDb;
  static bool _initFailed = false;
  static Future<void>? _dbInitFuture;

  /// Ensure the database is initialized (safe to call multiple times).
  static Future<void> ensureInitialized() async {
    if (_initFailed) throw StateError('Database initialization previously failed');
    if (kIsWeb && _webDb != null) return;
    if (!kIsWeb && _nativeDb != null) return;
    _dbInitFuture ??= _initDatabase().then((_) {
      _initFailed = false;
    }).catchError((e) {
      _initFailed = true;
      _dbInitFuture = null;
      throw e;
    });
    await _dbInitFuture;
  }

  static Future<void> _ensureInit() => ensureInitialized();

  static Future<void> _initDatabase() async {
    if (kIsWeb) {
      _webDb = await databaseFactoryWeb
          .openDatabase(AppConstants.dbName)
          .timeout(const Duration(seconds: 10));
    } else {
      final dbPath = await sqflite.getDatabasesPath();
      final path = p.join(dbPath, AppConstants.dbName);
      _nativeDb = await sqflite
          .openDatabase(
            path,
            version: AppConstants.dbVersion,
            onCreate: _onCreateNative,
            onUpgrade: _onUpgradeNative,
          )
          .timeout(const Duration(seconds: 10));
    }
  }

  // ─── Native: SQL tables ────────────────────────────────────────

  static Future<void> _onCreateNative(sqflite.Database db, int version) async {
    await db.execute(DbConstants.createUsersTable);
    await db.execute(DbConstants.createCouplesTable);
    await db.execute(DbConstants.createMessagesTable);
    await db.execute(DbConstants.createMemoriesTable);
    await db.execute(DbConstants.createMemoryAlbumsTable);
    await db.execute(DbConstants.createEventsTable);
    await db.execute(DbConstants.createGoalsTable);
    await db.execute(DbConstants.createGoalStepsTable);
    await db.execute(DbConstants.createWishlistTable);
    await db.execute(DbConstants.createLoveNotesTable);
    await db.execute(DbConstants.createMoodsTable);
    await db.execute(DbConstants.createCheckInsTable);
    await db.execute(DbConstants.createGamesTable);
    await db.execute(DbConstants.createMilestonesTable);
    await db.execute(DbConstants.createNotificationsTable);
  }

  static Future<void> _onUpgradeNative(sqflite.Database db, int oldVersion, int newVersion) async {}

  // ─── Web: sembast store helpers ─────────────────────────────────

  static sembast.StoreRef<String, Map<String, dynamic>> _store(String table) {
    return sembast.stringMapStoreFactory.store(table);
  }

  /// Parse simple `WHERE field = ?` for sembast filtering.
  static sembast.Filter? _parseWhere(String? where, List<dynamic>? whereArgs) {
    if (where == null || whereArgs == null || whereArgs.isEmpty) return null;
    final match = RegExp(r"(\w+)\s*=\s*\?").firstMatch(where);
    if (match != null && whereArgs.length == 1) {
      return sembast.Filter.equals(match.group(1)!, whereArgs[0]);
    }
    // Support AND conditions: `field1 = ? AND field2 = ?`
    if (where.contains(' AND ')) {
      final parts = where.split(' AND ');
      final filters = <sembast.Filter>[];
      var argIdx = 0;
      for (final part in parts) {
        final m = RegExp(r"(\w+)\s*=\s*\?").firstMatch(part);
        if (m != null && argIdx < whereArgs.length) {
          filters.add(sembast.Filter.equals(m.group(1)!, whereArgs[argIdx]));
          argIdx++;
        }
      }
      if (filters.isNotEmpty) return sembast.Filter.and(filters);
    }
    return null;
  }

  /// Parse ORDER BY for sembast sorting.
  static List<sembast.SortOrder>? _parseOrderBy(String? orderBy) {
    if (orderBy == null) return null;
    final desc = orderBy.endsWith(' DESC');
    final field = orderBy.split(' ').first;
    return [desc ? sembast.SortOrder(field, false) : sembast.SortOrder(field, true)];
  }

  // ─── Public API (works identically on web and native) ──────────

  static Future<int> insert(String table, Map<String, dynamic> data) async {
    await _ensureInit();
    if (kIsWeb) {
      final id = data['id'] as String? ?? '';
      await _store(table).record(id).put(_webDb!, Map<String, dynamic>.from(data));
      return 1;
    }
    return await _nativeDb!.insert(
      table,
      data,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  static Future<int> update(String table, Map<String, dynamic> data, String id) async {
    await _ensureInit();
    if (kIsWeb) {
      // sembast record.put() replaces the entire record, but update() is called
      // with only the changed fields. Merge with existing data first.
      final existing = await _store(table).record(id).get(_webDb!);
      final merged = Map<String, dynamic>.from(existing ?? {});
      merged.addAll(data);
      await _store(table).record(id).put(_webDb!, merged);
      return 1;
    }
    return await _nativeDb!.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> delete(String table, String id) async {
    await _ensureInit();
    if (kIsWeb) {
      await _store(table).record(id).delete(_webDb!);
      return 1;
    }
    return await _nativeDb!.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    await _ensureInit();
    if (kIsWeb) {
      final finder = sembast.Finder(
        filter: _parseWhere(where, whereArgs),
        sortOrders: _parseOrderBy(orderBy),
        limit: limit,
      );
      final records = await _store(table).find(_webDb!, finder: finder);
      return records.map((r) => r.value).toList();
    }
    return await _nativeDb!.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  static Future<Map<String, dynamic>?> getById(String table, String id) async {
    await _ensureInit();
    if (kIsWeb) {
      return await _store(table).record(id).get(_webDb!);
    }
    final results = await _nativeDb!.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  static Future<Map<String, dynamic>?> getByField(String table, String field, dynamic value) async {
    await _ensureInit();
    if (kIsWeb) {
      final records = await _store(table).find(
        _webDb!,
        finder: sembast.Finder(filter: sembast.Filter.equals(field, value)),
      );
      return records.isNotEmpty ? records.first.value : null;
    }
    final results = await _nativeDb!.query(table, where: '$field = ?', whereArgs: [value]);
    return results.isNotEmpty ? results.first : null;
  }

  static Future<int> getCount(String table, {String? where, List<dynamic>? whereArgs}) async {
    await _ensureInit();
    if (kIsWeb) {
      return await _store(table).count(
        _webDb!,
        filter: _parseWhere(where, whereArgs),
      );
    }
    final result = await _nativeDb!.rawQuery(
      'SELECT COUNT(*) as count FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return (result.first['count'] as int?) ?? 0;
  }

  static Future<double> getSum(String table, String column, {String? where, List<dynamic>? whereArgs}) async {
    await _ensureInit();
    if (kIsWeb) {
      final records = await _store(table).find(
        _webDb!,
        finder: sembast.Finder(filter: _parseWhere(where, whereArgs)),
      );
      double sum = 0;
      for (final r in records) {
        sum += (r[column] as num?)?.toDouble() ?? 0.0;
      }
      return sum;
    }
    final result = await _nativeDb!.rawQuery(
      'SELECT SUM($column) as total FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    await _ensureInit();
    if (kIsWeb) {
      // Raw SQL is not supported on web (sembast is NoSQL)
      return [];
    }
    return await _nativeDb!.rawQuery(sql, arguments);
  }

  static Future<void> close() async {
    if (kIsWeb) {
      await _webDb?.close();
      _webDb = null;
    } else {
      await _nativeDb?.close();
      _nativeDb = null;
    }
    _initFailed = false;
    _dbInitFuture = null;
  }
}
