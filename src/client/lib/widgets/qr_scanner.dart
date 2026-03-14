import 'package:flutter/material.dart';

/// QR码扫描器组件
class QRScanner extends StatefulWidget {
  final Function(String) onScan;
  final VoidCallback onClose;

  const QRScanner({
    super.key,
    required this.onScan,
    required this.onClose,
  });

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // 模拟扫描成功
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isScanning) {
        widget.onScan('device_code_12345');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 扫描区域
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // 角落标记
                  _buildCornerMarker(Alignment.topLeft),
                  _buildCornerMarker(Alignment.topRight),
                  _buildCornerMarker(Alignment.bottomLeft),
                  _buildCornerMarker(Alignment.bottomRight),

                  // 扫描线动画
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * 200,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.green.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 关闭按钮
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onClose,
            ),
          ),

          // 提示文字
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '将二维码放入框内扫描',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerMarker(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? BorderSide.none
                : const BorderSide(color: Colors.green, width: 3),
            bottom: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? BorderSide.none
                : const BorderSide(color: Colors.green, width: 3),
            left: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? BorderSide.none
                : const BorderSide(color: Colors.green, width: 3),
            right: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? BorderSide.none
                : const BorderSide(color: Colors.green, width: 3),
          ),
        ),
      ),
    );
  }
}

/// 手动输入设备码
class ManualDeviceInput extends StatefulWidget {
  final Function(String) onSubmit;
  final VoidCallback onClose;

  const ManualDeviceInput({
    super.key,
    required this.onSubmit,
    required this.onClose,
  });

  @override
  State<ManualDeviceInput> createState() => _ManualDeviceInputState();
}

class _ManualDeviceInputState extends State<ManualDeviceInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '输入设备配对码',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '在目标设备上查看配对码',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: '例如: PV-1234-5678',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.devices),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClose,
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      widget.onSubmit(_controller.text);
                    }
                  },
                  child: const Text('连接'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
