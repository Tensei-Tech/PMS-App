import 'package:speech_to_text/speech_to_text.dart' as stt;

stt.SpeechToText? _speech;

void startWebVoiceRecognition(
  void Function(String text, bool isFinal) onResult,
  void Function(String status, String message) onStatus, {
  String lang = 'en-IN',
}) async {
  try {
    _speech ??= stt.SpeechToText();

    if (_speech!.isListening) {
      await _speech!.stop();
    }

    final available = await _speech!.initialize(
      onError: (error) {
        onStatus('error', error.errorMsg);
      },
      onStatus: (status) {
        if (status == 'listening') {
          onStatus('listening', 'Listening… Speak into your mic now!');
        } else if (status == 'notListening' || status == 'done') {
          onStatus('ended', 'Ended');
        }
      },
    );

    if (!available) {
      onStatus('unsupported',
          'Speech recognition not available or microphone permission denied');
      return;
    }

    onStatus('listening', 'Listening… Speak into your mic now!');

    final normalizedLocale = lang.replaceAll('-', '_');

    await _speech!.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
        localeId: normalizedLocale,
      ),
    );
  } catch (e) {
    onStatus('error', 'Error initializing voice: $e');
  }
}

void stopWebVoiceRecognition() {
  try {
    if (_speech?.isListening == true) {
      _speech?.stop();
    }
  } catch (_) {}
}
