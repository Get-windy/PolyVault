import 'package:flutter/material.dart';
import '../widgets/animated_connection_indicator.dart';
import '../widgets/custom_button.dart';

/// 设备管理页面
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final List<DeviceInfo> _devices = [
    DeviceInfo(
      id: '1',
      name: '我的手机',
      type: 'Mobile Phone',
      isConnected: true,
      platform: 'Android',
      ipAddress: '192.168.1.100',
    ),
    DeviceInfo(
      id: '2',
      name: '工作电脑',
      type: 'Desktop Computer',
      isConnected: false,
      lastSeen: '2小时前',
      platform: 'Windows',
      ipAddress: '192.168.1.101',
    ),
  ];

  bool _isScanning = false;

  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isScanning = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('扫描完成')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设备管理',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanForDevices,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _scanForDevices,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 本机设备
            _buildSectionHeader('本机设备'),
            AnimatedDeviceCard(
              deviceName: '本机设备',
              deviceType: 'Current Device',
              isConnected: true,
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // 已配对设备
            _buildSectionHeader('已配对设备'),
            ..._devices.map((device) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DeviceConnectionCard(
                    deviceName: device.name,
                    deviceType: '${device.type} • ${device.platform}',
                    isConnected: device.isConnected,
                    lastSeen: device.lastSeen,
                    onConnect: device.isConnected
                        ? null
                        : () => _connectDevice(device),
                    onDisconnect: device.isConnected
                        ? () => _disconnectDevice(device)
                        : null,
                  ),
                )),

            const SizedBox(height: 24),

            // 添加新设备
            _buildSectionHeader('添加设备'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: InkWell(
                onTap: () => _showAddDeviceDialog(),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_link,
                          size: 32,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '添加新设备',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '扫描二维码或输入设备码配对',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _connectDevice(DeviceInfo device) {
    setState(() {
      device.isConnected = true;
      device.lastSeen = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已连接到 ${device.name}')),
    );
  }

  void _disconnectDevice(DeviceInfo device) {
    setState(() {
      device.isConnected = false;
      device.lastSeen = '刚刚';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已断开 ${device.name}')),
    );
  }

  void _showAddDeviceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '添加新设备',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('扫描二维码'),
              subtitle: const Text('扫描设备上的配对二维码'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius