library seq_logger;

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SeqLogger {
  static bool _initialized = false;

  /// returns true if initialized (url and batchsize are provided)
  static bool get initialized => _initialized;

  /// The count of records to send in one post
  /// default value is 50
  static int _batchSize = 50;

  /// YOUR API KEY for seqLogger API
  static String? _apiKey;

  /// The host address of your API End Point
  /// ex: https://yourdomain.com/api/add-log
  static String _url = "";

  static init({required String url, int? batchSize, String? apiKey}) {
    _url = url;
    _apiKey = apiKey;
    if (batchSize != null) _batchSize = batchSize;
    _initialized = true;
    log("SeqLogger is initialized", name: "SeqLogger");
  }

  /// Creates a Log Model from parameters and inserts to SQLite Database
  ///
  /// (String) message: Your message template (required)
  ///
  /// (Enum) level: importance level of your log, default is info
  ///
  /// (Json?) data: Any json data.
  ///
  /// ```
  /// addLogToDb(message:"My awesome log", level: LogLevel.debug);
  ///
  /// ```
  static Future<void> addLogToDb({
    required String message,
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? data,
  }) async {
    var logModel = LogModel(
      level: _nameOfLevel(level),
      mt: message,
      t: LoggerUtils.getDbTime(),
      data: data,
    );

    await _LoggerDbProvider.db.insert(logModel: logModel);

    log("Log recorded", name: "SeqLogger");
  }

  ///
  static Future<void> logDebug({required String message}) async {
    await addLogToDb(message: message, level: LogLevel.debug);
  }

  /// Returns message of the log containing information to addLogToDb
  static Future<void> logInfo({required String message}) async {
    await addLogToDb(message: message, level: LogLevel.info);
  }

  /// Returns message of the log containing warning to addLogToDb
  static Future<void> logWarning({required String message}) async {
    await addLogToDb(message: message, level: LogLevel.warning);
  }

  /// Returns message of the log containing error to addLogToDb
  static Future<void> logError({required String message}) async {
    await addLogToDb(message: message, level: LogLevel.error);
  }

  ///
  static Future<void> logVerbose({required String message}) async {
    await addLogToDb(message: message, level: LogLevel.verbose);
  }

  /// Method that returns the count of log records from the database
  static Future<int> getRecordCount() async {
    return await _LoggerDbProvider.db.getRecordCount();
  }

  /// Methot that read records from database and post to API
  static Future<void> sendLogs() async {
    if (!initialized) {
      /// Not supposed to run before initialization
      throw Exception(
          "You must initialize Logger first. Host address is required.");
    }

    var logs = await _LoggerDbProvider.db.getLogs();

    if (logs.isEmpty) {
      log("No logs to sent", name: "SeqLogger");
      return;
    }

    String dataToSend = "";
    var logsToDelete = <int>[];

    for (var l in logs) {
      var stringData = l[LoggerDbConstants.keyData] as String;
      dataToSend += "$stringData\n";
      logsToDelete.add(l[LoggerDbConstants.keyId]);
    }

    var sendResult = await LoggerNetworkProvider.sendAll(dataToSend);

    if (sendResult) {
      // delete sent items from SQLite Db
      var deleteResult = await _LoggerDbProvider.db.deleteLogs(logsToDelete);
      log("${logs.length} record(s) has been sent, $deleteResult record(s) has been deleted",
          name: "SeqLogger");
      // re-run to send remaining items.
      sendLogs();
    }
  }

  static String _nameOfLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return "info";
      case LogLevel.error:
        return "error";
      case LogLevel.verbose:
        return "verbose";
      case LogLevel.warning:
        return "warning";
      default:
        return "debug";
    }
  }
}

/// Network class
/// The class that performs the post process with the dio library
class LoggerNetworkProvider {
  static Future<bool> sendAll(String dataList) async {
    Dio dio = Dio();
    dio.options.followRedirects = false;
    dio.options.baseUrl = SeqLogger._url;
    dio.options.responseType = ResponseType.json;
    dio.options.contentType = "text/plain";
    if (SeqLogger._apiKey != null && SeqLogger._apiKey!.isNotEmpty) {
      dio.options.headers.addAll({"X-Seq-ApiKey": SeqLogger._apiKey});
    }
    try {
      final response = await dio.post(SeqLogger._url, data: dataList);

      switch (response.statusCode) {
        case HttpStatus.ok:
        case HttpStatus.created:
          return true;
        default:
          return false;
      }
    } catch (err) {
      log("Error while sending: ${err.toString()}", name: "SeqLogger");
      return false;
    }
  }
}

/// Class with database operations
class _LoggerDbProvider {
  _LoggerDbProvider._();
  static final _LoggerDbProvider db = _LoggerDbProvider._();
  Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await initDb();
    return _database;
  }

  /// The method we created the database
  initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'seq_logger_db.sqflite');
    return await openDatabase(path, version: 1, singleInstance: true,
        onCreate: (Database db, int version) async {
      await db.execute(LoggerDbConstants.dropTableItems);
      await db.execute(LoggerDbConstants.createTableItems);
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      // Enchantment: read all data for backup
      await db.execute(LoggerDbConstants.dropTableItems);
      await db.execute(LoggerDbConstants.createTableItems);
      // Enchantment: restore all data from backup
    });
  }

  /// Method that adds logs to database
  Future<int> insert({required LogModel logModel}) async {
    final db = await database;
    if (db == null) return -1;
    try {
      Map<String, dynamic> map = {};
      logModel.data ??= {};
      map = logModel.data!;
      map["@t"] = logModel.t;
      map["@mt"] = logModel.mt;
      map["@l"] = logModel.level;

      String mapString = json.encode(map);

      Map<String, String> dbMap = {
        LoggerDbConstants.keyData: mapString,
      };

      int id = await db.insert(LoggerDbConstants.itemsTable, dbMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
      return id;
    } catch (err) {
      log(err.toString(), name: "SeqLogger");
      return -1;
    }
  }

  /// Method to delete all logs in database
  Future<int> deleteAll() async {
    final db = await database;
    if (db == null) return -1;
    try {
      int id = await db.delete(LoggerDbConstants.itemsTable);
      return id;
    } catch (err) {
      log(err.toString(), name: "SeqLogger");
      return -1;
    }
  }

  /// The method that deletes the remaining saved logs while sending the logs in the database
  Future<int> deleteRecord(int id) async {
    final db = await database;
    if (db == null) return -1;
    try {
      int deleteResult = await db.delete(
        LoggerDbConstants.itemsTable,
        where: "${LoggerDbConstants.keyId} = ?",
        whereArgs: ["$id"],
      );
      return deleteResult;
    } catch (err) {
      log(err.toString(), name: "SeqLogger");
      return -1;
    }
  }

  /// The method that deletes the remaining list of saved logs while sending the logs in the database
  Future<int> deleteLogs(List<int> idList) async {
    var deleteCount = 0;
    for (var id in idList) {
      deleteCount += await deleteRecord(id);
    }
    return deleteCount;
  }

  Future<List<Map<String, dynamic>>> getLogs() async {
    List<Map<String, dynamic>> logList = [];
    final db = await database;
    if (db == null) return logList;
    try {
      var result = await db.query(LoggerDbConstants.itemsTable,
          columns: [
            LoggerDbConstants.keyData,
            LoggerDbConstants.keyId,
          ],
          orderBy: LoggerDbConstants.keyId,
          limit: SeqLogger._batchSize);
      if (result.isNotEmpty) {
        for (var row in result) {
          logList.add(row);
        }
      }
    } catch (err) {
      log(err.toString(), name: "SeqLogger");
      return logList;
    }
    return logList;
  }

  /// Method that gives the number of logs registered in the database
  Future<int> getRecordCount() async {
    int result = 0;
    final db = await database;
    if (db == null) return result;
    try {
      var r = await db.query(
        LoggerDbConstants.itemsTable,
        columns: [
          LoggerDbConstants.keyData,
          LoggerDbConstants.keyId,
        ],
      );
      if (r.isNotEmpty) {
        result = r.length;
      }
    } catch (err) {
      log(err.toString(), name: "SeqLogger");
      return result;
    }
    return result;
  }
}

/// Class where we keep our constant variables
class LoggerDbConstants {
  static const String itemsTable = 'items';
  static const String keyId = 'id';
  static const String keyData = 'dataColumn';

  static String createTableItems = '''
    CREATE TABLE IF NOT EXISTS $itemsTable (
      $keyId INTEGER PRIMARY KEY AUTOINCREMENT,
      $keyData TEXT
    )
  ''';

  static const String dropTableItems = 'DROP TABLE IF EXISTS $itemsTable';
}

/// Level of the log
/// for filtering and importance
enum LogLevel {
  /// information level logging
  info,

  /// warning level logging
  warning,

  /// debug level logging
  debug,

  /// error level logging
  error,

  /// verbose level logging
  verbose,
}

/// The class that the model is in
class LogModel {
  String t;
  String mt;
  String level;
  Map<String, dynamic>? data;
  LogModel({
    required this.t,
    required this.mt,
    this.level = "debug",
    this.data,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      '@t': t,
      '@mt': mt,
      '@l': level,
      'data': data,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      t: map['@t'],
      mt: map['@mt'],
      level: map['@l'],
      data: map['data'],
    );
  }
}

class LoggerUtils {
  /// Method that gives the time in the format we want
  static String getDbTime() {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss.mmm").format(DateTime.now());
  }
}
