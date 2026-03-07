import 'package:flutter/material.dart';

// ── 5-colour palette ─────────────────────────────────────────────────────────
// Dark palette (original)
const _dCharcoal = Color(0xFF1e2820);
const _dMoss     = Color(0xFF3d5a2e);
const _dLeaf     = Color(0xFF5c8a3c);
const _dLime     = Color(0xFFa8c96e);
const _dCream    = Color(0xFFf5f0e8);

// Light palette
const _lBackground = Color(0xFFF4F8F0); // very light minty white
const _lCard       = Color(0xFFFFFFFF); // pure white cards
const _lLeaf       = Color(0xFF4A7A30); // darker green (readable on white)
const _lLime       = Color(0xFF5c8a3c); // medium green accents
const _lText       = Color(0xFF1A2417); // near-black text

// ── ThemeExtension for custom palette ────────────────────────────────────────
class AppColors extends ThemeExtension<AppColors> {
  final Color charcoal; // scaffold / main background
  final Color moss;     // card / secondary background
  final Color leaf;     // primary accent green
  final Color lime;     // bright lime / highlights
  final Color cream;    // text / icon colour

  const AppColors({
    required this.charcoal,
    required this.moss,
    required this.leaf,
    required this.lime,
    required this.cream,
  });

  static const dark = AppColors(
    charcoal: _dCharcoal,
    moss:     _dMoss,
    leaf:     _dLeaf,
    lime:     _dLime,
    cream:    _dCream,
  );

  static const light = AppColors(
    charcoal: _lBackground,
    moss:     _lCard,
    leaf:     _lLeaf,
    lime:     _lLime,
    cream:    _lText,
  );

  @override
  AppColors copyWith({Color? charcoal, Color? moss, Color? leaf, Color? lime, Color? cream}) {
    return AppColors(
      charcoal: charcoal ?? this.charcoal,
      moss:     moss     ?? this.moss,
      leaf:     leaf     ?? this.leaf,
      lime:     lime     ?? this.lime,
      cream:    cream    ?? this.cream,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      charcoal: Color.lerp(charcoal, other.charcoal, t)!,
      moss:     Color.lerp(moss,     other.moss,     t)!,
      leaf:     Color.lerp(leaf,     other.leaf,     t)!,
      lime:     Color.lerp(lime,     other.lime,     t)!,
      cream:    Color.lerp(cream,    other.cream,    t)!,
    );
  }
}

// ── Convenient extension on BuildContext ─────────────────────────────────────
extension AppColorsExt on BuildContext {
  AppColors get ac => Theme.of(this).extension<AppColors>()!;
}

// ── ThemeData factory ─────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark  => _build(AppColors.dark,  Brightness.dark);

  static ThemeData _build(AppColors c, Brightness b) {
    final isDark = b == Brightness.dark;
    return ThemeData(
      brightness: b,
      scaffoldBackgroundColor: c.charcoal,
      extensions: [c],
      colorScheme: ColorScheme(
        brightness: b,
        primary:          c.leaf,
        onPrimary:        c.moss,
        secondary:        c.lime,
        onSecondary:      c.charcoal,
        error:            Colors.redAccent,
        onError:          Colors.white,
        surface:          c.moss,
        onSurface:        c.cream,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.leaf,
        foregroundColor: isDark ? _dCream : Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDark ? _dCream : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        iconTheme: IconThemeData(color: isDark ? _dCream : Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.leaf,
          foregroundColor: isDark ? _dCream : Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF263320) : const Color(0xFFEEF5E8),
        labelStyle: TextStyle(color: c.lime),
        hintStyle: TextStyle(color: c.cream.withOpacity(0.45)),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: c.lime, width: 0.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: c.lime, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: c.lime, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? _dCharcoal : Colors.white,
        selectedItemColor: c.lime,
        unselectedItemColor: c.cream.withOpacity(0.5),
      ),
      cardTheme: CardThemeData(
        color: c.moss,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: c.lime.withOpacity(0.18)),
        ),
      ),
      dividerColor: c.cream.withOpacity(0.1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.lime),
    );
  }
}
