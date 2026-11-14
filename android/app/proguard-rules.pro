# Release builds use R8 full mode, which drops default constructors that are
# only kept by "-keep class" rules. WorkManager (pulled in by Google Mobile
# Ads) creates its Room database by reflection, so keep those constructors,
# or the app crashes on start with "Failed to create an instance of
# androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
