import '../../core/models/base_record.dart';
import '../../core/providers/base_module_provider.dart';

class PreventiveProvider extends BaseModuleProvider {
  PreventiveProvider() : super('preventive');

  @override
  List<ModuleRecord> getFilteredRecords(String? subCategory) {
    if (subCategory == null ||
        subCategory.trim().isEmpty ||
        subCategory == 'All' ||
        subCategory.toLowerCase() == 'preventive') {
      return records;
    }
    final matched = records.where((r) => r.subCategory == subCategory).toList();
    return matched.isNotEmpty ? matched : records;
  }

  @override
  int getFilteredTotalCount(String? subCategory) {
    return getFilteredRecords(subCategory).length;
  }
}
