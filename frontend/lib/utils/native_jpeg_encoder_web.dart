import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:web/web.dart' as web;

Future<Uint8List?> encodeWebCanvasJpeg(ui.Image img, double quality) async {
  try {
    final w = img.width;
    final h = img.height;
    final canvas =
        web.document.createElement('canvas') as web.HTMLCanvasElement;
    canvas.width = w;
    canvas.height = h;
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
    if (ctx == null) return null;

    final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return null;

    final clamped = web.ImageData(
      (byteData.buffer.asUint8ClampedList()).toJS,
      w,
      h.toJS,
    );
    ctx.putImageData(clamped, 0, 0);

    final completer = Completer<Uint8List?>();
    canvas.toBlob(
      (web.Blob blob) {
        final reader = web.FileReader();
        reader.onloadend = (web.Event _) {
          final result = reader.result as JSArrayBuffer;
          completer.complete(result.toDart.asUint8List());
        }.toJS;
        reader.onerror = (web.Event _) {
          completer.complete(null);
        }.toJS;
        reader.readAsArrayBuffer(blob);
      }.toJS,
      'image/jpeg',
      quality.toJS,
    );
    return await completer.future;
  } catch (_) {
    return null;
  }
}
