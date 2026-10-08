// lib/widgets/common_form/voice_web_stub.dart

class WebSpeechHelper {
  static bool get isSupported => false;

  static Object? createRecognition({
    required void Function(String transcript) onResult,
    required void Function(String error) onError,
    required void Function() onEnd,
  }) {
    return null;
  }

  static void start(Object? recognition) {}
  static void stop(Object? recognition) {}
  static void abort(Object? recognition) {}
}
