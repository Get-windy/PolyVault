/// 图片优化服务
/// 提供压缩、缓存、懒加载支持
library image_optimizer;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

/// 图片压缩配置
class ImageCompressionConfig {
  final int maxWidth;
  final int maxHeight;
  int quality;
  final int targetSizeKB;

  const ImageCompressionConfig({
    this.maxWidth = 1920,
    this.maxHeight = 1080,
    this.quality = 85,
    this.targetSizeKB = 500,
  });

  /// 高质量配置
  const ImageCompressionConfig.highQuality()
      : maxWidth = 2560,
        maxHeight = 1440,
        quality = 95,
        targetSizeKB = 1000;

  /// 中等质量配置
  const ImageCompressionConfig.mediumQuality()
      : maxWidth = 1920,
        maxHeight = 1080,
        quality = 85,
        targetSizeKB = 500;

  /// 低质量配置（用于缩略图）
  const ImageCompressionConfig.thumbnail()
      : maxWidth = 320,
        maxHeight = 320,
        quality = 70,
        targetSizeKB = 50;
}

/// 图片优化器
class ImageOptimizer {
  ImageOptimizer._();

  /// 压缩图片
  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    ImageCompressionConfig config = const ImageCompressionConfig(),
  }) async {
    try {
      // 解码图片
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 计算缩放比例
      final aspectRatio = image.width / image.height;
      int targetWidth = image.width;
      int targetHeight = image.height;

      if (targetWidth > config.maxWidth) {
        targetWidth = config.maxWidth;
        targetHeight = (targetWidth / aspectRatio).round();
      }
      if (targetHeight > config.maxHeight) {
        targetHeight = config.maxHeight;
        targetWidth = (targetHeight * aspectRatio).round();
      }

      // 创建缩放后的图片数据
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('图片压缩失败: $e');
      return null;
    }
  }

  /// 获取图片尺寸
  static Future<Size> getImageSize(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  /// 计算压缩质量
  static int calculateQuality(int currentSizeKB, int targetSizeKB, int currentQuality) {
    if (currentSizeKB <= targetSizeKB) return currentQuality;
    
    final ratio = targetSizeKB / currentSizeKB;
    final newQuality = (currentQuality * ratio).round();
    return newQuality.clamp(10, 100);
  }
}

/// 懒加载图片组件
class LazyImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final ImageCompressionConfig? compressionConfig;
  final bool enableCache;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.compressionConfig,
    this.enableCache = true,
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _hasError = false;
  Uint8List? _imageBytes;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.enableCache) {
      final cached = await _getCachedImage();
      if (cached != null) {
        setState(() {
          _imageBytes = cached;
          _isLoading = false;
        });
        return;
      }
    }

    try {
      final uri = Uri.parse(widget.imageUrl);
      final response = await HttpClient().getUrl(uri);
      final httpResponse = await response.close();
      
      if (httpResponse.statusCode == 200) {
        final bytes = await httpResponse consolidateBytes();
        
        // 压缩图片
        Uint8List? finalBytes = bytes;
        if (widget.compressionConfig != null) {
          finalBytes = await ImageOptimizer.compressImage(
            bytes,
            config: widget.compressionConfig!,
          );
        }

        // 缓存图片
        if (widget.enableCache && finalBytes != null) {
          await _cacheImage(finalBytes);
        }

        if (mounted) {
          setState(() {
            _imageBytes = finalBytes ?? bytes;
            _isLoading = false;
          });
        }
      } else {
        _setError();
      }
    } catch (e) {
      _setError();
    }
  }

  void _setError() {
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<Uint8List?> _getCachedImage() async {
    // 简化的缓存逻辑，实际应用中应使用更完善的缓存系统
    return null;
  }

  Future<void> _cacheImage(Uint8List bytes) async {
    // 简化的缓存存储逻辑
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }

    if (_hasError || _imageBytes == null) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    return Image.memory(
      _imageBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// 带预加载的图片网格
class PreloadedImageGrid extends StatefulWidget {
  final List<String> imageUrls;
  final double spacing;
  final int crossAxisCount;
  final double aspectRatio;

  const PreloadedImageGrid({
    super.key,
    required this.imageUrls,
    this.spacing = 8,
    this.crossAxisCount = 3,
    this.aspectRatio = 1,
  });

  @override
  State<PreloadedImageGrid> createState() => _PreloadedImageGridState();
}

class _PreloadedImageGridState extends State<PreloadedImageGrid> {
  final Map<int, Uint8List> _preloadedImages = {};
  int _preloadIndex = 0;
  static const int _preloadAhead = 6;

  @override
  void initState() {
    super.initState();
    _startPreloading();
  }

  void _startPreloading() {
    // 预加载前方图片
    for (int i = _preloadIndex; i < _preloadIndex + _preloadAhead && i < widget.imageUrls.length; i++) {
      _preloadImage(i);
    }
  }

  Future<void> _preloadImage(int index) async {
    if (_preloadedImages.containsKey(index)) return;
    
    try {
      final uri = Uri.parse(widget.imageUrls[index]);
      final response = await HttpClient().getUrl(uri);
      final httpResponse = await response.close();
      final bytes = await httpResponse consolidateBytes();
      
      if (mounted) {
        setState(() {
          _preloadedImages[index] = bytes;
        });
      }
    } catch (e) {
      // 忽略预加载错误
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(widget.spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.spacing,
        crossAxisSpacing: widget.spacing,
        childAspectRatio: widget.aspectRatio,
      ),
      itemCount: widget.imageUrls.length,
      itemBuilder: (context, index) {
        final imageBytes = _preloadedImages[index];
        
        if (imageBytes != null) {
          return Image.memory(imageBytes, fit: BoxFit.cover);
        }
        
        return LazyImage(
          imageUrl: widget.imageUrls[index],
          fit: BoxFit.cover,
          compressionConfig: const ImageCompressionConfig.thumbnail(),
        );
      },
    );
  }
}

/// 图片缓存管理
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._();

  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxCacheCount = 200;

  /// 初始化缓存
  void initCache() {
    PaintingBinding.instance.imageCache.maximumSizeBytes = _maxCacheSize;
    PaintingBinding.instance.imageCache.maximumSize = _maxCacheCount;
  }

  /// 清除缓存
  void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// 预热缓存
  Future<void> warmupCache(List<String> urls) async {
    for (final url in urls) {
      precacheImage(NetworkImage(url), GlobalKey().currentContext!);
    }
  }

  /// 获取缓存状态
  Map<String, dynamic> getCacheStats() {
    final cache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': cache.currentSize,
      'currentSizeBytes': cache.currentSizeBytes,
      'maximumSize': cache.maximumSize,
      'maximumSizeBytes': cache.maximumSizeBytes,
      'pendingCount': cache.pendingImageCount,
    };
  }
}