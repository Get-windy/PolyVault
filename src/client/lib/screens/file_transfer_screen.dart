import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 文件传输项
class TransferItem {
  final String id;
  final String name;
  final String path;
  final int size;
  final TransferType type;
  final TransferStatus status;
  final double progress;
  final DateTime startTime;
  final DateTime? endTime;
  final String? error;

  const TransferItem({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    required this.status,
    this.progress = 0,
    required this.startTime,
    this.endTime,
    this.error,
  });

  TransferItem copyWith({
    TransferStatus? status,
    double? progress,
    DateTime? endTime,
    String? error,
  }) {
    return TransferItem(
      id: id,
      name: name,
      path: path,
      size: size,
      type: type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      error: error ?? this.error,
    );
  }
}

/// 传输类型
enum TransferType { upload, download }

/// 传输状态
enum TransferStatus { pending, inProgress, completed, failed, cancelled }

/// 文件信息
class FileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final String? thumbnail;

  const FileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    this.thumbnail,
  });
}

/// 文件传输主屏幕
class FileTransferScreen extends StatefulWidget {
  const FileTransferScreen({super.key});

  @override
  State<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends State<FileTransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 传输历史
  final List<TransferItem> _transfers = [
    TransferItem(
      id: '1',
      name: 'document.pdf',
      path: '/storage/documents/document.pdf',
      size: 2048576,
      type: TransferType.download,
      status: TransferStatus.completed,
      progress: 1.0,
      startTime: DateTime.now().subtract(const Duration(hours: 1)),
      endTime: DateTime.now().subtract(const Duration(minutes: 55)),
    ),
    TransferItem(
      id: '2',
      name: 'photo.jpg',
      path: '/storage/images/photo.jpg',
      size: 1536000,
      type: TransferType.upload,
      status: TransferStatus.inProgress,
      progress: 0.65,
      startTime: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    TransferItem(
      id: '3',
      name: 'backup.zip',
      path: '/storage/backup/backup.zip',
      size: 52428800,
      type: TransferType.download,
      status: TransferStatus.pending,
      progress: 0,
      startTime: DateTime.now(),
    ),
    TransferItem(
      id: '4',
      name: 'video.mp4',
      path: '/storage/videos/video.mp4',
      size: 104857600,
      type: TransferType.download,
      status: TransferStatus.failed,
      progress: 0.45,
      startTime: DateTime.now().subtract(const Duration(minutes: 10)),
      error: '网络连接中断',
    ),
  ];

  // 本地文件 (模拟)
  final List<FileInfo> _localFiles = [
    FileInfo(
      name: 'projects.zip',
      path: '/documents/projects.zip',
      size: 15728640,
      modified: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FileInfo(
      name: 'report.pdf',
      path: '/documents/report.pdf',
      size: 524288,
      modified: DateTime.now().subtract(const Duration(days: 2)),
    ),
    FileInfo(
      name: 'photo_album',
      path: '/images/photo_album',
      size: 31457280,
      modified: DateTime.now().subtract(const Duration(days: 3)),
    ),
    FileInfo(
      name: 'notes.txt',
      path: '/documents/notes.txt',
      size: 8192,
      modified: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  // 最近文件 (模拟)
  final List<FileInfo> _recentFiles = [
    FileInfo(
      name: 'presentation.pptx',
      path: '/work/presentation.pptx',
      size: 8388608,
      modified: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    FileInfo(
      name: 'data.csv',
      path: '/work/data.csv',
      size: 204800,
      modified: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件传输'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '传输', icon: Icon(Icons.swap_vert)),
            Tab(text: '本地文件', icon: Icon(Icons.folder)),
            Tab(text: '最近', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransfersTab(),
          _buildLocalFilesTab(),
          _buildRecentFilesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectFiles,
        icon: const Icon(Icons.add),
        label: const Text('选择文件'),
      ),
    );
  }

  /// 传输标签页
  Widget _buildTransfersTab() {
    final activeTransfers = _transfers.where((t) =>
        t.status == TransferStatus.inProgress || t.status == TransferStatus.pending).toList();
    final completedTransfers = _transfers.where((t) =>
        t.status == TransferStatus.completed || t.status == TransferStatus.failed).toList();

    if (_transfers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.swap_horiz,
        title: '暂无传输记录',
        subtitle: '选择文件开始上传或下载',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 进行中的传输
        if (activeTransfers.isNotEmpty) ...[
          _buildSectionHeader('进行中', activeTransfers.length),
          const SizedBox(height: 8),
          ...activeTransfers.map((t) => _buildTransferItem(t)),
          const SizedBox(height: 24),
        ],
        // 传输历史
        if (completedTransfers.isNotEmpty) ...[
          _buildSectionHeader('历史记录', completedTransfers.length),
          const SizedBox(height: 8),
          ...completedTransfers.map((t) => _buildTransferItem(t)),
        ],
      ],
    );
  }

  /// 本地文件标签页
  Widget _buildLocalFilesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _localFiles.length,
      itemBuilder: (context, index) {
        final file = _localFiles[index];
        return _buildFileItem(file, showUpload: true);
      },
    );
  }

  /// 最近文件标签页
  Widget _buildRecentFilesTab() {
    if (_recentFiles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: '暂无最近文件',
        subtitle: '最近打开的文件将显示在这里',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentFiles.length,
      itemBuilder: (context, index) {
        final file = _recentFiles[index];
        return _buildFileItem(file);
      },
    );
  }

  /// 传输项
  Widget _buildTransferItem(TransferItem item) {
    final isUpload = item.type == TransferType.upload;
    final isActive = item.status == TransferStatus.inProgress || item.status == TransferStatus.pending;

    Color statusColor;
    IconData statusIcon;
    switch (item.status) {
      case TransferStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case TransferStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = isUpload ? Icons.upload : Icons.download;
        break;
      case TransferStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TransferStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case TransferStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${isUpload ? "上传" : "下载"} • ${_formatSize(item.size)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // 操作按钮
                if (isActive)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => _cancelTransfer(item),
                    color: Colors.grey,
                  )
                else
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[400]),
                    onSelected: (value) {
                      switch (value) {
                        case 'retry':
                          _retryTransfer(item);
                          break;
                        case 'delete':
                          _deleteTransfer(item);
                          break;
                        case 'open':
                          _openFile(item);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (item.status == TransferStatus.failed)
                        const PopupMenuItem(value: 'retry', child: Text('重试')),
                      const PopupMenuItem(value: 'open', child: Text('打开')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
              ],
            ),
            // 进度条
            if (item.status == TransferStatus.inProgress) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(statusColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(item.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            // 错误信息
            if (item.status == TransferStatus.failed && item.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.error!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 时间
            const SizedBox(height: 8),
            Text(
              _formatTime(item.startTime),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  /// 文件项
  Widget _buildFileItem(FileInfo file, {bool showUpload = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _previewFile(file),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getFileColor(file.name).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(file.name),
            color: _getFileColor(file.name),
          ),
        ),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatSize(file.size)} • ${_formatTime(file.modified)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(file),
              tooltip: '下载',
            ),
            if (showUpload)
              IconButton(
                icon: const Icon(Icons.upload),
                onPressed: () => _uploadFile(file),
                tooltip: '上传',
              ),
          ],
        ),
      ),
    );
  }

  /// 分组标题
  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  /// 空状态
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 刷新
  void _refresh() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('刷新中...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 选择文件
  void _selectFiles() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('图片'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('选择图片'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
              title: const Text('文档'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('选择文档'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.purple),
              title: const Text('视频'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('选择视频'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 取消传输
  void _cancelTransfer(TransferItem item) {
    setState(() {
      final index = _transfers.indexWhere((t) => t.id == item.id);
      if (index != -1) {
        _transfers[index] = item.copyWith(
          status: TransferStatus.cancelled,
          endTime: DateTime.now(),
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('传输已取消'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 重试传输
  void _retryTransfer(TransferItem item) {
    setState(() {
      final index = _transfers.indexWhere((t) => t.id == item.id);
      if (index != -1) {
        _transfers[index] = item.copyWith(
          status: TransferStatus.inProgress,
          progress: 0,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在重试...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 删除传输记录
  void _deleteTransfer(TransferItem item) {
    setState(() {
      _transfers.removeWhere((t) => t.id == item.id);
    });
  }

  /// 打开文件
  void _openFile(TransferItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('打开: ${item.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 预览文件
  void _previewFile(FileInfo file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilePreviewSheet(file: file),
    );
  }

  /// 下载文件
  void _downloadFile(FileInfo file) {
    final newTransfer = TransferItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      name: file.name,
      path: file.path,
      size: file.size,
      type: TransferType.download,
      status: TransferStatus.inProgress,
      startTime: DateTime.now(),
    );
    setState(() => _transfers.add(newTransfer));
  }

  /// 上传文件
  void _uploadFile(FileInfo file) {
    final newTransfer = TransferItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      name: file.name,
      path: file.path,
      size: file.size,
      type: TransferType.upload,
      status: TransferStatus.inProgress,
      startTime: DateTime.now(),
    );
    setState(() => _transfers.add(newTransfer));
  }

  /// 获取文件图标
  IconData _getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// 获取文件颜色
  Color _getFileColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.pink;
      case 'mp3':
      case 'wav':
        return Colors.teal;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  /// 格式化大小
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}月${time.day}日';
  }
}

/// 文件预览面板
class _FilePreviewSheet extends StatelessWidget {
  final FileInfo file;

  const _FilePreviewSheet({required this.file});

  @override
  Widget build(BuildContext context) {
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(
      file.name.split('.').last.toLowerCase(),
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖动条
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 头部
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          // 预览内容
          Expanded(
            child: isImage
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '文件预览',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
          ),
          // 底部按钮
          Container(
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('分享文件'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('分享'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('下载 ${file.name}'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('下载'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}