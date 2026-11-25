# Regles R8 / ProGuard pour Otaku Verse (Android Gradle Plugin 9 + R8 Full Mode)
# Empeche R8 de supprimer les constructeurs utilises par reflexion par Firebase

-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
    public java.util.List getComponents();
}

# Conserver Firebase Crashlytics et les informations de ligne pour les rapports de crash
-keep class com.google.firebase.crashlytics.** { *; }
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keepattributes *Annotation*

# Conserver les enregistreurs de plugins Flutter Firebase
-keep class io.flutter.plugins.firebase.** { *; }
