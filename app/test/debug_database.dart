import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Quick debug script to dump all table contents from the Inboxie database.
/// Run with: flutter run test/debug_database.dart
/// Or call DatabaseDebugger.dumpAll() from anywhere in the app.
class DatabaseDebugger {
  static Future<void> dumpAll() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inboxie.db');
    final db = await openDatabase(path);

    print('\n');
    print('╔══════════════════════════════════════════════════╗');
    print('║          INBOXIE DATABASE DUMP                  ║');
    print('╚══════════════════════════════════════════════════╝');

    // List all tables
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'"
    );
    print('\n📋 Tables found: ${tables.map((t) => t['name']).join(', ')}\n');

    for (var table in tables) {
      final tableName = table['name'] as String;
      final rows = await db.query(tableName);
      final count = rows.length;

      print('┌──────────────────────────────────────────');
      print('│ 📁 $tableName ($count rows)');
      print('├──────────────────────────────────────────');

      if (rows.isEmpty) {
        print('│  (empty)');
      } else {
        // Print column headers
        print('│  Columns: ${rows.first.keys.join(', ')}');
        print('│');

        // Print each row (limit to 5 for readability)
        final displayRows = rows.take(5);
        for (var row in displayRows) {
          for (var entry in row.entries) {
            String value = '${entry.value}';
            if (value.length > 80) value = '${value.substring(0, 80)}...';
            print('│    ${entry.key}: $value');
          }
          print('│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─');
        }

        if (count > 5) {
          print('│  ... and ${count - 5} more rows');
        }
      }
      print('└──────────────────────────────────────────\n');
    }

    await db.close();
  }
}

// Standalone entry point
void main() async {
  await DatabaseDebugger.dumpAll();
}
