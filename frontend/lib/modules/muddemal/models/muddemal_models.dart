// lib/modules/muddemal/models/muddemal_models.dart
// Production data models for Digital Muddemal / Property Management Module.
// All categories, field schemas, dropdowns, and configurations are backend-driven.

class MuddemalCategory {
  final int id;
  final String categoryCode;
  final String categoryName;
  final String? _categoryLabel;
  final bool isActive;
  final int displayOrder;
  final Map<String, dynamic> applicablePropertyRules;
  final int fieldsCount;

  String get categoryLabel {
    final val = _categoryLabel;
    if (val != null && val.trim().isNotEmpty) return val.trim();
    return 'Type of Property';
  }

  const MuddemalCategory({
    required this.id,
    required this.categoryCode,
    required this.categoryName,
    String? categoryLabel,
    required this.isActive,
    required this.displayOrder,
    this.applicablePropertyRules = const {},
    this.fieldsCount = 0,
  }) : _categoryLabel = categoryLabel;

  factory MuddemalCategory.fromJson(Map<String, dynamic> json) {
    return MuddemalCategory(
      id: json['id'] as int? ?? 0,
      categoryCode: json['category_code']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      categoryLabel: json['category_label']?.toString() ?? 'Type of Property',
      isActive: json['is_active'] == true,
      displayOrder: json['display_order'] as int? ?? 0,
      applicablePropertyRules: (json['applicable_property_rules'] is Map)
          ? Map<String, dynamic>.from(json['applicable_property_rules'] as Map)
          : const {},
      fieldsCount: json['fields_count'] as int? ?? 0,
    );
  }
}

class MuddemalPropertyItem {
  final int id;
  final String propertyUid;
  final String? _displayCrNumber;

  String get displayCrNumber {
    final val = _displayCrNumber;
    if (val != null && val.trim().isNotEmpty) {
      return val.trim();
    }
    final rawUid = propertyUid;
    if (rawUid.isNotEmpty) {
      final match = RegExp(r'(CR-[0-9A-Za-z]+/\d{4})').firstMatch(rawUid);
      if (match != null) return match.group(1)!;
      return rawUid;
    }
    final cr = crNumber;
    if (cr.isNotEmpty) {
      return cr.startsWith('CR-') ? cr : 'CR-$cr/2026';
    }
    return '';
  }

  final int muddemalRecordId;
  final String registerNo;
  final String crNumber;
  final String stationName;
  final String sourceModule;
  final String sourceModuleDisplayName;
  final String? sourceCaseId;
  final String sourceCaseNumber;
  final String sourceCaseTitle;
  final String? sourceRecordId;
  final int propertyCategoryId;
  final String categoryCode;
  final String categoryName;
  final String? _categoryLabel;

  String get categoryLabel {
    final val = _categoryLabel;
    if (val != null && val.trim().isNotEmpty) return val.trim();
    return 'Type of Property';
  }

  final int propertySerialNo;
  final String description;
  final double quantity;
  final String unit;
  final double unitValue;
  final double totalItemValue;
  final String valuationStatus;
  final String ownerName;
  final String seizedFrom;
  final String? seizureDate;
  final String? recoveryDate;
  final String propertyStatus;
  final bool fslRequired;
  final String currentCustodyLocation;
  final String fslStatus;
  final String disposalStatus;
  final String remarks;
  final Map<String, dynamic> extraFields;
  final Map<String, dynamic> categoryAttributes;
  final String actSection;
  final String natureOfCrime;
  final String ioName;
  final bool notRecovered;
  final String? fslSentDate;
  final bool fslReportReceived;
  final String? fslReportReceivedDate;
  final String? disposalDate;
  final bool destroyed;
  final bool releasedOnSupurdnama;
  final bool returnedToOwner;
  final List<MuddemalMovementItem> movements;
  final List<MuddemalFSLItem> fslRecords;
  final List<MuddemalDisposalItem> disposals;
  final String? createdAt;
  final String? updatedAt;

  const MuddemalPropertyItem({
    required this.id,
    required this.propertyUid,
    String? displayCrNumber,
    required this.muddemalRecordId,
    required this.registerNo,
    required this.crNumber,
    required this.stationName,
    required this.sourceModule,
    this.sourceModuleDisplayName = '',
    this.sourceCaseId,
    this.sourceCaseNumber = '',
    this.sourceCaseTitle = '',
    this.sourceRecordId,
    required this.propertyCategoryId,
    required this.categoryCode,
    required this.categoryName,
    String? categoryLabel,
    required this.propertySerialNo,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitValue,
    required this.totalItemValue,
    required this.valuationStatus,
    required this.ownerName,
    required this.seizedFrom,
    this.seizureDate,
    this.recoveryDate,
    required this.propertyStatus,
    required this.fslRequired,
    this.currentCustodyLocation = '',
    this.fslStatus = 'Not Required',
    this.disposalStatus = 'In Custody',
    required this.remarks,
    this.extraFields = const {},
    this.categoryAttributes = const {},
    this.actSection = 'IPC / BNS',
    this.natureOfCrime = '',
    this.ioName = '—',
    this.notRecovered = false,
    this.fslSentDate,
    this.fslReportReceived = false,
    this.fslReportReceivedDate,
    this.disposalDate,
    this.destroyed = false,
    this.releasedOnSupurdnama = false,
    this.returnedToOwner = false,
    this.movements = const [],
    this.fslRecords = const [],
    this.disposals = const [],
    this.createdAt,
    this.updatedAt,
  })  : _displayCrNumber = displayCrNumber,
        _categoryLabel = categoryLabel;

  factory MuddemalPropertyItem.fromJson(Map<String, dynamic> json) {
    var rawMovements = json['movements'];
    var rawFsl = json['fsl_records'];
    var rawDisposals = json['disposals'];

    final sm = json['source_module']?.toString() ?? 'manual';
    final smDisplay = json['source_module_display_name']?.toString() ??
        (sm == 'crime'
            ? 'Crime Module'
            : sm == 'prohibition'
                ? 'Prohibition Module'
                : sm == 'gambling'
                    ? 'Gambling Module'
                    : sm == 'ndps'
                        ? 'NDPS Module'
                        : sm == 'theft'
                            ? 'Theft / Burglary'
                            : sm == 'two_four_wheeler'
                                ? 'Vehicle Theft'
                                : sm == 'weapons'
                                    ? 'Arms & Weapons'
                                    : sm.toUpperCase());

    final rawUid = json['property_uid']?.toString() ?? '';
    final crSnap = json['cr_number']?.toString() ?? '';
    String cleanCr = json['display_cr_number']?.toString() ?? '';
    if (cleanCr.isEmpty) {
      final match = RegExp(r'(CR-[0-9A-Za-z]+/\d{4})').firstMatch(rawUid);
      if (match != null) {
        cleanCr = match.group(1)!;
      } else if (crSnap.isNotEmpty) {
        cleanCr = crSnap.startsWith('CR-') ? crSnap : 'CR-$crSnap/2026';
      } else {
        cleanCr = rawUid;
      }
    }

    final rawExtra = (json['category_attributes'] is Map)
        ? Map<String, dynamic>.from(json['category_attributes'] as Map)
        : (json['extra_fields'] is Map
            ? Map<String, dynamic>.from(json['extra_fields'] as Map)
            : const <String, dynamic>{});

    // Cleanly filter out all internal technical keys
    const technicalKeys = {
      'auto_fetched',
      'source_table',
      'last_synced_at',
      'first_synced_at',
      'source_module_id',
      'original_record_id',
      'original_record_reference',
      'source_module_display_name',
      'status_logs',
    };
    final cleanCategoryAttrs = Map<String, dynamic>.from(rawExtra)
      ..removeWhere((k, _) => technicalKeys.contains(k.toLowerCase()));

    return MuddemalPropertyItem(
      id: json['id'] as int? ?? 0,
      propertyUid: rawUid,
      displayCrNumber: cleanCr,
      muddemalRecordId: json['muddemal_record'] as int? ?? 0,
      registerNo: json['register_no']?.toString() ?? '',
      crNumber: json['cr_number']?.toString() ?? '',
      stationName: json['station_name']?.toString() ?? '',
      sourceModule: sm,
      sourceModuleDisplayName: smDisplay,
      sourceCaseId: json['source_case_id']?.toString(),
      sourceCaseNumber: json['source_case_number']?.toString() ?? '',
      sourceCaseTitle: json['source_case_title']?.toString() ?? '',
      sourceRecordId: json['source_record_id']?.toString(),
      propertyCategoryId: json['property_category'] as int? ?? 0,
      categoryCode: json['category_code']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      categoryLabel: json['category_label']?.toString() ?? 'Type of Property',
      propertySerialNo: json['property_serial_no'] as int? ?? 1,
      description: json['description']?.toString() ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      unit: json['unit']?.toString() ?? 'Numbers',
      unitValue: double.tryParse(json['unit_value']?.toString() ?? '0') ?? 0.0,
      totalItemValue:
          double.tryParse(json['total_item_value']?.toString() ?? '0') ?? 0.0,
      valuationStatus: json['valuation_status']?.toString() ?? 'Pending',
      ownerName: json['owner_name']?.toString() ?? '',
      seizedFrom: json['seized_from']?.toString() ?? '',
      seizureDate: json['seizure_date']?.toString(),
      recoveryDate: json['recovery_date']?.toString(),
      propertyStatus: json['property_status']?.toString() ?? 'Seized',
      fslRequired: json['fsl_required'] == true,
      currentCustodyLocation:
          json['current_custody_location']?.toString() ?? '',
      fslStatus: json['fsl_status']?.toString() ??
          (json['fsl_required'] == true ? 'Pending' : 'Not Required'),
      disposalStatus: json['disposal_status']?.toString() ?? 'In Custody',
      remarks: json['remarks']?.toString() ?? '',
      extraFields: (json['extra_fields'] is Map)
          ? Map<String, dynamic>.from(json['extra_fields'] as Map)
          : const {},
      categoryAttributes: cleanCategoryAttrs,
      actSection: json['act_section']?.toString() ?? 'IPC / BNS',
      natureOfCrime: json['nature_of_crime']?.toString() ?? '',
      ioName: json['io_name']?.toString() ?? '—',
      notRecovered: json['not_recovered'] == true ||
          json['property_status'] == 'Stolen – Not Recovered',
      fslSentDate: json['fsl_sent_date']?.toString(),
      fslReportReceived: json['fsl_report_received'] == true,
      fslReportReceivedDate: json['fsl_report_received_date']?.toString(),
      disposalDate: json['disposal_date']?.toString(),
      destroyed:
          json['destroyed'] == true || json['property_status'] == 'Destroyed',
      releasedOnSupurdnama: json['released_on_supurdnama'] == true ||
          json['property_status'] == 'Released on Supurdnama',
      returnedToOwner: json['returned_to_owner'] == true ||
          json['property_status'] == 'Returned to Owner',
      movements: (rawMovements is List)
          ? rawMovements
              .whereType<Map>()
              .map((m) =>
                  MuddemalMovementItem.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      fslRecords: (rawFsl is List)
          ? rawFsl
              .whereType<Map>()
              .map(
                  (m) => MuddemalFSLItem.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      disposals: (rawDisposals is List)
          ? rawDisposals
              .whereType<Map>()
              .map((m) =>
                  MuddemalDisposalItem.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class MuddemalRegisterHeader {
  final int id;
  final String registerNo;
  final String policeStationId;
  final String stationName;
  final String? crCaseId;
  final String crNumberSnapshot;
  final String registrationDate;
  final String? ioId;
  final String? ioName;
  final String recordStatus;
  final String remarks;
  final int propertiesCount;
  final Map<String, dynamic> valuations;
  final List<MuddemalPropertyItem> properties;

  const MuddemalRegisterHeader({
    required this.id,
    required this.registerNo,
    required this.policeStationId,
    required this.stationName,
    this.crCaseId,
    required this.crNumberSnapshot,
    required this.registrationDate,
    this.ioId,
    this.ioName,
    required this.recordStatus,
    required this.remarks,
    this.propertiesCount = 0,
    this.valuations = const {},
    this.properties = const [],
  });

  factory MuddemalRegisterHeader.fromJson(Map<String, dynamic> json) {
    var rawProps = json['properties'];
    return MuddemalRegisterHeader(
      id: json['id'] as int? ?? 0,
      registerNo: json['muddemal_register_no']?.toString() ?? '',
      policeStationId: json['police_station_id']?.toString() ?? '',
      stationName: json['station_name']?.toString() ?? '',
      crCaseId: json['cr_case']?.toString(),
      crNumberSnapshot: json['cr_number_snapshot']?.toString() ?? '',
      registrationDate: json['registration_date']?.toString() ?? '',
      ioId: json['investigating_officer_id']?.toString(),
      ioName: json['investigating_officer_name']?.toString(),
      recordStatus: json['record_status']?.toString() ?? 'Active',
      remarks: json['remarks']?.toString() ?? '',
      propertiesCount: json['properties_count'] as int? ?? 0,
      valuations: (json['valuations'] is Map)
          ? Map<String, dynamic>.from(json['valuations'] as Map)
          : const {},
      properties: (rawProps is List)
          ? rawProps
              .whereType<Map>()
              .map((m) =>
                  MuddemalPropertyItem.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
    );
  }
}

class MuddemalMovementItem {
  final int id;
  final String fromLocation;
  final String toLocation;
  final String movementType;
  final String movementDate;
  final String responsibleOfficer;
  final String referenceNo;
  final String remarks;
  final String? createdBy;

  const MuddemalMovementItem({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.movementType,
    required this.movementDate,
    required this.responsibleOfficer,
    required this.referenceNo,
    required this.remarks,
    this.createdBy,
  });

  factory MuddemalMovementItem.fromJson(Map<String, dynamic> json) {
    return MuddemalMovementItem(
      id: json['id'] as int? ?? 0,
      fromLocation: json['from_location']?.toString() ?? '',
      toLocation: json['to_location']?.toString() ?? '',
      movementType: json['movement_type']?.toString() ?? '',
      movementDate: json['movement_date']?.toString() ?? '',
      responsibleOfficer: json['responsible_officer']?.toString() ?? '',
      referenceNo: json['reference_no']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      createdBy: json['created_by']?.toString(),
    );
  }
}

class MuddemalFSLItem {
  final int id;
  final String fslReferenceNo;
  final String dispatchDate;
  final String dispatchDetails;
  final String reportReceivedStatus;
  final String? reportReceivedDate;
  final String reportReference;
  final String remarks;

  const MuddemalFSLItem({
    required this.id,
    required this.fslReferenceNo,
    required this.dispatchDate,
    required this.dispatchDetails,
    required this.reportReceivedStatus,
    this.reportReceivedDate,
    required this.reportReference,
    required this.remarks,
  });

  factory MuddemalFSLItem.fromJson(Map<String, dynamic> json) {
    return MuddemalFSLItem(
      id: json['id'] as int? ?? 0,
      fslReferenceNo: json['fsl_reference_no']?.toString() ?? '',
      dispatchDate: json['dispatch_date']?.toString() ?? '',
      dispatchDetails: json['dispatch_details']?.toString() ?? '',
      reportReceivedStatus:
          json['report_received_status']?.toString() ?? 'Pending',
      reportReceivedDate: json['report_received_date']?.toString(),
      reportReference: json['report_reference']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
    );
  }
}

class MuddemalDisposalItem {
  final int id;
  final String disposalType;
  final String courtOrderReference;
  final String? orderDate;
  final String disposalDate;
  final String authorizationDetails;
  final String remarks;
  final Map<String, dynamic> ownerRecipientDetails;
  final Map<String, dynamic> supurdnamaDetails;

  const MuddemalDisposalItem({
    required this.id,
    required this.disposalType,
    required this.courtOrderReference,
    this.orderDate,
    required this.disposalDate,
    required this.authorizationDetails,
    required this.remarks,
    this.ownerRecipientDetails = const {},
    this.supurdnamaDetails = const {},
  });

  factory MuddemalDisposalItem.fromJson(Map<String, dynamic> json) {
    return MuddemalDisposalItem(
      id: json['id'] as int? ?? 0,
      disposalType: json['disposal_type']?.toString() ?? '',
      courtOrderReference: json['court_order_reference']?.toString() ?? '',
      orderDate: json['order_date']?.toString(),
      disposalDate: json['disposal_date']?.toString() ?? '',
      authorizationDetails: json['authorization_details']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      ownerRecipientDetails: (json['owner_recipient_details'] is Map)
          ? Map<String, dynamic>.from(json['owner_recipient_details'] as Map)
          : const {},
      supurdnamaDetails: (json['supurdnama_details'] is Map)
          ? Map<String, dynamic>.from(json['supurdnama_details'] as Map)
          : const {},
    );
  }
}

class DiscoveredSourceProperty {
  final String sourceModule;
  final String sourceRecordId;
  final String title;
  final String description;
  final String seizedFrom;
  final double quantity;
  final String unit;
  final double totalItemValue;
  final String inferredCategoryCode;
  final bool isAlreadyLinked;
  final String? linkedPropertyUid;
  final int? linkedPropertyId;
  final String rawSource;

  const DiscoveredSourceProperty({
    required this.sourceModule,
    required this.sourceRecordId,
    required this.title,
    required this.description,
    required this.seizedFrom,
    required this.quantity,
    required this.unit,
    required this.totalItemValue,
    required this.inferredCategoryCode,
    required this.isAlreadyLinked,
    this.linkedPropertyUid,
    this.linkedPropertyId,
    required this.rawSource,
  });

  factory DiscoveredSourceProperty.fromJson(Map<String, dynamic> json) {
    return DiscoveredSourceProperty(
      sourceModule: json['source_module']?.toString() ?? '',
      sourceRecordId: json['source_record_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      seizedFrom: json['seized_from']?.toString() ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      unit: json['unit']?.toString() ?? 'Numbers',
      totalItemValue:
          double.tryParse(json['total_item_value']?.toString() ?? '0') ?? 0.0,
      inferredCategoryCode:
          json['inferred_category_code']?.toString() ?? 'SEIZED_PROPERTY',
      isAlreadyLinked: json['is_already_linked'] == true,
      linkedPropertyUid: json['linked_property_uid']?.toString(),
      linkedPropertyId: json['linked_property_id'] as int?,
      rawSource: json['raw_source']?.toString() ?? '',
    );
  }
}

class MuddemalDashboardTab {
  final String key;
  final String label;
  final String badgeColor;
  final int displayOrder;
  final List<String> applicableStatuses;

  const MuddemalDashboardTab({
    required this.key,
    required this.label,
    required this.badgeColor,
    required this.displayOrder,
    this.applicableStatuses = const [],
  });

  factory MuddemalDashboardTab.fromJson(Map<String, dynamic> json) {
    return MuddemalDashboardTab(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      badgeColor: json['badge_color']?.toString() ?? '#2563EB',
      displayOrder: json['display_order'] as int? ?? 0,
      applicableStatuses: (json['applicable_statuses'] is List)
          ? (json['applicable_statuses'] as List)
              .map((e) => e.toString())
              .toList()
          : const [],
    );
  }
}

class MuddemalDisposalAuthority {
  final String code;
  final String label;
  final int displayOrder;

  const MuddemalDisposalAuthority({
    required this.code,
    required this.label,
    required this.displayOrder,
  });

  factory MuddemalDisposalAuthority.fromJson(Map<String, dynamic> json) {
    return MuddemalDisposalAuthority(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }
}

class MuddemalFslReportStatus {
  final String code;
  final String label;
  final String color;

  const MuddemalFslReportStatus({
    required this.code,
    required this.label,
    required this.color,
  });

  factory MuddemalFslReportStatus.fromJson(Map<String, dynamic> json) {
    return MuddemalFslReportStatus(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      color: json['color']?.toString() ?? '#6B7280',
    );
  }
}

class MuddemalFslRegionalLab {
  final String code;
  final String name;

  const MuddemalFslRegionalLab({
    required this.code,
    required this.name,
  });

  factory MuddemalFslRegionalLab.fromJson(Map<String, dynamic> json) {
    return MuddemalFslRegionalLab(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
