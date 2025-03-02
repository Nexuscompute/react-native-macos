diff --git a/ReactAndroid/src/main/jni/react/jni/Android.mk b/ReactAndroid/src/main/jni/react/jni/Android.mk
index 38a51019e..7425e65a5 100644
--- a/ReactAndroid/src/main/jni/react/jni/Android.mk
+++ b/ReactAndroid/src/main/jni/react/jni/Android.mk
@@ -128,6 +128,7 @@ $(call import-module,callinvoker)
 $(call import-module,reactperflogger)
 $(call import-module,hermes)
 $(call import-module,runtimeexecutor)
+$(call import-module,v8jsi)
 $(call import-module,react/nativemodule/core)
 
 include $(REACT_SRC_DIR)/reactperflogger/jni/Android.mk
@@ -148,3 +149,4 @@ include $(REACT_SRC_DIR)/jscexecutor/Android.mk
 include $(REACT_SRC_DIR)/../hermes/reactexecutor/Android.mk
 include $(REACT_SRC_DIR)/../hermes/instrumentation/Android.mk
 include $(REACT_SRC_DIR)/modules/blob/jni/Android.mk
+include $(REACT_SRC_DIR)/v8executor/Android.mk
