// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  final sw = Stopwatch()..start();
  final hmac = Hmac(sha256, utf8.encode('password'));
  var u = hmac.convert(utf8.encode('salt')).bytes;
  for (var i = 1; i < 100000; i++) {
    u = hmac.convert(u).bytes;
  }
  print(sw.elapsedMilliseconds);
}
