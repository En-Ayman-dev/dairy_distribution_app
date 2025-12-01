// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'app_colors.dart';

// // Helper utilities to safely use GoogleFonts without triggering runtime fetches
// // when `GoogleFonts.config.allowRuntimeFetching` is false. This avoids runtime
// // network requests and runtime exceptions on restricted/offline environments.
// TextTheme _safeInterTextTheme([TextTheme? base]) {
//   try {
//     if (GoogleFonts.config.allowRuntimeFetching) {
//       return GoogleFonts.interTextTheme(base);
//     }
//   } catch (_) {
//     // Fall through to returning base below on any error.
//   }
//   return base ?? const TextTheme();
// }

// TextStyle _safeInterTextStyle({double? fontSize, FontWeight? fontWeight, Color? color}) {
//   try {
//     if (GoogleFonts.config.allowRuntimeFetching) {
//       return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color);
//     }
//   } catch (_) {
//     // Fall back to plain TextStyle below
//   }
//   return TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
// }

// class AppTheme {
//   static ThemeData get lightTheme {
//     return ThemeData(
//       useMaterial3: true,
//       colorScheme: ColorScheme.fromSeed(
//         seedColor: AppColors.primary,
//         brightness: Brightness.light,
//       ),
//   textTheme: _safeInterTextTheme(),
//       appBarTheme: AppBarTheme(
//         elevation: 0,
//         centerTitle: true,
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         titleTextStyle: _safeInterTextStyle(
//           fontSize: 20,
//           fontWeight: FontWeight.w700,
//           color: Colors.white,
//         ),
//       ),
//       cardTheme: CardThemeData(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         filled: true,
//         fillColor: Colors.grey[50],
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           textStyle: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//       ),
//       floatingActionButtonTheme: FloatingActionButtonThemeData(
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//       ),
//     );
//   }

//   static ThemeData get darkTheme {
//     return ThemeData(
//       useMaterial3: true,
//       colorScheme: ColorScheme.fromSeed(
//         seedColor: AppColors.primary,
//         brightness: Brightness.dark,
//       ),
//   textTheme: _safeInterTextTheme(ThemeData.dark().textTheme),
//       appBarTheme: AppBarTheme(
//         elevation: 0,
//         centerTitle: true,
//         titleTextStyle: _safeInterTextStyle(
//           fontSize: 20,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//       cardTheme: CardThemeData(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }
// }
