# R8 / ProGuard keep rules for the release build.
#
# ML Kit text recognition (CNIC OCR, Latin script only):
# google_mlkit_text_recognition references the Chinese, Japanese, Korean
# and Devanagari script recognizers, which live in separate optional ML Kit
# artifacts that are NOT bundled with the Latin recognizer. R8 fails the
# release build on these missing classes (e.g. ChineseTextRecognizerOptions),
# although they are never called. Keep the entry points that are actually
# used and silence the warnings for the unbundled script models.

-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google.mlkit.vision.text.**
