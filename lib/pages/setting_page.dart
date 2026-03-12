import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  final bool isConnected;
  final bool sensorEnabled;
  final Future<void> Function(bool enable) onToggleSensor;

  const SettingPage({
    super.key,
    required this.isConnected,
    required this.sensorEnabled,
    required this.onToggleSensor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Row(
            children: [
              Icon(
                Icons.wifi_tethering,
                color: isConnected ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isConnected
                      ? 'เชื่อมต่อ MQTT สำเร็จ'
                      : 'ยังไม่ได้เชื่อมต่อ MQTT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isConnected ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
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
              const Text(
                'การควบคุมเซนเซอร์',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sensorEnabled
                    ? 'สถานะปัจจุบัน: เปิดการทำงานอยู่'
                    : 'สถานะปัจจุบัน: ปิดการทำงานอยู่',
                style: TextStyle(
                  fontSize: 15,
                  color: sensorEnabled ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: sensorEnabled,
                onChanged: isConnected
                    ? (value) {
                        onToggleSensor(value);
                      }
                    : null,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'เปิด/ปิดการทำงานของ Sensor',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                // ลบ subtitle ออก
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'หมายเหตุ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'การปิด Sensor ในหน้านี้เป็นการสั่งให้ ESP32 หยุดอ่านค่าจากเซนเซอร์เชิงซอฟต์แวร์ '
                'ไม่ได้เป็นการตัดไฟเลี้ยงของตัวเซนเซอร์จริง',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}