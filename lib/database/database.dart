import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
part 'database.g.dart';

class Urls extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text().unique()();
  TextColumn get title => text().nullable()();
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class History extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get urlId =>
      integer().references(Urls, #id, onDelete: KeyAction.cascade)();
  IntColumn get visitFrom => integer().nullable().references(Urls, #id)();
  IntColumn get eventType => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Preferences extends Table {
  TextColumn get id => text().unique()();
  TextColumn get value => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(tables: [Bookmarks, History, Preferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(preferences);
        }
      },
    );
  }
}

final appDatabase = AppDatabase();

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(dbFolder.path, ".zero_browser", 'data_unstable.sqlite'),
    );
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
