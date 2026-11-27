// lib/widgets/pdf_document_view_screen.dart
// Read-only "View" page that shows a record exactly as its PDF looks
// with multi-device zoom controls (pinch-to-zoom, double-tap, Ctrl+wheel, and on-screen zoom toolbar).
// Normal mouse wheel scrolling scrolls pages without accidental zooming.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../theme/app_theme.dart';
import '../utils/translation_helper.dart';
import 'module_hub_screen_app_bar.dart';

class PdfDocumentViewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String moduleName;

  const PdfDocumentViewScreen({
    super.key,
    required this.pdfBytes,
    required this.moduleName,
  });

  /// Opens the view page for [pdfBytes] under the module's name.
  static Future<void> open(
    BuildContext context, {
    required Uint8List pdfBytes,
    required String moduleName,
  }) {
    return Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: PdfDocumentViewScreen(pdfBytes: pdfBytes, moduleName: moduleName),
      ),
    );
  }

  @override
  State<PdfDocumentViewScreen> createState() => _PdfDocumentViewScreenState();
}

class _PdfDocumentViewScreenState extends State<PdfDocumentViewScreen>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animController;
  Animation<Matrix4>? _animation;
  double _currentScale = 1.0;
  bool _isCtrlPressed = false;
  TapDownDetails? _lastTapDownDetails;
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (isCtrl != _isCtrlPressed && mounted) {
      setState(() {
        _isCtrlPressed = isCtrl;
      });
    }
    return false;
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.01) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _animateToMatrix(Matrix4 target) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.reset();
    _animController.forward();
  }

  Matrix4 _centeredScaleMatrix(double targetScale, {Offset? focalPoint}) {
    final center =
        focalPoint ?? Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final tx = center.dx * (1.0 - targetScale);
    final ty = center.dy * (1.0 - targetScale);
    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
  }

  void _zoomIn() {
    final nextScale = (_currentScale + 0.25).clamp(0.5, 4.0);
    _animateToMatrix(_centeredScaleMatrix(nextScale));
  }

  void _zoomOut() {
    final nextScale = (_currentScale - 0.25).clamp(0.5, 4.0);
    if (nextScale <= 1.0) {
      _animateToMatrix(Matrix4.identity());
    } else {
      _animateToMatrix(_centeredScaleMatrix(nextScale));
    }
  }

  void _resetZoom() {
    _animateToMatrix(Matrix4.identity());
  }

  void _handleDoubleTap() {
    if (_currentScale > 1.05) {
      _resetZoom();
    } else {
      final focal = _lastTapDownDetails?.localPosition;
      _animateToMatrix(_centeredScaleMatrix(2.0, focalPoint: focal));
    }
  }

  Future<void> _downloadPdf() async {
    final safeName = widget.moduleName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final fileName = '${safeName.isEmpty ? 'Case' : safeName}_Report.pdf';
    await Printing.sharePdf(
      bytes: widget.pdfBytes,
      filename: fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = TranslationHelper.translate(context, widget.moduleName);
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: ModuleHubScreenAppBar(
        title: '${TranslationHelper.translate(context, 'View')} $name',
        subtitle: name,
        actionWidget: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ElevatedButton.icon(
            onPressed: _downloadPdf,
            icon: const Icon(
              Icons.download_rounded,
              color: Colors.white,
              size: 16,
            ),
            label: Text(
              'PDF',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyMid,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
                        HardwareKeyboard.instance.isMetaPressed;
                    if (isCtrl != _isCtrlPressed && mounted) {
                      setState(() {
                        _isCtrlPressed = isCtrl;
                      });
                    }
                  }
                },
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  panEnabled: _currentScale > 1.001,
                  scaleEnabled: true,
                  // Only allow mouse wheel scroll to zoom if Ctrl/Cmd is held down.
                  // Normal wheel scrolling scrolls pages without zooming.
                  scaleFactor: _isCtrlPressed ? 200.0 : 1e12,
                  clipBehavior: Clip.none,
                  child: GestureDetector(
                    onDoubleTapDown: (details) => _lastTapDownDetails = details,
                    onDoubleTap: _handleDoubleTap,
                    child: PdfPreview.builder(
                      build: (_) async => widget.pdfBytes,
                      useActions: false,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      initialPageFormat: PdfPageFormat.a4,
                      maxPageWidth: 850,
                      // High rendering DPI (5x standard 72 DPI, ~3000px width for A4)
                      // combined with FilterQuality.high delivers razor-sharp,
                      // vector-quality font glyphs at all zoom levels without aliasing.
                      dpi: 360.0,
                      scrollViewDecoration:
                          const BoxDecoration(color: AppColors.lightBg),
                      previewPageMargin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      pagesBuilder: (context, pages) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 850),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final page in pages)
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x1F000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: page.aspectRatio,
                                        child: Image(
                                          image: page.image,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.lightBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 20),
                        color: AppColors.navyDark,
                        tooltip: 'Zoom out',
                        onPressed: _currentScale > 0.5 ? _zoomOut : null,
                      ),
                      InkWell(
                        onTap: _resetZoom,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Text(
                            '${(_currentScale * 100).round()}%',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        color: AppColors.navyDark,
                        tooltip: 'Zoom in',
                        onPressed: _currentScale < 4.0 ? _zoomIn : null,
                      ),
                      Container(
                        height: 18,
                        width: 1,
                        color: AppColors.lightBorder,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fit_screen_rounded, size: 18),
                        color: AppColors.navyDark,
                        tooltip: 'Reset to fit',
                        onPressed: _currentScale != 1.0 ? _resetZoom : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
