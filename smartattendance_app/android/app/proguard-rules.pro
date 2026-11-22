# Reglas R8 / ProGuard seguras para BuenTiempo (Flutter + ML Kit + SQLite + Camera)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google ML Kit Face Detection
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**

# SQLite / Flutter Secure Storage / Google Sign-In
-keep class com.tekartik.sqflite.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.android.gms.auth.** { *; }
