// lib/widgets/common_form/voice_web_impl.dart
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe' as js_util;
import 'package:web/web.dart' as web;

class WebSpeechHelper {
  static bool get isSupported {
    try {
      final win = web.window as js.JSObject;
      return win.has('webkitSpeechRecognition') || win.has('SpeechRecognition');
    } catch (_) {
      return false;
    }
  }

  static Object? createRecognition({
    required void Function(String transcript) onResult,
    required void Function(String error) onError,
    required void Function() onEnd,
  }) {
    try {
      final win = web.window as js.JSObject;
      final hasWebkit = win.has('webkitSpeechRecognition');
      final speechClass = (hasWebkit
          ? win.getProperty('webkitSpeechRecognition'.toJS)
          : win.getProperty('SpeechRecognition'.toJS)) as js.JSFunction;

      final recognition = speechClass.callAsConstructor<js.JSObject>();
      recognition.setProperty('continuous'.toJS, true.toJS);
      recognition.setProperty('interimResults'.toJS, true.toJS);
      recognition.setProperty('lang'.toJS, 'en-IN'.toJS);

      recognition.setProperty(
        'onresult'.toJS,
        ((js.JSObject event) {
          final results = event.getProperty('results'.toJS) as js.JSObject;
          final length =
              (results.getProperty('length'.toJS) as js.JSNumber).toDartInt;

          String transcript = '';
          for (int i = 0; i < length; i++) {
            final resItem =
                results.getProperty(i.toString().toJS) as js.JSObject;
            final alt0 = resItem.getProperty('0'.toJS) as js.JSObject;
            final str =
                (alt0.getProperty('transcript'.toJS) as js.JSString).toDart;
            transcript += '$str ';
          }
          onResult(transcript.trim());
        }).toJS,
      );

      recognition.setProperty(
        'onerror'.toJS,
        ((js.JSObject error) {
          final errStr = error.has('error')
              ? (error.getProperty('error'.toJS) as js.JSString).toDart
              : '';
          onError(errStr);
        }).toJS,
      );

      recognition.setProperty(
        'onend'.toJS,
        ((js.JSObject _) {
          onEnd();
        }).toJS,
      );

      return recognition;
    } catch (e) {
      onError(e.toString());
      return null;
    }
  }

  static void start(Object? recognition) {
    if (recognition == null) return;
    try {
      final rec = recognition as js.JSObject;
      rec.callMethod('start'.toJS);
    } catch (_) {}
  }

  static void stop(Object? recognition) {
    if (recognition == null) return;
    try {
      final rec = recognition as js.JSObject;
      rec.setProperty('onend'.toJS, null);
      rec.callMethod('stop'.toJS);
    } catch (_) {}
  }

  static void abort(Object? recognition) {
    if (recognition == null) return;
    try {
      final rec = recognition as js.JSObject;
      rec.setProperty('onend'.toJS, null);
      rec.callMethod('abort'.toJS);
    } catch (_) {}
  }
}
