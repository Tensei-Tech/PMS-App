// lib/modules/accidental_death/providers/accidental_death_provider.dart
import '../../core/providers/base_module_provider.dart';

/// Accidental Death (अकस्मात मृत्यू / मर्ग) Provider.
/// Named accidental_death_provider to prevent browser ad-blockers (e.g. uBlock Origin)
/// from blocking the HTTP resource as an advertisement provider.
class AdProvider extends BaseModuleProvider {
  AdProvider() : super('ad');
}

typedef AccidentalDeathProvider = AdProvider;
