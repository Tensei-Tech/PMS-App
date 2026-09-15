// lib/widgets/common_form/pocso_voice_banner.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe' as js_util;
import 'package:web/web.dart' as web;

import '../../utils/speech_accuracy_engine.dart';

class PocsoVoiceBanner extends StatefulWidget {
  final String? activeFieldLabel;
  final String? activeSectionName;
  final TextEditingController? activeController;
  final VoidCallback? onNextField;
  final VoidCallback? onPreviousField;
  final VoidCallback? onClearField;

  const PocsoVoiceBanner({
    super.key,
    this.activeFieldLabel,
    this.activeSectionName,
    this.activeController,
    this.onNextField,
    this.onPreviousField,
    this.onClearField,
  });

  @override
  State<PocsoVoiceBanner> createState() => _PocsoVoiceBannerState();
}

class _PocsoVoiceBannerState extends State<PocsoVoiceBanner>
    with SingleTickerProviderStateMixin {
  stt.SpeechToText? _speech;
  Object? _webRecognition;
  bool _isListening = false;
  bool _userWantsListening = false;
  String _liveTranscript = '';
  late AnimationController _animController;

  TextEditingController? _trackedController;
  bool _isApplyingSpeechText = false;
  String _baselinePrefix = '';
  String _baselineSuffix = '';
  TextSelection? _lastSelection;

  @override
  void initState() {
    super.initState();
    _attachController(widget.activeController);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _attachController(TextEditingController? newCtrl) {
    if (_trackedController == newCtrl) {
      _captureBaseline();
      return;
    }
    _trackedController?.removeListener(_onControllerChanged);
    _trackedController = newCtrl;
    _trackedController?.addListener(_onControllerChanged);
    _captureBaseline();
  }

  void _onControllerChanged() {
    if (_isApplyingSpeechText) return;
    final ctrl = _trackedController;
    if (ctrl == null) return;

    final currentSel = ctrl.selection;
    if (_lastSelection != currentSel) {
      _lastSelection = currentSel;
      _captureBaseline();
      if (_userWantsListening) {
        if (kIsWeb) {
          _restartWebSpeech();
        } else {
          _restartNativeSpeech();
        }
      }
    }
  }

  void _captureBaseline() {
    final ctrl = _trackedController;
    if (ctrl == null) {
      _baselinePrefix = '';
      _baselineSuffix = '';
      return;
    }
    final fullText = ctrl.text;
    final sel = ctrl.selection;
    if (sel.isValid &&
        sel.start >= 0 &&
        sel.end >= 0 &&
        sel.start <= fullText.length &&
        sel.end <= fullText.length) {
      _baselinePrefix = fullText.substring(0, sel.start);
      _baselineSuffix = fullText.substring(sel.end);
    } else {
      _baselinePrefix = fullText;
      _baselineSuffix = '';
    }
  }

  void _applyNormalizedText(String normalized) {
    if (_trackedController == null || normalized.isEmpty) return;
    final ctrl = _trackedController!;

    _isApplyingSpeechText = true;
    try {
      final prefix = _baselinePrefix;
      final suffix = _baselineSuffix;

      String spaceBefore = '';
      if (prefix.isNotEmpty &&
          !prefix.endsWith(' ') &&
          !prefix.endsWith('\n') &&
          !normalized.startsWith(' ') &&
          !RegExp(r'^[,.\-/?!:;]').hasMatch(normalized)) {
        spaceBefore = ' ';
      }

      String spaceAfter = '';
      if (suffix.isNotEmpty &&
          !suffix.startsWith(' ') &&
          !suffix.startsWith('\n') &&
          !suffix.startsWith(RegExp(r'^[,.\-/?!:;]')) &&
          !normalized.endsWith(' ')) {
        spaceAfter = ' ';
      }

      final newText = '$prefix$spaceBefore$normalized$spaceAfter$suffix';
      final newCursorPos =
          (prefix.length + spaceBefore.length + normalized.length)
              .clamp(0, newText.length);

      ctrl.text = newText;
      ctrl.selection = TextSelection.collapsed(offset: newCursorPos);
      _lastSelection = ctrl.selection;
    } finally {
      _isApplyingSpeechText = false;
    }
  }

  @override
  void didUpdateWidget(PocsoVoiceBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeController != oldWidget.activeController) {
      _attachController(widget.activeController);
      _liveTranscript = '';
      if (_userWantsListening) {
        if (kIsWeb) {
          _restartWebSpeech();
        } else {
          _restartNativeSpeech();
        }
      }
    }
  }

  @override
  void dispose() {
    _userWantsListening = false;
    _trackedController?.removeListener(_onControllerChanged);
    _animController.dispose();
    _stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    _captureBaseline();
    _userWantsListening = true;
    if (kIsWeb) {
      _startWebSpeech();
    } else {
      await _startNativeSpeech();
    }
  }

  Future<void> _stopListening() async {
    _userWantsListening = false;
    if (kIsWeb) {
      _stopWebSpeech();
    } else {
      await _stopNativeSpeech();
    }
  }

  void _restartWebSpeech() {
    try {
      if (_webRecognition != null) {
        final rec = _webRecognition as js.JSObject;
        rec.setProperty('onend'.toJS, null);
        rec.callMethod('abort'.toJS);
        _webRecognition = null;
      }
    } catch (_) {}
    if (_userWantsListening) {
      _startWebSpeech();
    }
  }

  Future<void> _restartNativeSpeech() async {
    try {
      await _speech?.stop();
    } catch (_) {}
    if (_userWantsListening) {
      await _startNativeSpeech();
    }
  }

  // ── Web Implementation via Native Chrome Web Speech API ───────────────────
  void _startWebSpeech() {
    try {
      final win = web.window as js.JSObject;
      final hasWebkit = win.has('webkitSpeechRecognition');
      final hasStandard = win.has('SpeechRecognition');

      if (!hasWebkit && !hasStandard) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition is not supported in this browser. Please use Chrome/Edge.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final speechClass = (hasWebkit
          ? win.getProperty('webkitSpeechRecognition'.toJS)
          : win.getProperty('SpeechRecognition'.toJS)) as js.JSFunction;

      final recognition = speechClass.callAsConstructor<js.JSObject>();
      recognition.setProperty('continuous'.toJS, true.toJS);
      recognition.setProperty('interimResults'.toJS, true.toJS);
      recognition.setProperty('lang'.toJS, 'en-IN'.toJS);

      recognition.setProperty('onresult'.toJS, ((js.JSObject event) {
        final results = event.getProperty('results'.toJS) as js.JSObject;
        final length = (results.getProperty('length'.toJS) as js.JSNumber).toDartInt;

        String transcript = '';
        for (int i = 0; i < length; i++) {
          final resItem = results.getProperty(i.toString().toJS) as js.JSObject;
          final alt0 = resItem.getProperty('0'.toJS) as js.JSObject;
          final str = (alt0.getProperty('transcript'.toJS) as js.JSString).toDart;
          transcript += '$str ';
        }

        transcript = transcript.trim();

        if (transcript.isNotEmpty) {
          final normalized = SpeechAccuracyEngine.normalize(
            transcript,
            fieldLabel: widget.activeFieldLabel,
            sectionName: widget.activeSectionName,
          );

          if (mounted && normalized.isNotEmpty) {
            setState(() {
              _liveTranscript = normalized;
            });
            if (widget.activeController != null) {
              _applyNormalizedText(normalized);
            }
          }
        }
      }).toJS);

      recognition.setProperty('onerror'.toJS, ((js.JSObject error) {
        final errStr = error.has('error')
            ? (error.getProperty('error'.toJS) as js.JSString).toDart
            : '';
        if (errStr == 'aborted' || errStr == 'no-speech') {
          return;
        }
        if (errStr == 'not-allowed' || errStr == 'service-not-allowed') {
          if (mounted) {
            setState(() {
              _isListening = false;
              _userWantsListening = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Microphone permission denied.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }).toJS);

      recognition.setProperty('onend'.toJS, (() {
        if (mounted && _userWantsListening) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _userWantsListening) {
              try {
                recognition.callMethod('start'.toJS);
                if (!_isListening) {
                  setState(() => _isListening = true);
                }
              } catch (_) {
                if (_userWantsListening) {
                  _restartWebSpeech();
                }
              }
            }
          });
        } else {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      }).toJS);

      _webRecognition = recognition;
      recognition.callMethod('start'.toJS);

      setState(() {
        _isListening = true;
        _liveTranscript = '';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _userWantsListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start microphone: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _stopWebSpeech() {
    _userWantsListening = false;
    try {
      if (_webRecognition != null) {
        final rec = _webRecognition as js.JSObject;
        rec.setProperty('onend'.toJS, null);
        rec.callMethod('stop'.toJS);
        _webRecognition = null;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  // ── Native (Android/iOS/Desktop) Implementation ───────────────────────────
  Future<void> _startNativeSpeech() async {
    try {
      _speech ??= stt.SpeechToText();
      final hasInit = await _speech!.initialize(
        onError: (_) {
          if (mounted && !_userWantsListening) setState(() => _isListening = false);
        },
        onStatus: (val) {
          if (mounted) {
            if (val == 'done' || val == 'notListening') {
              if (_userWantsListening) {
                _restartNativeSpeech();
              } else {
                setState(() => _isListening = false);
              }
            }
          }
        },
      );

      if (!hasInit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission or Speech Recognition not available.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      setState(() {
        _isListening = true;
        _liveTranscript = '';
      });

      await _speech!.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            final normalized = SpeechAccuracyEngine.normalize(
              words,
              fieldLabel: widget.activeFieldLabel,
              sectionName: widget.activeSectionName,
            );
            if (mounted && normalized.isNotEmpty) {
              setState(() {
                _liveTranscript = normalized;
              });
              if (widget.activeController != null) {
                _applyNormalizedText(normalized);
              }
            }
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          localeId: 'en_IN',
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _stopNativeSpeech() async {
    _userWantsListening = false;
    try {
      await _speech?.stop();
    } catch (_) {}
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _clearActiveField() {
    _baselinePrefix = '';
    _baselineSuffix = '';
    _lastSelection = null;
    if (widget.activeController != null) {
      widget.activeController!.clear();
    }
    setState(() {
      _liveTranscript = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0F766E);
    const bgLight = Color(0xFFF8FAFC);
    const borderCol = Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isListening ? const Color(0xFF10B981) : borderCol,
          width: _isListening ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isListening
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Title + Controls in one sleek top row ──
          Row(
            children: [
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? const Color(0xFF10B981).withValues(
                              alpha: 0.2 + 0.3 * _animController.value)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? const Color(0xFF047857) : const Color(0xFF475569),
                      size: 16,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Live Voice Dictation',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isListening ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isListening ? 'MIC ON' : 'STANDBY',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _isListening ? const Color(0xFF15803D) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Start / Stop Voice Button
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: _isListening ? _stopListening : _startListening,
                  icon: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 15,
                  ),
                  label: Text(
                    _isListening ? 'Stop Voice' : 'Start Voice',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Clear Field Button
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: _clearActiveField,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: borderCol),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.backspace_outlined, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Active Field & Live Speech Preview ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.center_focus_strong, size: 14, color: primaryTeal),
                const SizedBox(width: 6),
                Text(
                  '${(widget.activeFieldLabel != null && widget.activeFieldLabel!.isNotEmpty) ? widget.activeFieldLabel : 'Active Field'}: ',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Expanded(
                  child: Text(
                    _liveTranscript.isNotEmpty
                        ? _liveTranscript
                        : (widget.activeController?.text.isNotEmpty == true
                            ? widget.activeController!.text
                            : 'Listening... Speak to type here'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: (_liveTranscript.isNotEmpty ||
                              widget.activeController?.text.isNotEmpty == true)
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                      fontStyle: (_liveTranscript.isEmpty &&
                              widget.activeController?.text.isEmpty != false)
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
