import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Ages are typed with at most this many digits on every tab: the same limit
/// the database gives the form-template age fields ('digits:3'), and the
/// backend accepts 1-999.
const int kAgeMaxDigits = 3;

/// Gives an age text field digits-only input of at most [maxDigits] digits.
/// Typing more is refused and "<label> can be at most N digits" is shown (as
/// the field's errorText) until the next edit, like the form-template fields.
///
///     AgeDigitsLimit(
///       label: 'Age',
///       builder: (formatters, errorText) => TextFormField(
///         inputFormatters: formatters,
///         decoration: deco.copyWith(errorText: errorText),
///       ),
///     )
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
  bool _tooLong = false;

  void _setTooLong(bool value) {
    if (_tooLong != value) setState(() => _tooLong = value);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction((oldValue, newValue) {
          final tooLong = newValue.text.length > widget.maxDigits;
          _setTooLong(tooLong);
          return tooLong ? oldValue : newValue;
        }),
      ],
      _tooLong
          ? '${widget.label} can be at most ${widget.maxDigits} digits'
          : null,
    );
  }
}
