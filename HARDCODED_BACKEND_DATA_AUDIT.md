# Audit Report: Hardcoded Frontend Data vs. Available Backend Services

**Document Version:** 1.0  
**Generated On:** October 13, 2026  
**Repository:** `PMS-App` (Frontend: Flutter / Dart | Backend: Django REST Framework / PostgreSQL / SQLite)

---

## 1. Executive Summary

This comprehensive audit identifies all places where the **Flutter frontend hardcodes data, choices, lists, configurations, and schemas**, despite the **Django backend already possessing corresponding database models, seed records, and REST API endpoints**.

Currently, multiple frontend modules duplicate database truth with local Dart maps, arrays, or JSON files. This creates maintenance overhead, discrepancies when database seeds update, and prevents dynamic administration from the Django admin or backend database.

---

## 2. Summary Comparison Matrix

| # | Domain / Feature | Frontend Hardcoded Location | Backend Database Model & Table | Available Backend API Endpoint | Status & Impact |
|---|---|---|---|---|---|
| **1** | **Acts & Sections** | `ad_form_screen.dart` (`ACT_DATA`), `common_form.dart`, `nc_form.dart`, `preventive_form.dart`, `common_form_pdf.dart` | `Act`, `ActSection`, `ActSubsection` in `apps.crimetab.models.common_form` (`acts`, `act_sections`, `act_subsections`) | `GET /api/acts/`<br>`GET /api/act-sections/?act_id=`<br>`GET /api/act-subsections/?section_id=`<br>`GET /api/categories/{id}/form-definition/` | **High Impact**: Frontend only knows ~35 static sections in `ACT_DATA`, while backend has 193+ sections and 245+ subsections across BNS & IPC. *(Only recently integrated in charges selector, still hardcoded everywhere else)*. |
| **2** | **Form I-V Crime Categories** | `form_iv_category_button.dart` (`kFormIVCaseCategories`), `dashboard_screen.dart` | `CaseCategoryGroup` & `CaseCategory` (`case_categories` where `group_id=1`) | `GET /api/groups/1/categories/`<br>`GET /api/categories/?group=1` | **High Impact**: 28 categories hardcoded in Dart. Any new category added in backend DB doesn't show up in Form I-V grids. |
| **3** | **Part VI Crime Categories** | `form_vi_category_button.dart` (`kFormVICaseCategories`) | `CaseCategory` (`case_categories` where `group_id=2` / code `VI`) | `GET /api/groups/2/categories/`<br>`GET /api/categories/?group=2` | **Medium Impact**: 9 Part VI categories frozen in Dart arrays. |
| **4** | **Standalone Categories** | `standalone_selection_screen.dart` (`kDefaultStandaloneCategories`), `app_constants.dart` (`Classification.all`) | `CaseCategory` (`case_categories` where `group_id IS NULL`) | `GET /api/categories/?standalone=true`<br>`GET /api/categories/standalone/`<br>`GET /api/categories/dashboard-tabs/` | **High Impact**: 26 standalone categories and 34 drawer classifications hardcoded locally. |
| **5** | **Police Designations & Ranks** | `app_constants.dart` (`commissionerateRegistration`, `ruralRegistration`, `SeniorOfficerRoles`) | `Designation` in `apps.public_master.models` (`public.designations`) | `GET /api/master/designations/`<br>`GET /api/master/hierarchy/rank-configs/` | **High Impact**: Ranks (PC, PSI, PI, etc.), jurisdiction levels, and switch-station permissions are hardcoded in Flutter constants instead of reading from `public.designations`. |
| **6** | **States & UTs Registry** | `india_states.dart` (`IndiaStates.all`) | `StateRegistry` in `apps.public_master.models` (`public.states`) | `GET /api/master/states/` | **Medium Impact**: 28 States + 8 UTs hardcoded as strings instead of querying active multi-tenant states. |
| **7** | **Districts & Divisions** | `india_districts_repository.dart` (`assets/data/india_districts.json`) | `MasterDivision` (`master_divisions`), `District` (`districts`) | `GET /api/divisions/`<br>`GET /api/districts/?division_id=`<br>`GET /api/master/hierarchy/divisions/`<br>`GET /api/master/hierarchy/districts/` | **High Impact**: Loads offline bundled JSON instead of live database districts and state revenue divisions. |
| **8** | **Police Stations Registry** | `maharashtra_police_stations.dart` (`maharashtraPoliceStations`), `maharashtra_police_stations_repository.dart` | `PoliceStation` in `apps.stations.models` (`stations_policestation`) | `GET /api/stations/?district_id=`<br>`GET /api/master/hierarchy/stations/` | **High Impact**: 843 stations are hardcoded in static maps or local assets instead of querying tenant stations. |
| **9** | **Panchanama Checklists** | `dynamic_form_screen.dart` (`_panchanamaKeyToName`), `common_form.dart` (`_kPanchanamaKeys`) | `ProceduralChecklist` in `apps.crimetab.models.common_form` (`procedural_checklist`) | `GET /api/categories/{id}/form-definition/` (`procedural_items`) | **Medium Impact**: 7 procedural panchanama types hardcoded in Dart maps. Backend already serves this map under `procedural_items`. |
| **10** | **Preventive Action Provisions** | `dynamic_control_factory.dart` (`preventiveActionChoices`), `dynamic_form_screen.dart` | `PreventiveActionItems.ACTION_TYPE_CHOICES` in `apps.crimetab.models.common_form` | `GET /api/categories/{id}/form-definition/` (`preventive_items`) | **Medium Impact**: 11 statutory sections (107 CrPC, 110 CrPC, 55 MPA, etc.) hardcoded in Dart choices. Backend already serves this array under `preventive_items`. |
| **11** | **Dynamic Form Fields & Templates** | `common_form.dart` (5,909 lines with hardcoded inputs for 17 sections) | `FieldTemplate` (45 templates), `FieldTemplateField` (229 field definitions) | `GET /api/<slug>/form-schema/`<br>`GET /api/categories/{id}/form-definition/` | **Critical Impact**: Legacy forms hardcode custom inputs that already exist in backend `field_template_fields` table (with types, labels, required flags, sections, and order). |
| **12** | **App Announcements & Carousel** | `news_provider.dart` (`defaultNewsItems`), `manage_announcements_screen.dart` | `AppAnnouncement` in `apps.public_master.models` (`public.app_announcements`) | `GET /api/master/announcements/` | **Low Impact**: Fallback news/law bulletins hardcoded in Dart rather than dynamically populated from the database. |
| **13** | **Person Role Types (KYC)** | `dynamic_form_screen.dart` (only supports accused / suspect) | `CasesPerson.ROLE_CHOICES` in `apps.crimetab.models.common_form` | `GET /api/cases/{id}/` (`persons` array) | **Medium Impact**: Backend supports `victim`, `deceased`, `injured`, `unidentified_accused`, etc., but UI forms only model `accused` and `suspected_accused`. |
| **14** | **Crime Type & Specialized Breakdown Queries** | `filtered_pending_screen.dart`, `pending_summary_screen.dart`, etc. (client-side loops over in-memory list) | SQL aggregations in `apps.cases.views` | `GET /api/cases/crime-types/`<br>`GET /api/cases/crime-types/<type>/sections/`<br>`GET /api/cases/pending/io-wise/`<br>`GET /api/cases/detected/time-wise/`<br>`GET /api/cases/disposal/crime-type-wise/` | **High Impact**: Specialized DB aggregation views exist in Django, but frontend frequently loads raw case lists and calculates metrics in Dart. |

---

## 3. Deep Dive into Specific Modules

### 3.1 Acts & Sections Data
- **Backend Capability:**
  - Database tables `acts`, `act_sections`, and `act_subsections` contain:
    - 2 active Acts: **Bharatiya Nyaya Sanhita 2023 (BNS)** and **Indian Penal Code 1860 (IPC)**.
    - **193+ Act Sections** with Section Number, Title, Description, Bailable Status (`Non-Bailable` vs `Bailable`), and active flags.
    - **245+ Act Subsections**.
  - Service `dynamic_form_service.py` (`get_form_definition`) automatically bundles all active Acts and Sections into `acts_sections`, plus statutory fallbacks for POCSO Act 2012, Arms Act 1959, NDPS Act 1985, MCOCA 1999, MPDA 1981, and IT Act 2000.
- **Frontend Current State:**
  - `frontend/lib/screens/ad_form_screen.dart` contains a hardcoded constant `ACT_DATA` with only ~35 sections.
  - `common_form.dart`, `common_form_pdf.dart`, `preventive_form.dart`, `pocso_extra_fields.dart`, and `nc_form.dart` all import and read from `ACT_DATA`.
  - Sections not in `ACT_DATA` cannot be selected unless using `RepeatingCascadingChargesSelector`.

---

### 3.2 Crime Categories & Groupings
- **Backend Capability:**
  - Table `case_category_groups` defines grouping levels (`1 to 5` / `I TO V`, `Part 6` / `VI`).
  - Table `case_categories` has relational hierarchy: `group_id`, `parent_category_id`, `template_id`, `display_order`, `is_active`.
  - Endpoints:
    - `GET /api/groups/`
    - `GET /api/groups/{id}/categories/`
    - `GET /api/categories/?standalone=true`
    - `GET /api/categories/{id}/children/`
- **Frontend Current State:**
  - `frontend/lib/widgets/form_iv_category_button.dart` hardcodes `kFormIVCaseCategories` (28 strings).
  - `frontend/lib/widgets/form_vi_category_button.dart` hardcodes `kFormVICaseCategories` (9 strings).
  - `frontend/lib/screens/standalone_selection_screen.dart` hardcodes `kDefaultStandaloneCategories` (26 strings).
  - `frontend/lib/utils/app_constants.dart` hardcodes `Classification.addMenuAll` (32 items) and `Classification.all` (34 items).
  - `form_i_v_selection_screen.dart:194` hardcodes `_isExcludedFromFormIV` blacklist instead of querying group definitions.

---

### 3.3 Police Designations & Hierarchy
- **Backend Capability:**
  - Table `public.designations` provides an authority matrix:
    - Code (PC, NPC, HC, ASI, PSI, API, PI, ACP, DCP, SP, DIG, DGP).
    - `rank_level` (1=DGP to 12=PC).
    - `allowed_categories` (`field_officer`, `admin_officer`).
    - `allowed_admin_roles` (`station_admin`, `district_admin`, `division_admin`).
    - `can_approve_transfers`, `can_manage_all_cases`.
    - `is_station_admin_allowed`, `is_district_admin_allowed`, `is_state_admin_allowed`.
- **Frontend Current State:**
  - `frontend/lib/utils/app_constants.dart` hardcodes `commissionerateRegistration` and `ruralRegistration` with static entries.
  - `SeniorOfficerRoles.multiLocationDesignations` hardcodes rank strings (`PSI`, `API`, `PI`, `Sr. PI`, etc.).
  - Frontend never reads from `GET /api/master/designations/` or `GET /api/master/hierarchy/rank-configs/`.

---

### 3.4 Geographic & Station Master Data
- **Backend Capability:**
  - Table `public.states` via `GET /api/master/states/` lists all registered states.
  - Table `master_divisions` via `GET /api/divisions/` lists administrative revenue divisions (Amravati, Chhatrapati Sambhajinagar, Konkan, Nagpur, Nashik, Pune).
  - Table `districts` via `GET /api/districts/?division_id=` lists districts with status and approvals.
  - Table `stations_policestation` via `GET /api/stations/?district_id=` lists all police stations with address, zone, landline, and in-charge officer.
- **Frontend Current State:**
  - `india_states.dart` hardcodes `IndiaStates.all` with 28 states and 8 union territories.
  - `india_districts_repository.dart` reads from `assets/data/india_districts.json`.
  - `maharashtra_police_stations.dart` hardcodes `maharashtraPoliceStations` dictionary.

---

### 3.5 Procedural Panchanama Checklists
- **Backend Capability:**
  - `ProceduralChecklist` model in `apps.crimetab.models.common_form`:
    - Spot Panchanama, Seizure Panchanama, Search Panchanama, Personal Search Panchanama, Memorandum Panchanama, Identification Panchanama, Identification Parade Panchanama.
  - Backend `GET /api/categories/{id}/form-definition/` delivers `procedural_items` map directly.
- **Frontend Current State:**
  - `dynamic_form_screen.dart:2316` hardcodes `static const Map<String, String> _panchanamaKeyToName`.
  - `common_form.dart:137` hardcodes `_kPanchanamaKeys`.
  - `dynamic_field_model.dart` parses `proceduralItems`, but it is unused in the UI builder.

---

### 3.6 Preventive Action Provisions
- **Backend Capability:**
  - `PreventiveActionItems.ACTION_TYPE_CHOICES` contains 11 statutory provisions:
    - `107 CrPC/126 BNSS`, `109 CrPC/128 BNSS`, `110 CrPC/129 BNSS`, `151(3) CrPC/170 BNSS`, `144 CrPC/163 BNSS`, `149 CrPC/168 BNSS`, `55 MPA`, `56 MPA`, `57 MPA`, `122 MPA`, `93 Prohibition Act`.
  - Backend `GET /api/categories/{id}/form-definition/` delivers `preventive_items` array.
- **Frontend Current State:**
  - `dynamic_control_factory.dart:399` hardcodes `static const List<String> preventiveActionChoices` with identical 11 strings.
  - `dynamic_form_screen.dart:138` initializes from the static factory constant instead of `_formDef?.preventiveItems`.

---

### 3.7 Form Schema & Dynamic Field Templates
- **Backend Capability:**
  - 45 templates in `field_templates` table.
  - 229 field definitions in `field_template_fields` table with:
    - `field_label`, `field_key`, `field_source` (`common` vs `custom`), `field_type` (`text`, `textarea`, `number`, `date`, `datetime`, `dropdown`, `checkbox`, `chips`, `file`), `is_required`, `section`, `display_order`.
  - Endpoint `GET /api/<slug>/form-schema/` returns:
    ```json
    {
      "category_name": "Murder",
      "category_slug": "murder",
      "schema": {
        "shared_fields": [...],
        "tab_fields": [...]
      }
    }
    ```
- **Frontend Current State:**
  - `common_form.dart` contains 5,909 lines of manually hand-coded widgets for all 17 sections.
  - `GET /api/<slug>/form-schema/` is never invoked anywhere in the Flutter frontend code.

---

## 4. Architectural Gaps & Risks

1. **Desynchronization Risk:**
   If legal revisions or department admins add a new Act section, preventive provision, or police rank in the Django admin console, the database receives it, but users in the Flutter app will **never see it** because the frontend renders hardcoded constants.

2. **Redundant Network & Memory Overhead:**
   The backend sends rich payloads (`acts_sections`, `procedural_items`, `preventive_items`, `genders`) in `GET /api/categories/{id}/form-definition/`, but the frontend discards them and renders static values.

3. **Duplicated Maintenance:**
   Any wording change in a category name or designation requires editing both backend SQL/Django migrations and multiple frontend files (`app_constants.dart`, `form_iv_category_button.dart`, etc.).

---

## 5. Recommended Step-by-Step Action Plan

1. **Step 1: Wire Form Definitions Directly to UI**
   - In `dynamic_control_factory.dart`, update `_buildDropdownField` to use `fieldDef.options.isNotEmpty ? fieldDef.options : (_formDef?.preventiveItems ?? ...)` instead of `preventiveActionChoices`.
   - In `dynamic_form_screen.dart`, replace `_panchanamaKeyToName` with `_formDef?.proceduralItems ?? _fallbackPanchanamaMap`.

2. **Step 2: Replace `ACT_DATA` with Database APIs**
   - Transition `common_form.dart`, `preventive_form.dart`, and `nc_form.dart` from importing `ACT_DATA` to using `CaseService.fetchActs()` and `CaseService.fetchActSections()`.

3. **Step 3: Replace Hardcoded Categories with Category APIs**
   - Change `kFormIVCaseCategories` and `kFormVICaseCategories` from compile-time constants to cached lists populated via `CaseService().fetchGroupCategories(1)` and `fetchGroupCategories(2)`.

4. **Step 4: Connect Designations and Stations to Master APIs**
   - Wire registration rank dropdowns to `GET /api/master/designations/`.
   - Wire station selectors to `GET /api/stations/?district_id=`.
