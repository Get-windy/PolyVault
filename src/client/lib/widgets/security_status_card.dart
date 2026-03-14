import 'package:flutter/material.dart';

/// 安全状态卡片
class SecurityStatusCard extends StatelessWidget {
  final bool isBiometricAvailable;
  final bool isHardwareSecure;
  final String encryptionLevel;

  const SecurityStatusCard({
    super.key,
    required this.isBiometricAvailable,
    required this.isHardwareSecure,
    required this.encryptionLevel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.security,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '安全状态',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSecurityItem(
              icon: isBiometricAvailable ? Icons.fingerprint : Icons.lock,
              title: '生物认证',
              status: isBiometricAvailable ? '已启用' : '未启用',
              isActive: isBiometricAvailable,
            ),
            const SizedBox(height: 12),
            _buildSecurityItem(
              icon: Icons.hardware,
              title: '硬件安全',
              status: isHardwareSecure ? '已启用' : '软件加密',
              isActive: isHardwareSecure,
            ),
            const SizedBox(height: 12),
            _buildSecurityItem(
              icon: Icons.enhanced_encryption,
              title: '加密级别',
              status: encryptionLevel,
              isActive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String status,
    required bool isActive,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isActive ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.orange,
            ),
          ),
        ),
      ],
    );
  }
}
