import 'package:flutter_test/flutter_test.dart';
import 'package:khakhi_diary/utils/category_navigation_helper.dart';

Map<String, dynamic> _cat(int id, String name, int? group, {int? parent}) => {
      'category_id': id,
      'category_name': name,
      'group': group,
      'parent_category': parent,
      'is_active': true,
    };

void main() {
  final cats = [
    _cat(223, 'Theft', 1),
    _cat(224, 'Kidnapping', 1),
    _cat(228, 'Missing', 1),
    _cat(229, 'Crime Against Women', 1),
    _cat(227, 'Two/Four Wheeler Theft', 1),
    _cat(231, 'Sec 156(3)/175(3)(BNSS)', 1),
    _cat(232, 'Coin', 1),
    _cat(266, 'Normal Accident', 1, parent: 230),
    _cat(247, 'Prohibition', 2),
    _cat(248, 'Gambling', 2),
    _cat(251, 'Gowansh', 2),
    _cat(253, 'M.V Act', 2),
    // Standalone copies must never be returned as the twin
    _cat(239, 'Crime Against Women', null),
    _cat(244, 'A.D.', null),
    _cat(276, 'MPDA', null),
  ];

  String? twin(String label) =>
      CategoryNavigationHelper.findGroupTwin(cats, label)?['category_name'];

  test('dashboard labels resolve to their 1-to-5 / Part 6 category', () {
    expect(twin('Crime against\nWomen'), 'Crime Against Women');
    expect(twin('Two/Four\nWheeler Theft'), 'Two/Four Wheeler Theft');
    expect(twin('COIN'), 'Coin');
    expect(twin('CRPC 156(3) /\nBNSS 175(3)'), 'Sec 156(3)/175(3)(BNSS)');
    expect(twin('Prohibition'), 'Prohibition');
    expect(twin('Gambling'), 'Gambling');
    expect(twin('Gowansh'), 'Gowansh');
    expect(twin('M.V Act'), 'M.V Act');
    expect(twin('Theft'), 'Theft');
  });

  test('standalone-only tabs, sub-categories and combined tiles have no twin', () {
    expect(twin('A.D'), isNull);
    expect(twin('MPDA'), isNull);
    expect(twin('Normal Accident'), isNull);
    expect(twin('Kidnapping/Missing'), isNull);
  });
}
