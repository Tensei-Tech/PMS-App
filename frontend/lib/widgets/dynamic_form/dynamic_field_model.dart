// lib/widgets/dynamic_form/dynamic_field_model.dart
// Unified metadata model reflecting the Database-driven Dynamic Smart Form Engine.

class DynamicFieldDef {
  final int fieldDefId;
  final String fieldLabel;
  final String fieldKey;
  final String fieldSource; // 'common' or 'custom'
  final String
      fieldType; // 'text', 'textarea', 'number', 'date', 'datetime', 'dropdown', 'checkbox', 'radio', 'chips', 'file', 'multi_select', 'repeating_group'
  final bool isRequired;
  final int displayOrder;
  final List<String> options;
  final String? section;
  final String? dependsOnFieldKey;
  final String? dependsOnValue;
  final String? optionsSource;
  final String? parentFieldKey;

  const DynamicFieldDef({
    required this.fieldDefId,
    required this.fieldLabel,
    required this.fieldKey,
    required this.fieldSource,
    required this.fieldType,
    required this.isRequired,
    required this.displayOrder,
    this.options = const [],
    this.section,
    this.dependsOnFieldKey,
    this.dependsOnValue,
    this.optionsSource,
    this.parentFieldKey,
  });

  static const String sumSourcePrefix = 'sum:';

  /// Field keys this number field is the total of: options source
  /// `sum:<field_key>,<field_key>` (filled automatically, not typed in).
  List<String> get sumOf {
    final src = optionsSource ?? '';
    if (fieldType != 'number' || !src.startsWith(sumSourcePrefix)) {
      return const [];
    }
    return src
        .substring(sumSourcePrefix.length)
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static const String maxDigitsPrefix = 'digits:';

  /// Most digits a number field accepts: options source `digits:<n>` (e.g.
  /// `digits:3` on age fields); trying to type more shows a message.
  int? get maxDigits {
    final src = optionsSource ?? '';
    if (fieldType != 'number' || !src.startsWith(maxDigitsPrefix)) {
      return null;
    }
    final n = int.tryParse(src.substring(maxDigitsPrefix.length).trim());
    return n != null && n > 0 ? n : null;
  }

  static const String maxWordsPrefix = 'words:';

  /// Most words a text field accepts: options source `words:<n>` (e.g.
  /// `words:20` on a short description); typing more words is blocked.
  int? get maxWords {
    final src = optionsSource ?? '';
    if ((fieldType != 'text' && fieldType != 'textarea') ||
        !src.startsWith(maxWordsPrefix)) {
      return null;
    }
    final n = int.tryParse(src.substring(maxWordsPrefix.length).trim());
    return n != null && n > 0 ? n : null;
  }

  static const String maxItemsPrefix = 'max:';

  /// Most rows a repeating group may hold: options source `max:<n>`
  /// (e.g. `max:1` keeps a single row with no Add / Remove buttons).
  int? get maxItems {
    final src = optionsSource ?? '';
    if (fieldType != 'repeating_group' || !src.startsWith(maxItemsPrefix)) {
      return null;
    }
    final n = int.tryParse(src.substring(maxItemsPrefix.length).trim());
    return n != null && n > 0 ? n : null;
  }

  static const String stepperSourcePrefix = 'stepper';

  /// Whether this number field has a stepper with (- 1 +) increment/decrement buttons.
  bool get isStepper {
    final src = (optionsSource ?? '').toLowerCase().trim();
    return fieldType == 'number' &&
        (src == stepperSourcePrefix || src.startsWith('$stepperSourcePrefix:'));
  }

  DynamicFieldDef copyWith({
    int? fieldDefId,
    String? fieldLabel,
    String? fieldKey,
    String? fieldSource,
    String? fieldType,
    bool? isRequired,
    int? displayOrder,
    List<String>? options,
    String? section,
    String? dependsOnFieldKey,
    String? dependsOnValue,
    String? optionsSource,
    String? parentFieldKey,
  }) {
    return DynamicFieldDef(
      fieldDefId: fieldDefId ?? this.fieldDefId,
      fieldLabel: fieldLabel ?? this.fieldLabel,
      fieldKey: fieldKey ?? this.fieldKey,
      fieldSource: fieldSource ?? this.fieldSource,
      fieldType: fieldType ?? this.fieldType,
      isRequired: isRequired ?? this.isRequired,
      displayOrder: displayOrder ?? this.displayOrder,
      options: options ?? this.options,
      section: section ?? this.section,
      dependsOnFieldKey: dependsOnFieldKey ?? this.dependsOnFieldKey,
      dependsOnValue: dependsOnValue ?? this.dependsOnValue,
      optionsSource: optionsSource ?? this.optionsSource,
      parentFieldKey: parentFieldKey ?? this.parentFieldKey,
    );
  }

  factory DynamicFieldDef.fromJson(Map<String, dynamic> json) {
    var rawLabel = json['field_label']?.toString() ?? '';
    final lowerLabel = rawLabel.toLowerCase().trim();
    if (lowerLabel == 'crime spot full address' ||
        lowerLabel == 'spot full address' ||
        lowerLabel == 'crime spot address') {
      rawLabel = 'Address';
    }
    return DynamicFieldDef(
      fieldDefId: (json['field_def_id'] ?? json['id']) as int? ?? 0,
      fieldLabel: rawLabel,
      fieldKey: json['field_key']?.toString() ?? '',
      fieldSource: json['field_source']?.toString() ?? 'common',
      fieldType: json['field_type']?.toString().toLowerCase() ?? 'text',
      isRequired: json['is_required'] == true,
      displayOrder: json['display_order'] as int? ?? 0,
      options: (json['options'] is List)
          ? (json['options'] as List).map((e) => e.toString()).toList()
          : const [],
      section: json['section']?.toString(),
      dependsOnFieldKey: json['depends_on_field_key']?.toString(),
      dependsOnValue: json['depends_on_value']?.toString(),
      optionsSource: json['options_source']?.toString(),
      parentFieldKey: json['parent_field_key']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'field_def_id': fieldDefId,
        'field_label': fieldLabel,
        'field_key': fieldKey,
        'field_source': fieldSource,
        'field_type': fieldType,
        'is_required': isRequired,
        'display_order': displayOrder,
        'options': options,
        'section': section,
        'depends_on_field_key': dependsOnFieldKey,
        'depends_on_value': dependsOnValue,
        'options_source': optionsSource,
        'parent_field_key': parentFieldKey,
      };
}

class DynamicFormDefinition {
  final int categoryId;
  final String categoryName;
  final String? categoryCode;
  final int? groupId;
  final bool hasLinkedBundle;
  final bool hasCommonFormBaseline;
  final List<DynamicFieldDef> fields;
  final Map<String, dynamic> actsSections;
  final List<String> preventiveItems;
  final List<String> genders;
  final Map<String, String> proceduralItems;

  const DynamicFormDefinition({
    required this.categoryId,
    required this.categoryName,
    this.categoryCode,
    this.groupId,
    this.hasLinkedBundle = true,
    this.hasCommonFormBaseline = false,
    required this.fields,
    this.actsSections = const {},
    this.preventiveItems = const [],
    this.genders = const [],
    this.proceduralItems = const {},
  });

  factory DynamicFormDefinition.fromJson(Map<String, dynamic> json) {
    final rawFields = (json['fields'] is List)
        ? (json['fields'] as List)
            .whereType<Map>()
            .map((m) => DynamicFieldDef.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <DynamicFieldDef>[];

    // Sort by display order
    rawFields.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return DynamicFormDefinition(
      categoryId: json['category_id'] as int? ?? 0,
      categoryName: json['category_name']?.toString() ?? '',
      categoryCode: json['category_code']?.toString(),
      groupId: json['group_id'] as int?,
      hasLinkedBundle:
          json['has_linked_bundle'] as bool? ?? rawFields.isNotEmpty,
      hasCommonFormBaseline: json['has_common_form_baseline'] as bool? ?? false,
      fields: rawFields,
      actsSections: (json['acts_sections'] is Map)
          ? Map<String, dynamic>.from(json['acts_sections'] as Map)
          : const {},
      preventiveItems: (json['preventive_items'] is List)
          ? (json['preventive_items'] as List).map((e) => e.toString()).toList()
          : const [],
      genders: (json['genders'] is List)
          ? (json['genders'] as List).map((e) => e.toString()).toList()
          : const [],
      proceduralItems: (json['procedural_items'] is Map)
          ? (json['procedural_items'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
    );
  }
}

/// Whether a parent field's current value opens a dependent field
/// (depends_on_value from field_template_fields).
/// - empty target: any non-empty, non-false value
/// - "A|B": any of the listed values
/// - list / multi-select / comma-separated value: contains the target
/// - Yes / true / 1 are treated alike
bool dependsOnValueMatches(dynamic rawVal, String? dependsOnValue,
    {bool parentIsMultiSelect = false}) {
  final targetVal = dependsOnValue?.trim() ?? '';
  final currentStr = rawVal?.toString().trim() ?? '';

  if (targetVal.isEmpty) {
    return currentStr.isNotEmpty &&
        currentStr.toLowerCase() != 'false' &&
        currentStr != '0';
  }

  final targets = targetVal
      .split('|')
      .map((t) => t.trim().toLowerCase())
      .where((t) => t.isNotEmpty)
      .toSet();

  if (rawVal is List) {
    return rawVal
        .any((item) => targets.contains(item.toString().trim().toLowerCase()));
  }
  if (parentIsMultiSelect ||
      (currentStr.startsWith('[') && currentStr.endsWith(']')) ||
      currentStr.contains(',')) {
    final cleaned = currentStr.replaceAll(RegExp(r'^\[|\]$'), '');
    if (cleaned
        .split(',')
        .any((s) => targets.contains(s.trim().toLowerCase()))) {
      return true;
    }
  }

  final current = currentStr.toLowerCase();
  if (targets.contains(current)) return true;

  bool truthy(String v) => v == 'true' || v == '1' || v == 'yes';
  return truthy(current) && targets.any(truthy);
}
