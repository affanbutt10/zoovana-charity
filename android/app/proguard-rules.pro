# shared_preferences_android calls its Kotlin suspend APIs through Dart JNI.
# The jni package looks these runtime types and members up by their original
# names, so R8 must not rename or remove them in release builds.
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
