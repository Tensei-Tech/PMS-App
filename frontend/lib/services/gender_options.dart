import 'dynamic_options_service.dart';

/// Gender choices from the database (/api/options/gender/), cached for the
/// session by [DynamicOptionsService]. Empty until the first load finishes.
class GenderOptions {
  static const String route = '/api/options/gender/';

  /// The loaded list, right away (empty before the first [load])
  static List<String> get cached =>
      DynamicOptionsService().getCachedOptions(route) ?? const [];

  static Future<List<String>> load() =>
      DynamicOptionsService().fetchOptions(route);

  /// [value] if it is one of [options], else null (a dropdown's initial value
  /// must be one of its items)
  static String? pick(String? value, List<String> options) =>
      value != null && options.contains(value) ? value : null;
}
