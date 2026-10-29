// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

StreamSubscription<html.Event>? _resultSub;
StreamSubscription<html.Event>? _statusSub;

void startWebVoiceRecognition(
  void Function(String text, bool isFinal) onResult,
  void Function(String status, String message) onStatus, {
  String lang = 'en-IN',
}) {
  try {
    _resultSub?.cancel();
    _statusSub?.cancel();

    _resultSub = html.window.on['voice_result'].listen((event) {
      if (event is html.CustomEvent && event.detail != null) {
        final text = event.detail['text']?.toString() ?? '';
        final isFinal = event.detail['isFinal'] == true;
        onResult(text, isFinal);
      }
    });

    _statusSub = html.window.on['voice_status'].listen((event) {
      if (event is html.CustomEvent && event.detail != null) {
        final status = event.detail['status']?.toString() ?? '';
        final message = event.detail['message']?.toString() ?? '';
        onStatus(status, message);
      }
    });

    // Call JavaScript voiceRecognizer.start(lang)
    if (js.context.hasProperty('voiceRecognizer')) {
      final recognizer = js.context['voiceRecognizer'];
      if (recognizer != null) {
        recognizer.callMethod('start', [lang]);
      }
    }
  } catch (e) {
    onStatus('error', 'Error initializing voice: $e');
  }
}

void stopWebVoiceRecognition() {
  try {
    _resultSub?.cancel();
    _resultSub = null;
    _statusSub?.cancel();
    _statusSub = null;

    if (js.context.hasProperty('voiceRecognizer')) {
      final recognizer = js.context['voiceRecognizer'];
      if (recognizer != null) {
        recognizer.callMethod('stop', []);
      }
    }
  } catch (_) {}
}
