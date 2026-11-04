import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Ages are typed with at most this many digits on every tab: the same limit
/// the database gives the form-template age fields ('digits:3'), and the
/// backend accepts 1-999.
const int kAgeMaxDigits = 3;

/// How long the "maximum N digits" note stays after a digit is refused.
const Duration kMaxDigitsHintDuration = Duration(seconds: 2);

/// The note shown when a digit past the limit is refused, e.g.
/// "Age: maximum 3 digits".
String maxDigitsHint(String label, int maxDigits) =>
    '$label: maximum $maxDigits digits';

/// Grey (not error-red) style for that note: the value in the field is still
/// valid, only the extra digit was refused.
const TextStyle kMaxDigitsHintStyle =
    TextStyle(fontSize: 11.5, color: AppColors.lightSubText);

/// Gives an age text field digits-only input of at most [maxDigits] digits.
/// Typing more is refused and a grey "<label>: maximum N digits" note shows
/// under the field for [kMaxDigitsHintDuration]. The field itself is never
/// marked as an error, since the digits it keeps are valid.
///
///     AgeDigitsLimit(
///       label: 'Age',
///       builder: (formatters, errorText) => TextFormField(
///         inputFormatters: formatters,
///         decoration: deco.copyWith(errorText: errorText),
///       ),
///     )
///
/// [builder]'s errorText is always null; it stays in the signature so callers
/// that also show their own errors keep working.
class AgeDigitsLimit extends StatefulWidget {
  final String label;
  final int maxDigits;
  final Widget Function(List<TextInputFormatter> formatters, String? errorText)
      builder;

  const AgeDigitsLimit({
    super.key,
    required this.label,
    required this.builder,
    this.maxDigits = kAgeMaxDigits,
  });

  @override
  State<AgeDigitsLimit> createState() => _AgeDigitsLimitState();
}

class _AgeDigitsLimitState extends State<AgeDigitsLimit> {
  final _hint = MaxDigitsHintController();

  @override
  void initState() {
    super.initState();
    _hint.addListener(_onHint);
  }

  void _onHint() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hint.removeListener(_onHint);
    _hint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.builder(
      [
        FilteringTextInputFormatter.digitsOnly,
        _hint.formatter(widget.maxDigits),
      ],
      null,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        if (_hint.visible)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              maxDigitsHint(widget.label, widget.maxDigits),
              style: kMaxDigitsHintStyle,
            ),
          ),
      ],
    );
  }
}

/// Shows the "maximum N digits" note when a digit is refused and hides it
/// again after [kMaxDigitsHintDuration] or on the next accepted edit.
class MaxDigitsHintController extends ChangeNotifier {
  bool _visible = false;
  Timer? _timer;

  bool get visible => _visible;

  /// Keeps at most [maxDigits] digits and shows the note when more were
  /// entered. A typed extra digit is dropped; a pasted longer number keeps
  /// its first [maxDigits] digits rather than being refused whole.
  TextInputFormatter formatter(int maxDigits) =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        final tooLong = newValue.text.length > maxDigits;
        _set(tooLong);
        if (!tooLong) return newValue;
        final kept = newValue.text.substring(0, maxDigits);
        return TextEditingValue(
          text: kept,
          selection: TextSelection.collapsed(offset: kept.length),
        );
      });

  void _set(bool show) {
    _timer?.cancel();
    if (show) _timer = Timer(kMaxDigitsHintDuration, () => _set(false));
    if (_visible != show) {
      _visible = show;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
