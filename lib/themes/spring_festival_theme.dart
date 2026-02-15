import 'package:flutter/material.dart';
import '../services/seasonal_theme_service.dart';
import '../widgets/fireworks_effect.dart';

/// 春节主题（动态农历日期）
/// 激活：大年初一前5天 ~ 元宵节（正月十五）
/// 配色：红金
class SpringFestivalTheme extends SeasonalTheme {
  @override
  String get id => 'spring_festival';

  @override
  String get name => '春节';

  @override
  String get emoji => '🧨';

  // 占位值，实际使用 isActiveOn 重写
  @override
  int get startMonth => 1;
  @override
  int get startDay => 1;
  @override
  int get endMonth => 2;
  @override
  int get endDay => 28;

  // 2024~2050年大年初一公历日期查找表
  static final Map<int, DateTime> _lunarNewYearDates = {
    2024: DateTime(2024, 2, 10),
    2025: DateTime(2025, 1, 29),
    2026: DateTime(2026, 2, 17),
    2027: DateTime(2027, 2, 6),
    2028: DateTime(2028, 1, 26),
    2029: DateTime(2029, 2, 13),
    2030: DateTime(2030, 2, 3),
    2031: DateTime(2031, 1, 23),
    2032: DateTime(2032, 2, 11),
    2033: DateTime(2033, 1, 31),
    2034: DateTime(2034, 2, 19),
    2035: DateTime(2035, 2, 8),
    2036: DateTime(2036, 1, 28),
    2037: DateTime(2037, 2, 15),
    2038: DateTime(2038, 2, 4),
    2039: DateTime(2039, 1, 24),
    2040: DateTime(2040, 2, 12),
    2041: DateTime(2041, 2, 1),
    2042: DateTime(2042, 1, 22),
    2043: DateTime(2043, 2, 10),
    2044: DateTime(2044, 1, 30),
    2045: DateTime(2045, 2, 17),
    2046: DateTime(2046, 2, 6),
    2047: DateTime(2047, 1, 26),
    2048: DateTime(2048, 2, 14),
    2049: DateTime(2049, 2, 2),
    2050: DateTime(2050, 1, 23),
  };

  @override
  bool isActiveOn(DateTime date) {
    // 检查当年和前一年的春节（处理跨年情况）
    for (final year in [date.year, date.year - 1]) {
      final newYearDate = _lunarNewYearDates[year];
      if (newYearDate == null) continue;

      final start = newYearDate.subtract(const Duration(days: 5));
      final end = newYearDate
          .add(const Duration(days: 15, hours: 23, minutes: 59, seconds: 59));

      if (!date.isBefore(start) && !date.isAfter(end)) return true;
    }
    return false;
  }

  // 深色模式主色
  static const festivalRed = Color(0xFFD72B2B);
  // 浅色模式主色（亮红）
  static const festivalLightRed = Color.fromARGB(246, 223, 73, 53);
  static const festivalGold = Color(0xFFFFD700);
  static const festivalCrimson = Color(0xFFE54848);
  static const festivalLightCrimson = Color(0xFFFF6B3D);
  static const festivalDarkBg = Color(0xFF1A0808);
  static const festivalLightBg = Color(0xFFFFF7EC);

  @override
  ColorScheme getLightColorScheme() {
    return ColorScheme.light(
      primary: festivalLightRed,
      secondary: festivalGold,
      tertiary: festivalLightCrimson,
      surface: festivalLightBg,
      onPrimary: Colors.white,
      onSecondary: const Color(0xFF1A1A1A),
      primaryContainer: festivalLightRed,
      onPrimaryContainer: Colors.white,
      secondaryContainer: const Color(0xFFFFF0C2),
      onSecondaryContainer: const Color(0xFF7A5B00),
    );
  }

  @override
  ColorScheme getDarkColorScheme() {
    return ColorScheme.dark(
      primary: festivalRed,
      secondary: festivalGold,
      tertiary: festivalCrimson,
      surface: festivalDarkBg,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      primaryContainer: const Color(0xFF5C1018),
      onPrimaryContainer: const Color(0xFFFFDAD6),
      secondaryContainer: const Color(0xFF3D2E00),
      onSecondaryContainer: const Color(0xFFFFE8A0),
    );
  }

  @override
  Widget? buildDecoration(BuildContext context) {
    return const FireworksEffect(
      maxFireworks: 4,
      child: SizedBox.shrink(),
    );
  }

  @override
  Widget? buildAppBarDecoration(BuildContext context) {
    return const SpringFestivalBadge(size: 28);
  }
}
