import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

/// Base de datos embebida (usuarios) en el dispositivo; misma información que
/// `users` en el Flask antiguo, sin servidor.
class AuthDatabase {
  AuthDatabase._();

  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    if (kIsWeb) {
      return databaseFactoryWeb.openDatabase('alworki_auth.db');
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'alworki_auth.db');
    return databaseFactoryIo.openDatabase(path);
  }
}
