import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

const _seed = Color(0xFF6750A4);

const _expressiveRadius = BorderRadius.all(Radius.circular(28));
const _largeRadius = BorderRadius.all(Radius.circular(20));
const _mediumRadius = BorderRadius.all(Radius.circular(16));

ThemeData pointTheme(Brightness brightness, [ColorScheme? dynamicScheme]) {
  final scheme = dynamicScheme ??
      ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final base = ThemeData(
    colorScheme: scheme,
    brightness: scheme.brightness,
    useMaterial3: true,
  );

  return base.copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: _expressiveText(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.headlineSmall?.copyWith(
        fontWeight: .w800,
        color: scheme.onSurface,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerHigh,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: _expressiveRadius),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: _expressiveRadius),
      titleTextStyle: base.textTheme.headlineSmall?.copyWith(
        fontWeight: .w800,
        color: scheme.onSurface,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: .w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: .w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: .w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: const RoundedRectangleBorder(borderRadius: _largeRadius),
      titleTextStyle: base.textTheme.bodyLarge?.copyWith(
        fontWeight: .w600,
        color: scheme.onSurface,
      ),
      subtitleTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
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
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: const StadiumBorder(),
        selectedBackgroundColor: scheme.secondaryContainer,
        selectedForegroundColor: scheme.onSecondaryContainer,
        foregroundColor: scheme.onSurface,
        textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: .w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.secondaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        base.textTheme.labelMedium?.copyWith(fontWeight: .w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: scheme.onSecondaryContainer,
            size: 24,
          );
        }
        return IconThemeData(color: scheme.onSurfaceVariant, size: 24);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.secondaryContainer,
      elevation: 0,
      selectedLabelTextStyle: base.textTheme.labelMedium?.copyWith(
        fontWeight: .w800,
        color: scheme.onSecondaryContainer,
      ),
      unselectedLabelTextStyle: base.textTheme.labelMedium?.copyWith(
        fontWeight: .w500,
        color: scheme.onSurfaceVariant,
      ),
      selectedIconTheme: IconThemeData(
        color: scheme.onSecondaryContainer,
        size: 24,
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
      ),
      shape: const RoundedRectangleBorder(borderRadius: _largeRadius),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: scheme.surfaceContainerHighest,
      labelStyle: base.textTheme.labelLarge?.copyWith(fontWeight: .w600),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    splashFactory: InkSparkle.splashFactory,
    splashColor: scheme.primary.withValues(alpha: .12),
    highlightColor: scheme.primary.withValues(alpha: .08),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values)
          p: const CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

TextTheme _expressiveText(TextTheme base) => base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: .w800,
        letterSpacing: -1.0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: .w800,
        letterSpacing: -0.5,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: .w800,
        letterSpacing: -0.25,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: .w800,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: .w700,
        letterSpacing: -0.25,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: .w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: .w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: .w600,
        letterSpacing: 0.1,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: .w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: .w400,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontWeight: .w400,
        height: 1.4,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontWeight: .w400,
        height: 1.3,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: .w700,
        letterSpacing: 0.5,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: .w600,
        letterSpacing: 0.5,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: .w600,
        letterSpacing: 0.5,
      ),
    );
