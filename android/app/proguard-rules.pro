-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class * extends androidx.room.RoomDatabase$Callback { *; }

# mobile_scanner / ML Kit barcode scanning. R8 otherwise strips the
# dynamically loaded barcode detector, crashing the camera in release builds.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.odml.** { *; }
-dontwarn com.google.android.odml.**
