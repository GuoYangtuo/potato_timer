-keepattributes Exceptions,InnerClasses,Signature,Deprecated,*Annotation*,EnclosingMethod

# ==================== 阿里云一键登录 SDK 混淆规则 ====================

# 保护阿里云一键登录 SDK 核心类
-keep class com.mobile.auth.** { *; }
-keep class com.cmic.sso.** { *; }
-keep class com.unicom.** { *; }
-keep class com.ct.** { *; }

# 保护阿里云 SDK 的授权页 Activity（关键！）
-keep public class com.mobile.auth.gatewayauth.LoginAuthActivity { *; }
-keep public class com.cmic.sso.sdk.activity.LoginAuthActivity { *; }
-keep public class com.mobile.auth.gatewayauth.activity.AuthWebVeiwActivity { *; }

# 保护所有 Activity 的生命周期方法（防止被优化移除 super.onCreate() 等调用）
-keepclassmembers class * extends android.app.Activity {
    public void onCreate(android.os.Bundle);
    public void onStart();
    public void onResume();
    public void onPause();
    public void onStop();
    public void onDestroy();
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