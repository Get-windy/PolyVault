import 'package:flutter/material.dart';
import '../widgets/animated_connection_indicator.dart';
import '../widgets/qr_scanner.dart';

class DeviceInfo {
  String id, name, type, platform, ipAddress;
  bool isConnected;
  String? lastSeen;
  DateTime? pairedAt;
  DeviceInfo({required this.id, required this.name, required this.type, required this.isConnected,
    this.lastSeen, required this.platform, required this.ipAddress, this.pairedAt});
}

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final List<DeviceInfo> _devices = [
    DeviceInfo(id: '1', name: '我的手机', type: 'Mobile Phone', isConnected: true,
      platform: 'Android', ipAddress: '192.168.1.100', pairedAt: DateTime.now().subtract(const Duration(days: 30))),
    DeviceInfo(id: '2', name: '工作电脑', type: 'Desktop Computer', isConnected: false,
      lastSeen: '2小时前', platform: 'Windows', ipAddress: '192.168.1.101', pairedAt: DateTime.now().subtract(const Duration(days: 60))),
    DeviceInfo(id: '3', name: 'iPad平板', type: 'Tablet', isConnected: false,
      lastSeen: '1天前', platform: 'iOS', ipAddress: '192.168.1.102', pairedAt: DateTime.now().subtract(const Duration(days: 15))),
  ];
  bool _isScanning = false;

  Future<void> _scanForDevices() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isScanning = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('扫描完成')));
  }

  void _deleteDevice(DeviceInfo device) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('删除设备'),
      content: Text('确定要删除设备"${device.name}"吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: () {
          setState(() => _devices.removeWhere((d) => d.id == device.id));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已删除 ${device.name}')));
        }, style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
      ],
    ));
  }

  void _addDevice(String code) {
    final newDevice = DeviceInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '新设备',
      type: 'Unknown',
      isConnected: false,
      lastSeen: '刚刚',
      platform: 'Unknown',
      ipAddress: '192.168.1.xxx',
      pairedAt: DateTime.now(),
    );
    setState(() => _devices.add(newDevice));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已添加新设备')));
  }

  void _connectDevice(DeviceInfo device) {
    setState(() { device.isConnected = true; device.lastSeen = null; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已连接到 ${device.name}')));
  }

  void _disconnectDevice(DeviceInfo device) {
    setState(() { device.isConnected = false; device.lastSeen = '刚刚'; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已断开 ${device.name}')));
  }

  void _showDeviceDetail(DeviceInfo device) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Row(children: [
            ConnectionPulse(isActive: device.isConnected, size: 60, color: device.isConnected ? Colors.green : Colors.grey),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(device.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(device.type, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ])),
          ]),
          const SizedBox(height: 24),
          _buildDetailItem('设备ID', device.id),
          _buildDetailItem('平台', device.platform),
          _buildDetailItem('IP地址', device.ipAddress),
          _buildDetailItem('连接状态', device.isConnected ? '已连接' : '未连接', valueColor: device.isConnected ? Colors.green : Colors.grey),
          if (device.lastSeen != null) _buildDetailItem('最后在线', device.lastSeen!),
          if (device.pairedAt != null) _buildDetailItem('配对时间', '${device.pairedAt!.year}-${device.pairedAt!.month.toString().padLeft(2, '0')}-${device.pairedAt!.day.toString().padLeft(2, '0')}'),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(context); _deleteDevice(device); },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('删除设备', style: TextStyle(color: Colors.red)))),
            const SizedBox(width: 16),
            Expanded(child: FilledButton.icon(
              onPressed: () { Navigator.pop(context); device.isConnected ? _disconnectDevice(device) : _connectDevice(device); },
              icon: Icon(device.isConnected ? Icons.link_off : Icons.link),
              label: Text(device.isConnected ? '断开连接' : '连接'))),
          ]),
        ])));
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
      ]));
  }

  void _showAddDeviceDialog() {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('添加新设备', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.qr_code_scanner, color: Theme.of(context).colorScheme.onPrimaryContainer)),
            title: const Text('扫描二维码'), subtitle: const Text('扫描设备上的配对二维码'),
            onTap: () { Navigator.pop(context); _showQRScanner(); }),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSecondaryContainer)),
            title: const Text('手动输入'), subtitle: const Text('输入设备配对码'),
            onTap: () { Navigator.pop(context); _showManualInput(); }),
        ])));
  }

  void _showQRScanner() {
    showDialog(context: context, builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: QRScanner(onScan: (code) { Navigator.pop