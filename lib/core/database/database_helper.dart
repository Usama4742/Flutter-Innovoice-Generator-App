import 'package:innvoice_generator/models/invoice_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return instance;
  }

  Database? _database;

  // ============================================================
  // DATABASE
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // ============================================================
  // INITIALIZE DATABASE
  // ============================================================

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, 'invoice_generator.db');

    return await openDatabase(
      path,

      // VERSION 2
      version: 2,

      onCreate: _createDatabase,

      onUpgrade: _upgradeDatabase,
    );
  }

  // ============================================================
  // CREATE DATABASE
  // ============================================================

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        invoice_number TEXT UNIQUE NOT NULL,

        vendor_company_name TEXT,
        vendor_name TEXT,
        vendor_email TEXT,
        vendor_phone TEXT,
        vendor_address TEXT,

        customer_name TEXT NOT NULL,
        customer_email TEXT,
        customer_phone TEXT,

        invoice_date TEXT NOT NULL,

        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        discount REAL NOT NULL,
        total REAL NOT NULL,

        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        invoice_id INTEGER NOT NULL,

        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        total REAL NOT NULL,

        FOREIGN KEY (invoice_id)
          REFERENCES invoices(id)
          ON DELETE CASCADE
      )
    ''');
  }

  // ============================================================
  // DATABASE MIGRATION
  // ============================================================

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE invoices
        ADD COLUMN vendor_company_name TEXT
      ''');

      await db.execute('''
        ALTER TABLE invoices
        ADD COLUMN vendor_name TEXT
      ''');

      await db.execute('''
        ALTER TABLE invoices
        ADD COLUMN vendor_email TEXT
      ''');

      await db.execute('''
        ALTER TABLE invoices
        ADD COLUMN vendor_phone TEXT
      ''');

      await db.execute('''
        ALTER TABLE invoices
        ADD COLUMN vendor_address TEXT
      ''');
    }
  }

  // ============================================================
  // GET NEXT INVOICE NUMBER
  // ============================================================

  Future<String> getNextInvoiceNumber() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT MAX(
        CAST(
          SUBSTR(invoice_number, 5)
          AS INTEGER
        )
      ) AS max_number

      FROM invoices

      WHERE invoice_number LIKE 'INV-%'
    ''');

    final maxNumber = (result.first['max_number'] as num?)?.toInt() ?? 0;

    final nextNumber = maxNumber + 1;

    return 'INV-${nextNumber.toString().padLeft(3, '0')}';
  }

  // ============================================================
  // INSERT INVOICE
  // ============================================================

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;

    return await db.transaction<int>((transaction) async {
      final invoiceData = invoice.toMap();

      // Don't insert the ID when creating a new invoice.
      invoiceData.remove('id');

      final invoiceId = await transaction.insert(
        'invoices',
        invoiceData,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      for (final item in invoice.items) {
        final itemData = item.toMap();

        itemData.remove('id');

        itemData['invoice_id'] = invoiceId;

        await transaction.insert('invoice_items', itemData);
      }

      return invoiceId;
    });
  }

  // ============================================================
  // GET ALL INVOICES
  // ============================================================

  Future<List<Invoice>> getInvoices() async {
    final db = await database;

    final invoiceMaps = await db.query('invoices', orderBy: 'id DESC');

    final List<Invoice> invoices = [];

    for (final invoiceMap in invoiceMaps) {
      final id = invoiceMap['id'] as int;

      final items = await _getItems(db, id);

      invoices.add(Invoice.fromMap(invoiceMap, items: items));
    }

    return invoices;
  }

  // ============================================================
  // GET SINGLE INVOICE
  // ============================================================

  Future<Invoice?> getInvoiceById(int id) async {
    final db = await database;

    final result = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final items = await _getItems(db, id);

    return Invoice.fromMap(result.first, items: items);
  }

  // ============================================================
  // GET BY INVOICE NUMBER
  // ============================================================

  Future<Invoice?> getInvoiceByNumber(String invoiceNumber) async {
    final db = await database;

    final result = await db.query(
      'invoices',
      where: 'invoice_number = ?',
      whereArgs: [invoiceNumber],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final id = result.first['id'] as int;

    final items = await _getItems(db, id);

    return Invoice.fromMap(result.first, items: items);
  }

  // ============================================================
  // GET ITEMS
  // ============================================================

  Future<List<InvoiceItem>> _getItems(Database db, int invoiceId) async {
    final result = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );

    return result.map((item) => InvoiceItem.fromMap(item)).toList();
  }
  // ============================================================
  // EDIT INVOICE
  // ============================================================

  Future<void> updateInvoice(Invoice invoice) async {
    final db = await database;

    await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );

    // Update invoice items if your app allows item editing.
  }

  // ============================================================
  // DELETE INVOICE
  // ============================================================

  Future<void> deleteInvoice(int id) async {
    final db = await database;

    await db.transaction((transaction) async {
      await transaction.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [id],
      );

      await transaction.delete('invoices', where: 'id = ?', whereArgs: [id]);
    });
  }
}
