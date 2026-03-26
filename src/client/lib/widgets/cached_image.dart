import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// PolyVault 图片缓存组件
/// 提供优化的图片加载和缓存功能

/// 缓存图片组件
class PVCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Duration fadeInDuration;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;

  const PVCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth ?? 500,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache ?? 1000,
      maxHeightDiskCache: maxHeightDiskCache,
      fadeInDuration: fadeInDuration,
      placeholder: placeholder != null
          ? (context, url) => placeholder!
          : (context, url) => _buildDefaultPlaceholder(context),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget!
          : (context, url, error) => _buildDefaultError(context, error),
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultError(BuildContext context, dynamic error) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.error,
        size: 32,
      ),
    );
  }
}

/// 头像图片组件 (带缓存)
class PVAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const PVAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final bgColor = backgroundColor ?? _getColorFromName(name);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          initials,
          style: textStyle ??
              TextStyle(
                color: Colors.white,
                fontSize: radius * 0.6,
                fontWeight: FontWeight.w500,
              ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: PVCachedImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          memCacheWidth: (radius * 2).toInt(),
          placeholder: (context, url) => Text(
            initials,
            style: textStyle ??
                TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.w500,
                ),
          ),
          errorWidget: (context, url, error) => Text(
            initials,
            style: textStyle ??
                TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getColorFromName(String name) {
    if (name.isEmpty) return Colors.grey;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    final index = name.codeUnits.reduce((a, b) => a + b) % colors.length;
    return colors[index];
  }
}

/// 图标图片组件 (带缓存)
class PVIconImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Color? color;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PVIconImage({
    super.key,
    required this.imageUrl,
    this.size = 24,
    this.color,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return PVCachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      memCacheWidth: size.toInt() * 2,
      placeholder: placeholder ??
          (context, url) => SizedBox(
                width: size,
                height: size,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
      errorWidget: errorWidget ??
          (context, url, error) => Icon(
                Icons.image_not_supported_outlined,
                size: size,
                color: color ?? Colors.grey,
              ),
    );
  }
}

/// 自定义缓存管理器
class PVCacheManager {
  static const key = 'polyVaultCache';

  static BaseCacheManager get instance => CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );

  /// 清除所有缓存
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }

  /// 获取缓存大小
  static Future<int> getCacheSize() async {
    // 简化实现，实际需要遍历缓存目录
    return 0;
  }

  /// 预加载图片
  static Future<void> preloadImages(List<String> urls) async {
    for (final url in urls) {
      await instance.downloadFile(url);
    }
  }
}