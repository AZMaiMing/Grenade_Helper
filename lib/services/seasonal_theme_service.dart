import 'package:flutter/material.dart';

/// 节日主题基类
///
/// 所有节日主题（圣诞节、春节、情人节等）都应继承此类
abstract class SeasonalTheme {
  /// 主题唯一标识符
  String get id;

  /// 名称
  String get name;

  /// 图标
  String get emoji;

  /// 开始日期
  int get startMonth;
  int get startDay;

  /// 结束日期
  int get endMonth;
  int get endDay;

  /// 浅色配色
  ColorScheme getLightColorScheme();

  /// 深色配色
  ColorScheme getDarkColorScheme();

  /// 构建装饰
  Widget? buildDecoration(BuildContext context);

  /// 构建AppBar装饰
  Widget? buildAppBarDecoration(BuildContext context) => null;

  /// 检查激活
  bool isActiveOn(DateTime date) {
    final year = date.year;

    // 处理跨年情况（如圣诞节 12月20日 - 1月2日）
    if (endMonth < startMonth) {
      // 跨年：检查是否在开始月之后（去年底） 或 结束月之前（今年初）
      final startDate = DateTime(year, startMonth, startDay);
      final endDateThisYear = DateTime(year, endMonth, endDay, 23, 59, 59);

      // 如果当前日期在开始日期之后（年底）或在结束日期之前（年初）
      return date.isAfter(startDate.subtract(const Duration(days: 1))) ||
          date.isBefore(endDateThisYear.add(const Duration(days: 1)));
    } else {
      // 同年
      final startDate = DateTime(year, startMonth, startDay);
      final endDate = DateTime(year, endMonth, endDay, 23, 59, 59);

      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }
  }
}

/// 主题管理
class SeasonalThemeManager {
  SeasonalThemeManager._();

  /// 已注册主题
  static final List<SeasonalTheme> _themes = [];

  /// 注册
  static void registerTheme(SeasonalTheme theme) {
    if (!_themes.any((t) => t.id == theme.id)) {
      _themes.add(theme);
    }
  }

  /// 获取所有
  static List<SeasonalTheme> get themes => List.unmodifiable(_themes);

  /// 获取当前
  static SeasonalTheme? getActiveTheme([DateTime? date]) {
    final now = date ?? DateTime.now();
    for (final theme in _themes) {
      if (theme.isActiveOn(now)) {
        return theme;
      }
    }
    return null;
  }

  /// ID获取
  static SeasonalTheme? getThemeById(String id) {
    for (final theme in _themes) {
      if (theme.id == id) {
        return theme;
      }
    }
    return null;
  }

  /// 应用配色
  static ThemeData applySeasonalColors(
    ThemeData baseTheme,
    SeasonalTheme seasonalTheme,
    bool isDark,
  ) {
    final colorScheme = isDark
        ? seasonalTheme.getDarkColorScheme()
        : seasonalTheme.getLightColorScheme();

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor:
            isDark ? colorScheme.surface : colorScheme.primaryContainer,
        foregroundColor:
            isDark ? colorScheme.onSurface : colorScheme.onPrimaryContainer,
      ),
    );
  }
}
