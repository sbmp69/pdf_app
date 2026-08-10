import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scanpro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';

    await db.execute('''
CREATE TABLE documents (
  id $idType,
  name $textType,
  path $textType,
  mimeType $textType,
  createdAt $textType,
  modifiedAt $textType,
  size $integerType,
  pageCount $integerType,
  folderId $textType,
  isFavorite $boolType,
  isPinned $boolType,
  documentType $textType
)
''');

    await db.execute('''
CREATE TABLE pages (
  id $idType,
  documentId $textType,
  imagePath $textType,
  pageNumber $integerType
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
