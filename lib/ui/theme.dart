import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

const _expressiveRadius = BorderRadius.all(Radius.circular(32));
const _largeRadius = BorderRadius.all(Radius.circular(24));
const _mediumRadius = BorderRadius.all(Radius.circular(18));

@immutable
class PointThemeScheme {
  const PointThemeScheme({
    required this.id,
    required this.name,
    required this.seed,
    required this.icon,
  });

  final String id;
  final String name;
  final Color seed;
  final IconData icon;
}

const pointThemeSchemes = [
  PointThemeScheme(
    id: 'violet',
    name: 'Violet',
    seed: Color(0xFF6E56CF),
    icon: Icons.auto_awesome_rounded,
  ),
  PointThemeScheme(
    id: 'indigo',
    name: 'Indigo',
    seed: Color(0xFF3451B2),
    icon: Icons.blur_on_rounded,
  ),
  PointThemeScheme(
    id: 'teal',
    name: 'Teal',
    seed: Color(0xFF007C80),
    icon: Icons.water_rounded,
  ),
  PointThemeScheme(
    id: 'emerald',
    name: 'Emerald',
    seed: Color(0xFF2E7D32),
    icon: Icons.eco_rounded,
  ),
  PointThemeScheme(
    id: 'rose',
    name: 'Rose',
    seed: Color(0xFFC2185B),
    icon: Icons.favorite_rounded,
  ),
  PointThemeScheme(
    id: 'coral',
    name: 'Coral',
    seed: Color(0xFFD45D40),
    icon: Icons.local_fire_department_rounded,
  ),
  PointThemeScheme(
    id: 'amber',
    name: 'Amber',
    seed: Color(0xFFB7791F),
    icon: Icons.wb_sunny_rounded,
  ),
  PointThemeScheme(
    id: 'graphite',
    name: 'Graphite',
    seed: Color(0xFF56616B),
    icon: Icons.contrast_rounded,
  ),
];

final _colorSchemeCache = <String, ColorScheme>{};
final _themeCache = <String, ThemeData>{};

PointThemeScheme pointThemeSchemeById(String id) {
  for (final scheme in pointThemeSchemes) {
    if (scheme.id == id) return scheme;
  }
  return pointThemeSchemes.first;
}

ColorScheme pointColorScheme(Brightness brightness, String schemeId) {
  final themeScheme = pointThemeSchemeById(schemeId);
  final key = '${brightness.name}:${themeScheme.id}';
  return _colorSchemeCache.putIfAbsent(
    key,
    () => ColorScheme.fromSeed(
      seedColor: themeScheme.seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    ),
  );
}

ThemeData pointTheme(Brightness brightness, String schemeId) {
  final themeScheme = pointThemeSchemeById(schemeId);
  final key = '${brightness.name}:${themeScheme.id}';
  return _themeCache.putIfAbsent(
    key,
    () => _buildPointTheme(brightness, themeScheme.id),
  );
}

ThemeData _buildPointTheme(Brightness brightness, String schemeId) {
  final scheme = pointColorScheme(brightness, schemeId);
  final base = ThemeData(
    colorScheme: scheme,
    brightness: scheme.brightness,
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    useMaterial3: true,
  );
  final splashFactory = switch (defaultTargetPlatform) {
    TargetPlatform.android => InkSparkle.splashFactory,
    _ => InkRipple.splashFactory,
  };

  return base.copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: _expressiveText(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.headlineSmall?.copyWith(
        fontWeight: .w800,
        color: scheme.onSurface,
        letterSpacing: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: _expressiveRadius),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: _expressiveRadius),
      titleTextStyle: base.textTheme.headlineSmall?.copyWith(
        fontWeight: .w800,
        color: scheme.onSurface,
        letterSpacing: 0,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      showDragHandle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: .w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: .w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: .w800),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
        minimumSize: const Size.square(44),
        padding: const EdgeInsets.all(10),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: base.textTheme.bodyLarge?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      border: const OutlineInputBorder(
        borderRadius: _mediumRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: _mediumRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _mediumRadius,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      minLeadingWidth: 40,
      shape: const RoundedRectangleBorder(borderRadius: _largeRadius),
      titleTextStyle: base.textTheme.bodyLarge?.copyWith(
        fontWeight: .w700,
        color: scheme.onSurface,
      ),
      subtitleTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      iconColor: scheme.onSurfaceVariant,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.onPrimary;
        return scheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return scheme.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.transparent;
        return scheme.outlineVariant;
      }),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: const StadiumBorder(),
        selectedBackgroundColor: scheme.secondaryContainer,
        selectedForegroundColor: scheme.onSecondaryContainer,
        foregroundColor: scheme.onSurface,
        textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: .w800),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      elevation: 0,
      height: 76,
      labelTextStyle: WidgetStatePropertyAll(
        base.textTheme.labelMedium?.copyWith(fontWeight: .w700),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: scheme.onSecondaryContainer, size: 26);
        }
        return IconThemeData(color: scheme.onSurfaceVariant, size: 24);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      elevation: 0,
      groupAlignment: -0.7,
      selectedLabelTextStyle: base.textTheme.labelMedium?.copyWith(
        fontWeight: .w800,
        color: scheme.onSecondaryContainer,
      ),
      unselectedLabelTextStyle: base.textTheme.labelMedium?.copyWith(
        fontWeight: .w600,
        color: scheme.onSurfaceVariant,
      ),
      selectedIconTheme: IconThemeData(
        color: scheme.onSecondaryContainer,
        size: 26,
      ),
      unselectedIconTheme: IconThemeData(
        color: scheme.onSurfaceVariant,
        size: 24,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
        fontWeight: .w600,
      ),
      shape: const RoundedRectangleBorder(borderRadius: _largeRadius),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.secondaryContainer,
      checkmarkColor: scheme.onSecondaryContainer,
      labelStyle: base.textTheme.labelLarge?.copyWith(fontWeight: .w700),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      circularTrackColor: scheme.surfaceContainerHighest,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: .6),
      thickness: 1,
      space: 1,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: ShapeDecoration(
        color: scheme.inverseSurface,
        shape: const StadiumBorder(),
      ),
      textStyle: base.textTheme.labelMedium?.copyWith(
        color: scheme.onInverseSurface,
        fontWeight: .w700,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      shape: const RoundedRectangleBorder(borderRadius: _largeRadius),
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 1,
      highlightElevation: 0,
    ),
    splashFactory: splashFactory,
    splashColor: scheme.primary.withValues(alpha: .12),
    highlightColor: scheme.primary.withValues(alpha: .08),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values)
          p: const FadeThroughPageTransitionsBuilder(),
      },
    ),
  );
}

TextTheme _expressiveText(TextTheme base) => base.copyWith(
  displayLarge: base.displayLarge?.copyWith(
    fontWeight: .w800,
    letterSpacing: 0,
  ),
  displayMedium: base.displayMedium?.copyWith(
    fontWeight: .w800,
    letterSpacing: 0,
  ),
  displaySmall: base.displaySmall?.copyWith(
    fontWeight: .w800,
    letterSpacing: 0,
  ),
  headlineLarge: base.headlineLarge?.copyWith(
    fontWeight: .w800,
    letterSpacing: 0,
  ),
  headlineMedium: base.headlineMedium?.copyWith(
    fontWeight: .w800,
    letterSpacing: 0,
  ),
  headlineSmall: base.headlineSmall?.copyWith(
    fontWeight: .w800,
    letterSpacing: 0,
  ),
  titleLarge: base.titleLarge?.copyWith(fontWeight: .w800, letterSpacing: 0),
  titleMedium: base.titleMedium?.copyWith(fontWeight: .w700, letterSpacing: 0),
  titleSmall: base.titleSmall?.copyWith(fontWeight: .w700, letterSpacing: 0),
  bodyLarge: base.bodyLarge?.copyWith(
    fontWeight: .w400,
    height: 1.5,
    letterSpacing: 0,
  ),
  bodyMedium: base.bodyMedium?.copyWith(
    fontWeight: .w400,
    height: 1.4,
    letterSpacing: 0,
  ),
  bodySmall: base.bodySmall?.copyWith(
    fontWeight: .w400,
    height: 1.3,
    letterSpacing: 0,
  ),
  labelLarge: base.labelLarge?.copyWith(fontWeight: .w800, letterSpacing: 0),
  labelMedium: base.labelMedium?.copyWith(fontWeight: .w700, letterSpacing: 0),
  labelSmall: base.labelSmall?.copyWith(fontWeight: .w700, letterSpacing: 0),
);
