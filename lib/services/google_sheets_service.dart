import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ParkingLog {
  final String slotName;
  final int slotNumber;
  final int status;
  final DateTime? entryTime;

  ParkingLog({
    required this.slotName,
    required this.slotNumber,
    required this.status,
    this.entryTime,
  });

  factory ParkingLog.fromCsvRow(List<String> row) {
    final rawSlot = row[0].trim();
    final numMatch = RegExp(r'(\d+)').firstMatch(rawSlot);
    final slotNum = numMatch != null ? int.parse(numMatch.group(1)!) : 0;

    int statusVal;
    try {
      statusVal = int.parse(row[1].trim());
    } catch (_) {
      statusVal = 0;
    }

    DateTime? ts;
    if (row.length > 2 && row[2].trim().isNotEmpty) {
      try {
        ts = _parseTimestamp(row[2].trim());
      } catch (_) {
        ts = null;
      }
    }

    return ParkingLog(
      slotName: rawSlot,
      slotNumber: slotNum,
      status: statusVal,
      entryTime: ts,
    );
  }

  bool get isOccupied => status == 1;
  String get statusText => isOccupied ? 'ไม่ว่าง' : 'ว่าง';

  static DateTime _parseTimestamp(String s) {
    final formats = [
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('dd/MM/yyyy HH:mm:ss'),
      DateFormat('MM/dd/yyyy HH:mm:ss'),
      DateFormat('d/M/yyyy H:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm'),
      DateFormat('dd/MM/yyyy HH:mm'),
      DateFormat('M/d/yyyy H:mm:ss'),
    ];

    for (final fmt in formats) {
      try {
        return fmt.parse(s);
      } catch (_) {}
    }

    return DateTime.parse(s);
  }
}

class HourlyStats {
  final int hour;
  final int count;

  HourlyStats({required this.hour, required this.count});
}

class GoogleSheetsService {
  static const String spreadsheetId =
      '1O_SAL35I4yY7fpeVkJGmfhJWP7l_jwbj8oSKXqexZu4';

  static Future<List<ParkingLog>> fetchParkingLogs() async {
    final url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?tqx=out:csv&sheet=ParkingData',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load data from Google Sheets');
    }

    final body = utf8.decode(response.bodyBytes);
    final rows = _parseCsv(body);
    final dataRows = rows.length > 1 ? rows.sublist(1) : rows;

    final logs = <ParkingLog>[];
    for (final row in dataRows) {
      if (row.length >= 2 && row[0].trim().isNotEmpty) {
        try {
          logs.add(ParkingLog.fromCsvRow(row));
        } catch (_) {}
      }
    }

    return logs;
  }

  static Future<List<ParkingLog>> fetchLatestLogs({int count = 10}) async {
    final allLogs = await fetchParkingLogs();
    final occupied = allLogs
        .where((log) => log.isOccupied && log.entryTime != null)
        .toList();

    occupied.sort((a, b) => b.entryTime!.compareTo(a.entryTime!));
    return occupied.take(count).toList();
  }

  static Future<List<HourlyStats>> fetchHourlyStats() async {
    final allLogs = await fetchParkingLogs();

    final hourlyCounts = <int, int>{};
    for (int i = 0; i < 24; i++) {
      hourlyCounts[i] = 0;
    }

    for (final log in allLogs) {
      if (log.isOccupied && log.entryTime != null) {
        hourlyCounts[log.entryTime!.hour] =
            (hourlyCounts[log.entryTime!.hour] ?? 0) + 1;
      }
    }

    return hourlyCounts.entries
        .map((e) => HourlyStats(hour: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));
  }

  static List<List<String>> _parseCsv(String csv) {
    final rows = <List<String>>[];
    final lines = const LineSplitter().convert(csv);

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      rows.add(_parseCsvLine(line));
    }

    return rows;
  }

  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final c = line[i];

      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buffer.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buffer.write(c);
        }
      } else {
        if (c == '"') {
          inQuotes = true;
        } else if (c == ',') {
          fields.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(c);
        }
      }
    }

    fields.add(buffer.toString());
    return fields;
  }
}