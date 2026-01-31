-keepattributes Exceptions,InnerClasses,Signature,Deprecated,*Annotation*,EnclosingMethod

# ==================== 阿里云一键登录 SDK 混淆规则 ====================

# 【关键配置】禁止优化（防止 R8 移除 super.onCreate() 调用）
-dontoptimize

# 保持调试信息（帮助定位问题）
-keepattributes SourceFile,LineNumberTable

# 【核心保护】完全保护阿里云 SDK 的三个 Activity（不混淆、不优化、不收缩）
-keep class com.mobile.auth.gatewayauth.LoginAuthActivity {
    *;
}

-keep class com.cmic.sso.sdk.activity.LoginAuthActivity {
    *;
}

-keep class com.mobile.auth.gatewayauth.activity.AuthWebVeiwActivity {
    *;
}

# 保护阿里云一键登录 SDK 所有类
-keep class com.mobile.auth.** { *; }
-keep class com.cmic.sso.** { *; }
-keep class com.unicom.** { *; }
-keep class com.ct.** { *; }

# 保护所有 Activity 的生命周期方法
-keepclassmembers class * extends android.app.Activity {
    protected void onCreate(android.os.Bundle);
    protected void onStart();
    protected void onResume();
    protected void onPause();
    protected void onStop();
    protected void onDestroy();
}

# 保护 Activity 构造函数
-keepclasseswithmembers class * extends android.app.Activity {
    <init>(...);
}

# 保护阿里云 SDK 内部使用的反射类
-keepclassmembers class * {
    @com.alibaba.fastjson.annotation.JSONField *;
    @com.alibaba.fastjson2.annotation.JSONField *;
}

# 保护 Fastjson（阿里云 SDK 依赖）
-keep class com.alibaba.fastjson.** { *; }
-keep class com.alibaba.fastjson2.** { *; }
-dontwarn com.alibaba.fastjson.**
-dontwarn com.alibaba.fastjson2.**

# 保护运营商 SDK 的本地方法
-keepclasseswithmembernames class * {
    native <methods>;
}