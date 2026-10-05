# Enables core library desugaring (needed by flutter_local_notifications) in the generated Gradle file.
import os, re, sys
for name in ["android/app/build.gradle", "android/app/build.gradle.kts"]:
    if not os.path.exists(name):
        continue
    s = open(name).read()
    kts = name.endswith(".kts")
    if "desugar" in s.lower():
        print("already patched"); sys.exit(0)
    flag = "isCoreLibraryDesugaringEnabled = true" if kts else "coreLibraryDesugaringEnabled true"
    s, n = re.subn(r"compileOptions\s*\{", "compileOptions {\n        " + flag, s, count=1)
    if n == 0:
        s = re.sub(r"android\s*\{", "android {\n    compileOptions {\n        " + flag + "\n    }", s, count=1)
    dep = 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")' if kts else "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'"
    s += "\ndependencies {\n    " + dep + "\n}\n"
    open(name, "w").write(s)
    print("patched", name); sys.exit(0)
print("gradle file not found"); sys.exit(1)
