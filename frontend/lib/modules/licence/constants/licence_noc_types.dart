// lib/modules/licence/constants/licence_noc_types.dart

class LicenceNocOption {
  final int number;
  final String name;

  const LicenceNocOption({
    required this.number,
    required this.name,
  });

  /// Example: "Arms Licence"
  String get displayName => name;

  /// Example: "1. Arms Licence"
  String get numberedName => '$number. $name';

  /// Example: "1 Arms Licence"
  String get rawLabel => '$number $name';

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LicenceNocOption &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          name == other.name;

  @override
  int get hashCode => number.hashCode ^ name.hashCode;
}

/// The official list of 37 Police Licence / NOC / Verification types
const List<LicenceNocOption> kLicenceNocOptions = [
  LicenceNocOption(number: 1, name: 'Arms Licence'),
  LicenceNocOption(number: 2, name: 'Beer Bar / Permit Room NOC'),
  LicenceNocOption(number: 3, name: 'Wine Shop NOC'),
  LicenceNocOption(number: 4, name: 'Firecracker Sale Licence / NOC'),
  LicenceNocOption(number: 5, name: 'Foreign Liquor Shop NOC'),
  LicenceNocOption(number: 6, name: 'Country Liquor Shop NOC'),
  LicenceNocOption(number: 7, name: 'Beer Shoppee NOC'),
  LicenceNocOption(number: 8, name: 'Liquor Bar / Restaurant NOC'),
  LicenceNocOption(number: 9, name: 'Hotel / Lodge NOC'),
  LicenceNocOption(number: 10, name: 'Eating House / Restaurant NOC'),
  LicenceNocOption(number: 11, name: 'Cinema Theatre NOC'),
  LicenceNocOption(number: 12, name: 'Amusement / Entertainment Premises NOC'),
  LicenceNocOption(
      number: 13, name: 'Public Performance / Loudspeaker Permission'),
  LicenceNocOption(number: 14, name: 'Procession / Rally Permission'),
  LicenceNocOption(number: 15, name: 'Public Meeting / Event Permission'),
  LicenceNocOption(number: 16, name: 'Temporary Festival / Mandap Permission'),
  LicenceNocOption(number: 17, name: 'Petrol Pump NOC'),
  LicenceNocOption(number: 18, name: 'Explosives Storage / Handling NOC'),
  LicenceNocOption(number: 19, name: 'Gas Agency / LPG Storage NOC'),
  LicenceNocOption(number: 20, name: 'Money-Lending Business Verification'),
  LicenceNocOption(
      number: 21, name: 'Private Security Agency Police Verification'),
  LicenceNocOption(
      number: 22, name: 'Character and Antecedent Verification for Licence'),
  LicenceNocOption(
      number: 23,
      name:
          'Pawn Broker / Gold Loan Business Police Verification, where applicable'),
  LicenceNocOption(
      number: 24,
      name:
          'Cyber Café / Internet Café Police Verification, where locally required'),
  LicenceNocOption(number: 25, name: 'Other Licence / NOC'),
  LicenceNocOption(number: 26, name: 'Cinema / Theatre Licence Verification'),
  LicenceNocOption(
      number: 27, name: 'Video Parlour / Amusement Parlour Licence'),
  LicenceNocOption(
      number: 28, name: 'Loudspeaker Permission / Contractor Licence'),
  LicenceNocOption(number: 29, name: 'Fireworks Display Permission'),
  LicenceNocOption(number: 30, name: 'Temporary Liquor Licence for Events'),
  LicenceNocOption(
      number: 31, name: 'Public Entertainment / Performance Licence'),
  LicenceNocOption(number: 32, name: 'Stage / Event Structure NOC'),
  LicenceNocOption(number: 33, name: 'Ticket-Selling Permission for Events'),
  LicenceNocOption(number: 34, name: 'Private Security Agency Verification'),
  LicenceNocOption(number: 35, name: 'Renewal of Existing Licence / NOC'),
  LicenceNocOption(number: 36, name: 'Licence Amendment / Change of Premises'),
  LicenceNocOption(number: 38, name: 'Other Police Verification / NOC'),
];

/// Helper to match any string representation to a known LicenceNocOption
LicenceNocOption? findLicenceNocOption(String? input) {
  if (input == null) return null;
  final clean = input.trim().toLowerCase();
  if (clean.isEmpty) return null;

  for (final opt in kLicenceNocOptions) {
    if (opt.name.toLowerCase() == clean ||
        opt.numberedName.toLowerCase() == clean ||
        opt.displayName.toLowerCase() == clean ||
        opt.rawLabel.toLowerCase() == clean) {
      return opt;
    }
  }

  // Also check without number prefix e.g. "1. Arms Licence" or "1 Arms Licence" -> "Arms Licence"
  final stripped = clean.replaceFirst(RegExp(r'^\d+[\.\-\)\s]+'), '').trim();
  if (stripped.isNotEmpty) {
    for (final opt in kLicenceNocOptions) {
      if (opt.name.toLowerCase() == stripped) {
        return opt;
      }
    }
  }

  // Check prefix matches e.g. "Money-Lending Business Verificati"
  if (clean.startsWith('money-lending business verificat')) {
    return kLicenceNocOptions[19];
  }

  // Check if string starts with an option name (e.g. "Other Licence / NOC - Custom details")
  for (final opt in kLicenceNocOptions) {
    if (clean.startsWith(opt.name.toLowerCase()) ||
        clean.startsWith(opt.displayName.toLowerCase())) {
      return opt;
    }
  }

  return null;
}
