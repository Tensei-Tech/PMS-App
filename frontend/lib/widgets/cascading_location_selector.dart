import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';

/// Reusable Cascading Location Dropdowns for Police Administrative Hierarchy:
/// 1. Division (GET /api/divisions/)
/// 2. District (GET /api/districts/?division_id=...)
/// 3. Police Station (GET /api/stations/?district_id=...)
class CascadingLocationSelector extends StatefulWidget {
  final String? initialDivisionId;
  final String? initialDistrictId;
  final String? initialStationId;
  final ValueChanged<Map<String, dynamic>?>? onDivisionChanged;
  final ValueChanged<Map<String, dynamic>?>? onDistrictChanged;
  final ValueChanged<Map<String, dynamic>?>? onStationChanged;
  final bool isRequired;

  const CascadingLocationSelector({
    super.key,
    this.initialDivisionId,
    this.initialDistrictId,
    this.initialStationId,
    this.onDivisionChanged,
    this.onDistrictChanged,
    this.onStationChanged,
    this.isRequired = false,
  });

  @override
  State<CascadingLocationSelector> createState() =>
      _CascadingLocationSelectorState();
}

class _CascadingLocationSelectorState extends State<CascadingLocationSelector> {
  final CaseService _caseService = CaseService();

  List<Map<String, dynamic>> _divisions = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _stations = [];

  Map<String, dynamic>? _selectedDivision;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedStation;

  bool _loadingDivisions = true;
  bool _loadingDistricts = false;
  bool _loadingStations = false;

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    final divs = await _caseService.fetchDivisions();
    if (!mounted) return;
    setState(() {
      _divisions = divs;
      _loadingDivisions = false;
    });

    if (widget.initialDivisionId != null) {
      final match = _divisions.firstWhere(
        (d) =>
            d['id']?.toString() == widget.initialDivisionId ||
            d['name'] == widget.initialDivisionId,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        _onDivisionSelected(match);
      } else {
        _loadDistricts();
      }
    } else {
      _loadDistricts();
    }
  }

  Future<void> _loadDistricts({dynamic divisionId}) async {
    setState(() => _loadingDistricts = true);
    final dists = await _caseService.fetchDistricts(divisionId: divisionId);
    if (!mounted) return;
    setState(() {
      _districts = dists;
      _loadingDistricts = false;
    });

    if (widget.initialDistrictId != null) {
      final match = _districts.firstWhere(
        (d) =>
            d['id']?.toString() == widget.initialDistrictId ||
            d['name'] == widget.initialDistrictId,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        _onDistrictSelected(match);
      }
    }
  }

  Future<void> _loadStations({dynamic districtId}) async {
    setState(() => _loadingStations = true);
    final stns = await _caseService.fetchStations(districtId: districtId);
    if (!mounted) return;
    setState(() {
      _stations = stns;
      _loadingStations = false;
    });

    if (widget.initialStationId != null) {
      final match = _stations.firstWhere(
        (s) =>
            s['id']?.toString() == widget.initialStationId ||
            s['name'] == widget.initialStationId,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        _selectedStation = match;
        widget.onStationChanged?.call(_selectedStation);
      }
    }
  }

  void _onDivisionSelected(Map<String, dynamic>? division) {
    setState(() {
      _selectedDivision = division;
      _selectedDistrict = null;
      _selectedStation = null;
      _districts = [];
      _stations = [];
    });
    widget.onDivisionChanged?.call(_selectedDivision);
    widget.onDistrictChanged?.call(null);
    widget.onStationChanged?.call(null);

    if (division != null) {
      _loadDistricts(divisionId: division['id'] ?? division['name']);
    } else {
      _loadDistricts();
    }
  }

  void _onDistrictSelected(Map<String, dynamic>? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedStation = null;
      _stations = [];
    });
    widget.onDistrictChanged?.call(_selectedDistrict);
    widget.onStationChanged?.call(null);

    if (district != null) {
      _loadStations(districtId: district['id'] ?? district['name']);
    }
  }

  void _onStationSelected(Map<String, dynamic>? station) {
    setState(() {
      _selectedStation = station;
    });
    widget.onStationChanged?.call(_selectedStation);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Division Dropdown
        _buildDropdownCard(
          label: 'Division / Range',
          hint: 'Select Division (e.g. Pune, Konkan)',
          icon: Icons.layers_outlined,
          isLoading: _loadingDivisions,
          itemCount: _divisions.length,
          value: _selectedDivision != null ? _selectedDivision!['name'] : null,
          items: _divisions.map((d) => d['name'].toString()).toList(),
          onChanged: (val) {
            if (val == null) {
              _onDivisionSelected(null);
            } else {
              final match = _divisions.firstWhere((d) => d['name'] == val);
              _onDivisionSelected(match);
            }
          },
        ),
        const SizedBox(height: 12),

        // 2. District Dropdown
        _buildDropdownCard(
          label: 'District / Commissionerate',
          hint: _selectedDivision == null
              ? 'Select District (${_districts.length} available)'
              : 'Select District under ${_selectedDivision!['name']}',
          icon: Icons.location_city_rounded,
          isLoading: _loadingDistricts,
          itemCount: _districts.length,
          value: _selectedDistrict != null ? _selectedDistrict!['name'] : null,
          items: _districts.map((d) => d['name'].toString()).toList(),
          onChanged: (val) {
            if (val == null) {
              _onDistrictSelected(null);
            } else {
              final match = _districts.firstWhere((d) => d['name'] == val);
              _onDistrictSelected(match);
            }
          },
        ),
        const SizedBox(height: 12),

        // 3. Police Station Dropdown
        _buildDropdownCard(
          label: 'Police Station',
          hint: _selectedDistrict == null
              ? 'Select District first to view stations'
              : 'Select Station (${_stations.length} in ${_selectedDistrict!['name']})',
          icon: Icons.local_police_rounded,
          isLoading: _loadingStations,
          itemCount: _stations.length,
          value: _selectedStation != null ? _selectedStation!['name'] : null,
          items: _stations.map((s) => s['name'].toString()).toList(),
          onChanged: (val) {
            if (val == null) {
              _onStationSelected(null);
            } else {
              final match = _stations.firstWhere((s) => s['name'] == val);
              _onStationSelected(match);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdownCard({
    required String label,
    required String hint,
    required IconData icon,
    required bool isLoading,
    required int itemCount,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.navyMid),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (itemCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$itemCount',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : null,
              hint: Text(
                hint,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
              items: items.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
