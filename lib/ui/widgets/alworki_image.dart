import 'package:flutter/material.dart';

import '../../config/asset_paths.dart';

class AlworkiImage extends StatelessWidget {
  const AlworkiImage({
    super.key,
    required this.imageKey,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String imageKey;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final path = AssetPaths.resolve(imageKey);
    Widget img = Image.asset(
      path,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _Fallback(imageKey: imageKey, height: height, width: width),
    );
    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}

class AlworkiAvatar extends StatelessWidget {
  const AlworkiAvatar({super.key, required this.avatarKey, this.radius = 20});

  final String avatarKey;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: AssetImage(AssetPaths.resolve(avatarKey)),
      onBackgroundImageError: (exception, stackTrace) {},
      child: null,
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.imageKey, this.height, this.width});
  final String imageKey;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary];
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
      ),
      child: const Icon(Icons.image, color: Colors.white70),
    );
  }
}
