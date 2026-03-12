import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/google_sheets_service.dart'; // ใช้ ParkingLog, HourlyStats

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<ParkingLog> _logs = [];
  List<HourlyStats> _hourlyStats = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadDataSilent();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDataSilent() async {
    try {
      final results = await Future.wait([
        FirebaseService.fetchLatestLogs(count: 10),
        FirebaseService.fetchHourlyStats(),
      ]);
      if (mounted) {
        setState(() {
          _logs = results[0] as List<ParkingLog>;
          _hourlyStats = results[1] as List<HourlyStats>;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        FirebaseService.fetchLatestLogs(count: 10),
        FirebaseService.fetchHourlyStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _logs = results[0] as List<ParkingLog>;
        _hourlyStats = results[1] as List<HourlyStats>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลได้: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(
            icon: Icons.history,
            title: 'รายการสถานะช่องจอดล่าสุด',
            subtitle: 'Recent parking slot status list',
          ),
          const SizedBox(height: 12),
          _buildLogsList(),
          const SizedBox(height: 28),
          _buildSectionHeader(
            icon: Icons.bar_chart_rounded,
            title: 'กราฟสถิติรถเข้าจอด',
            subtitle: 'ช่วงเวลาที่มีรถจอดเยอะที่สุด',
          ),
          const SizedBox(height: 12),
          _buildHourlyChart(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue[700], size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogsList() {
    if (_logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'ยังไม่มีข้อมูลการเข้าจอด',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: List.generate(_logs.length, (index) {
            final log = _logs[index];
            final timeStr = log.entryTime != null
                ? DateFormat('dd/MM/yyyy HH:mm:ss').format(log.entryTime!)
                : '-';

            return Container(
              decoration: BoxDecoration(
                border: index < _logs.length - 1
                    ? Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.red[700],
                  ),
                ),
                title: Text(
                  'ช่องจอด ${log.slotNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'เวลาเข้า: $timeStr',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                // ไม่แสดง trailing status
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHourlyChart() {
    final maxCount =
        _hourlyStats.fold<int>(0, (prev, e) => e.count > prev ? e.count : prev);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 24, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxCount + 2).toDouble(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${group.x.toInt()}:00\n${rod.toY.toInt()} คัน',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        if (hour % 3 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble() && value >= 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _hourlyStats.map((stat) {
                  return BarChartGroupData(
                    x: stat.hour,
                    barRods: [
                      BarChartRodData(
                        toY: stat.count.toDouble(),
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.blue[300]!,
                            Colors.blue[600]!,
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'จำนวนรถเข้าจอดตามช่วงเวลา (ชม.)',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
          if (_hourlyStats.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPeakHourInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildPeakHourInfo() {
    final peak = _hourlyStats.reduce((a, b) => a.count >= b.count ? a : b);

    if (peak.count == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ช่วงเวลาที่มีรถเข้าจอดมากที่สุด: '
              '${peak.hour.toString().padLeft(2, '0')}:00 น. '
              '(${peak.count} คัน)',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}