// lib/widgets/custom_pdf_preview_dialog.dart
// Interactive, modern in-app PDF preview dialog matching the PMS theme
// with multi-device zoom controls (pinch-to-zoom, double-tap, Ctrl+wheel, and floating toolbar).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../theme/app_theme.dart';

class CustomPdfPreviewDialog extends StatefulWidget {
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;
  final String title;
  final String fileName;
  final bool showPrint;

  const CustomPdfPreviewDialog({
    super.key,
    required this.buildPdf,
    this.title = 'Document Preview',
    this.fileName = 'Document.pdf',
    this.showPrint = true,
  });

  /// Shows a modal full-screen PDF preview dialog matching the PMS design
  static Future<void> show({
    required BuildContext context,
    required Future<Uint8List> Function(PdfPageFormat format) buildPdf,
    String title = 'Document Preview',
    String fileName = 'Document.pdf',
    bool showPrint = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.lightBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1050,
            maxHeight: 900,
          ),
          child: CustomPdfPreviewDialog(
            buildPdf: buildPdf,
            title: title,
            fileName: fileName,
            showPrint: showPrint,
          ),
        ),
      ),
    );
  }

  @override
  State<CustomPdfPreviewDialog> createState() => _CustomPdfPreviewDialogState();
}

class _CustomPdfPreviewDialogState extends State<CustomPdfPreviewDialog>
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

  bool get _isNdpsDoc {
    final t = widget.title.toUpperCase();
    final f = widget.fileName.toUpperCase();
    return t.contains('NDPS') || f.contains('NDPS');
  }

  bool get _canPrint => widget.showPrint && !_isNdpsDoc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navyDark),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Close Preview',
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.navyMid,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_canPrint)
            IconButton(
              icon: const Icon(Icons.print_rounded,
                  color: AppColors.navyDark, size: 20),
              tooltip: 'Print',
              onPressed: () async {
                try {
                  final bytes = await widget.buildPdf(PdfPageFormat.a4);
                  await Printing.layoutPdf(
                    onLayout: (_) async => bytes,
                    name: widget.fileName,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Print failed: $e'),
                        backgroundColor: AppColors.dangerRed,
                      ),
                    );
                  }
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.download_rounded,
                color: AppColors.navyDark, size: 20),
            tooltip: 'Download PDF',
            onPressed: () async {
              try {
                final bytes = await widget.buildPdf(PdfPageFormat.a4);
                await Printing.sharePdf(
                    bytes: bytes, filename: widget.fileName);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Download failed: $e'),
                      backgroundColor: AppColors.dangerRed,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
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
                  scaleFactor: _isCtrlPressed ? 200.0 : 1e12,
                  clipBehavior: Clip.none,
                  child: GestureDetector(
                    onDoubleTapDown: (details) => _lastTapDownDetails = details,
                    onDoubleTap: _handleDoubleTap,
                    child: PdfPreview.builder(
                      build: widget.buildPdf,
                      pdfFileName: widget.fileName,
                      useActions: false,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      initialPageFormat: PdfPageFormat.a4,
                      maxPageWidth: 850,
                      dpi: 360.0,
                      scrollViewDecoration:
                          const BoxDecoration(color: AppColors.lightBg),
                      previewPageMargin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      loadingWidget: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.navyMid),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Rendering Document Preview...',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.lightSubText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onError: (context, error) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.dangerRed, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Failed to render PDF preview',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$error',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.lightSubText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
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
                bottom: 20,
                right: 20,
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
