import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/category_icon_helper.dart';
import '../utils/translation_helper.dart';

/// One sub-tab of a dashboard tile (e.g. "NAFIS" inside "NAFIS/Fingerprint").
class SubTab {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;

  const SubTab(this.label, this.icon, this.builder);
}

/// Opens a dashboard tile's sub-tabs as tabs: the first one shows right away
/// and the others are one tap away, without going back to a chooser.
///
/// Each sub-tab keeps its own screen, header and buttons. Screens show the
/// tab switch by adding [SubTabHost.appBarBottom] to their AppBar or
/// [SubTabHost.strip] to their body; outside a host both are empty, so the
/// same screens still work when opened on their own.
class SubTabHost extends StatefulWidget {
  final List<SubTab> tabs;

  const SubTabHost({super.key, required this.tabs});

  /// The tab switch as an AppBar `bottom`, or null outside a host.
  static PreferredSizeWidget? appBarBottom(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SubTabScope>();
    return scope == null ? null : _SubTabStrip(scope: scope);
  }

  /// For an AppBar that already has a `bottom` (e.g. its own TabBar): the tab
  /// switch stacked above [bottom], or just [bottom] outside a host.
  static PreferredSizeWidget appBarBottomAbove(
    BuildContext context,
    PreferredSizeWidget bottom,
  ) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SubTabScope>();
    if (scope == null) return bottom;
    final strip = _SubTabStrip(scope: scope);
    return PreferredSize(
      preferredSize: Size.fromHeight(
        strip.preferredSize.height + bottom.preferredSize.height,
      ),
      child: Column(children: [strip, bottom]),
    );
  }

  /// The tab switch for the top of a screen's body, or nothing outside a host.
  static List<Widget> strip(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SubTabScope>();
    return scope == null ? const [] : [_SubTabStrip(scope: scope)];
  }

  @override
  State<SubTabHost> createState() => _SubTabHostState();
}

class _SubTabHostState extends State<SubTabHost> {
  int _index = 0;

  // Tabs are built the first time they are opened and then kept, so
  // switching back keeps their scroll position and loaded data.
  final Set<int> _built = {0};

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _built.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < widget.tabs.length; i++)
          _built.contains(i)
              // Hidden tabs keep their state but pause their animations.
              ? TickerMode(
                  enabled: i == _index,
                  child: _SubTabScope(
                    tabs: widget.tabs,
                    selected: _index,
                    onSelect: _select,
                    child: Builder(builder: widget.tabs[i].builder),
                  ),
                )
              : const SizedBox.shrink(),
      ],
    );
  }
}

class _SubTabScope extends InheritedWidget {
  final List<SubTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  const _SubTabScope({
    required this.tabs,
    required this.selected,
    required this.onSelect,
    required super.child,
  });

  @override
  bool updateShouldNotify(_SubTabScope oldWidget) =>
      selected != oldWidget.selected || tabs != oldWidget.tabs;
}

/// Segmented switch between a tile's sub-tabs, in the app's navy theme: a
/// soft white track with a navy pill that slides to the selected tab.
class _SubTabStrip extends StatelessWidget implements PreferredSizeWidget {
  final _SubTabScope scope;

  const _SubTabStrip({required this.scope});

  static const double _height = 50;
  static const double _trackHeight = 38;
  static const double _inset = 3;
  static const Duration _slide = Duration(milliseconds: 200);

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  Widget _buildIcon(SubTab tab, Color color) {
    final svg = CategoryIconHelper.getSvgPath(tab.label);
    if (svg != null) {
      return CategoryIconHelper.buildWidget(tab.label, color: color, size: 15);
    }
    return Icon(tab.icon, size: 15, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final count = scope.tabs.length;
    return Container(
      height: _height,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      alignment: Alignment.center,
      child: Container(
        height: _trackHeight,
        constraints: BoxConstraints(
          maxWidth: count <= 2 ? 380 : (count * 160.0).clamp(380.0, 600.0),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(_inset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / count;
            return Stack(
              children: [
                // Sliding pill behind the selected tab.
                AnimatedPositioned(
                  duration: _slide,
                  curve: Curves.easeOutCubic,
                  left: segmentWidth * scope.selected,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.navyDark,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navyDark.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      Expanded(child: _segment(context, i)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, int i) {
    final tab = scope.tabs[i];
    final selected = i == scope.selected;
    final fg = selected ? Colors.white : AppColors.navyDark;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => scope.onSelect(i),
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(
                    tab,
                    fg.withValues(alpha: selected ? 1.0 : 0.75),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: _slide,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: fg.withValues(alpha: selected ? 1.0 : 0.85),
                      ),
                      child: Text(
                        TranslationHelper.translate(context, tab.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
