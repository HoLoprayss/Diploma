import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_icons.dart';

/// Виджет для отображения SVG иконок приложения
class AppIcon extends StatelessWidget {
  final String iconPath;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const AppIcon(
    this.iconPath, {
    super.key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  /// Конструктор для иконки по категории продукта
  factory AppIcon.forProduct(
    String productName, {
    Key? key,
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return AppIcon(
      AppIcons.getIconByCategory(productName),
      key: key,
      width: width,
      height: height,
      color: color,
      fit: fit,
    );
  }

  /// Конструктор для иконки хранения (холодильник/кладовая)
  factory AppIcon.forStorage(
    String storageType, {
    Key? key,
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return AppIcon(
      AppIcons.getStorageIcon(storageType),
      key: key,
      width: width,
      height: height,
      color: color,
      fit: fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      iconPath,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      fit: fit,
      placeholderBuilder: (context) => Container(
        width: width ?? 24,
        height: height ?? 24,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.image_not_supported,
          size: (width ?? 24) * 0.6,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

