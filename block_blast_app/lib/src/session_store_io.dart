import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'session_store.dart';

class SqliteSessionStore implements SessionStore {
  static const _key = 'active_session';

  @override
  Future<String?> loadSessionJson() async {
    final database = await _open();
    try {
      final rows = database.select(
        'SELECT value FROM kv_store WHERE key = ? LIMIT 1',
        <Object?>[_key],
      );
      return rows.isEmpty ? null : rows.first['value'] as String?;
    } finally {
      database.close();
    }
  }

  @override
  Future<void> saveSessionJson(String json) async {
    final database = await _open();
    try {
      database.execute(
        '''
        INSERT INTO kv_store (key, value)
        VALUES (?, ?)
        ON CONFLICT(key) DO UPDATE SET value = excluded.value
        ''',
        <Object?>[_key, json],
      );
    } finally {
      database.close();
    }
  }

  Future<sqlite.Database> _open() async {
    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, 'aether_block_blast.sqlite');
    final database = sqlite.sqlite3.open(path);
    database.execute('''
      CREATE TABLE IF NOT EXISTS kv_store (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
      ''');
    return database;
  }
}

SessionStore createSessionStore() => SqliteSessionStore();
