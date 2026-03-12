import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'package:intl/intl.dart';
import 'google_sheets_service.dart'; // ใช้ ParkingLog, HourlyStats

class FirebaseService {
  static const String baseUrl =
      'https://carparking-982c9-default-rtdb.asia-southeast1.firebasedatabase.app/history.json';

  static Future<List<ParkingLog>> fetchLatestLogs({int count = 10}) async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load data from Firebase');
    }
    final Map<String, dynamic> data = json.decode(response.body);
    final logs = <ParkingLog>[];
    for (final entry in data.entries) {
      final item = entry.value;
      logs.add(ParkingLog(
        slotName: 'Slot ${item['slot'] ?? ''}',
        slotNumber: item['slot'] ?? 0,
        status: 1, // ถือว่าเป็นการจอง
        entryTime: item['entry_time'] != null
            ? DateTime.tryParse(item['entry_time'])
            : null,
      ));
    }
    final occupied = logs
        .where((log) => log.entryTime != null)
        .toList();
    occupied.sort((a, b) => b.entryTime!.compareTo(a.entryTime!));
    return occupied.take(count).toList();
  }

  static Future<List<HourlyStats>> fetchHourlyStats() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load data from Firebase');
    }
    final Map<String, dynamic> data = json.decode(response.body);
    final logs = <ParkingLog>[];
    for (final entry in data.entries) {
      final item = entry.value;
      logs.add(ParkingLog(
        slotName: 'Slot ${item['slot'] ?? ''}',
        slotNumber: item['slot'] ?? 0,
        status: 1,
        entryTime: item['entry_time'] != null
            ? DateTime.tryParse(item['entry_time'])
            : null,
      ));
    }
    final hourlyCounts = <int, int>{};
    for (int i = 0; i < 24; i++) {
      hourlyCounts[i] = 0;
    }
    for (final log in logs) {
      if (log.entryTime != null) {
        hourlyCounts[log.entryTime!.hour] =
            (hourlyCounts[log.entryTime!.hour] ?? 0) + 1;
      }
    }
    return hourlyCounts.entries
        .map((e) => HourlyStats(hour: e.key, count: e.value))
        .toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));
  }
}
