# ==================== Potato Timer 应用混淆规则 ====================

# Flutter 相关保护
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保护 Flutter 插件注册类
-keep class io.flutter.embedding.engine.plugins.** { *; }

# 保护项目的主 Activity
-keep class com.guoyangtuo.potatoclock1.MainActivity { *; }

# 保护所有 Activity 和 Fragment 的生命周期方法
-keepclassmembers class * extends android.app.Activity {
    public void onCreate(android.os.Bundle);
    public void onStart();
    public void onResume();
    public void onPause();
    public void onStop();
    public void onDestroy();
}

-keepclassmembers class * extends androidx.fragment.app.Fragment {
    public void onCreate(android.os.Bundle);
    public void onCreateView(android.view.LayoutInflater, android.view.ViewGroup, android.os.Bundle);
}

# 保护 Parcelable 实现
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# 保护序列化类
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 保护枚举类型
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保护注解
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# 保护行号信息（方便调试崩溃日志）
-keepattributes SourceFile,LineNumberTable

# 保护泛型签名
-keepattributes Signature

# 移除日志（可选，减小 APK 体积）
# -assumenosideeffects class android.util.Log {
#     public static *** d(...);
#     public static *** v(...);
#     public static *** i(...);
# }

# ==================== Google Play Core (可选功能) ====================
# 忽略 Play Store 动态模块相关的缺失类（这些是可选功能）
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

