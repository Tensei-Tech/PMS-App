import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:khakhi_diary/modules/pocso/providers/pocso_provider.dart';
import 'package:khakhi_diary/modules/pocso/widgets/pocso_extra_fields.dart';
import 'package:khakhi_diary/widgets/common_form/government_vehicle_usage_widget.dart';
import 'package:khakhi_diary/widgets/common_form/section_82_83_action_widget.dart';

void main() {
  group('POCSO Extra Data & Widgets Tests', () {
    testWidgets('PocsoExtraFields widget renders all 8 sections and collects data',
        (WidgetTester tester) async {
      final GlobalKey<PocsoExtraFieldsState> pocsoKey =
          GlobalKey<PocsoExtraFieldsState>();
      String? updatedVictimName;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PocsoProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PocsoExtraFields(
                  key: pocsoKey,
                  onVictimNameChanged: (name) {
                    updatedVictimName = name;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and sections exist
      expect(find.text('POCSO: LEGAL SECTIONS'), findsOneWidget);
      expect(find.text('POCSO: VICTIM IDENTITY (ANONYMIZED)'), findsOneWidget);
      expect(find.text('POCSO: VICTIM DETAILS'), findsOneWidget);
      expect(find.text('POCSO: MEDICAL EXAMINATION'), findsOneWidget);
      expect(find.text('POCSO: STATEMENTS & COUNSELLING'), findsOneWidget);
      expect(find.text('POCSO: DNA / FSL — VICTIM'), findsOneWidget);
      expect(find.text('POCSO: DNA / FSL — ACCUSED'), findsOneWidget);

      // Verify BNS & POCSO Acts are distinct
      expect(find.text('BNS ACT & SECTIONS'), findsOneWidget);
      expect(find.text('POCSO ACT & SECTIONS'), findsOneWidget);

      // Verify Age Proof Options
      expect(find.text('Age Proof'), findsOneWidget);

      // Verify Statements queries
      expect(find.text("Victim's Statement"), findsOneWidget);
      expect(find.text('Statement Taken by Lady Officer'), findsOneWidget);
      expect(find.text('CWC Statement'), findsOneWidget);
      expect(find.text('164 CrPC / 183 BNSS Statement'), findsOneWidget);
      expect(find.text('Counselling'), findsOneWidget);

      // Verify default victim pseudonym is generated as ABC 1
      expect(updatedVictimName, 'ABC 1');

      // Test hydration & collection
      pocsoKey.currentState?.hydrateFrom({
        'bnsSections': ['64', '65'],
        'pocsoSections': ['4', '8'],
        'anonymizedVictimName': 'ABC 2',
        'victimAge': '14',
        'ageProof': 'Aadhar Card',
        'medicalVictim': 'yes',
        'medicalAccused': 'no',
        'dnaAccusedFslReport': 'yes',
      });
      await tester.pumpAndSettle();

      final data = pocsoKey.currentState?.collectData();
      expect(data, isNotNull);
      expect(data!['bnsSections'], ['64', '65']);
      expect(data['pocsoSections'], ['4', '8']);
      expect(data['anonymizedVictimName'], 'ABC 2');
      expect(data['victimAge'], '14');
      expect(data['ageProof'], 'Aadhar Card');
      expect(data['medicalVictim'], 'yes');
      expect(data['medicalAccused'], 'no');
      expect(data['dnaAccusedFslReport'], 'yes');

      // Test + Add Victim button
      expect(find.text('+ Add Victim'), findsOneWidget);
      await tester.tap(find.text('+ Add Victim'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Victim #2'), findsOneWidget);
      expect(find.text('Remove'), findsNWidgets(2));

      // Tap Remove on second victim with ensureVisible
      await tester.ensureVisible(find.text('Remove').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Victim #2'), findsNothing);
      expect(find.text('Remove'), findsNothing);
    });

    testWidgets('GovernmentVehicleUsageWidget toggles correctly',
        (WidgetTester tester) async {
      GovernmentVehicleUsageData vehicleData = GovernmentVehicleUsageData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return GovernmentVehicleUsageWidget(
                  data: vehicleData,
                  onChanged: (val) {
                    setState(() => vehicleData = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('GOVERNMENT VEHICLE USAGE'), findsOneWidget);
      expect(find.text('SD Entry of Vehicle Number and Time'), findsOneWidget);
      expect(find.text('Log Book of Vehicle Entry'), findsOneWidget);
      expect(find.text('Case Diary Vehicle Entry'), findsOneWidget);

      // Tap 'Yes' on SD Entry
      final yesButtons = find.text('Yes');
      expect(yesButtons, findsWidgets);
      await tester.tap(yesButtons.first);
      await tester.pumpAndSettle();

      expect(vehicleData.sdEntry, 'yes');
    });

    testWidgets('Section8283ActionWidget toggles correctly',
        (WidgetTester tester) async {
      String? actionValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Section8283ActionWidget(
                  value: actionValue,
                  onChanged: (val) {
                    setState(() => actionValue = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(
        find.text(
            'If the accused is not traceable, has action under Section 82/83 been initiated?'),
        findsOneWidget,
      );

      // Tap Yes
      final yesBtn = find.text('Yes');
      await tester.tap(yesBtn);
      await tester.pumpAndSettle();

      expect(actionValue, 'yes');
    });
  });
}
