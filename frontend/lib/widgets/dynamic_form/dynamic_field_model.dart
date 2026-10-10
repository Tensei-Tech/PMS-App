// lib/widgets/dynamic_form/dynamic_field_model.dart
// Unified metadata model reflecting the Database-driven Dynamic Smart Form Engine.

class DynamicFieldDef {
  final int fieldDefId;
  final String fieldLabel;
  final String fieldKey;
  final String fieldSource; // 'common' or 'custom'
  final String
      fieldType; // 'text', 'textarea', 'number', 'date', 'datetime', 'dropdown', 'checkbox', 'radio', 'chips', 'file'
  final bool isRequired;
  final int displayOrder;
  final List<String> options;
  final String? section;
  final String? dependsOnFieldKey;
  final String? dependsOnValue;
  final String? optionsSource;

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
  });

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
    );
  }

  factory DynamicFieldDef.fromJson(Map<String, dynamic> json) {
    return DynamicFieldDef(
      fieldDefId: (json['field_def_id'] ?? json['id']) as int? ?? 0,
      fieldLabel: json['field_label']?.toString() ?? '',
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
    this.genders = const ['Male', 'Female', 'Other'],
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
          : const ['Male', 'Female', 'Other'],
      proceduralItems: (json['procedural_items'] is Map)
          ? (json['procedural_items'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
    );
  }
}
