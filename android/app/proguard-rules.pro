# Keep AndroidX Startup and WorkManager components used by Google Mobile Ads
-keep class androidx.startup.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn androidx.startup.**
-dontwarn androidx.work.**
