library qr_bill;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import './qr_bill.dart';

class QRGenerator {
  late QrImage _qrImage;

  QRGenerator(QRBill data) {
    final version = _setVersion(data.toString());
    final qrCode = QrCode(version, QrErrorCorrectLevel.M);
    qrCode.addData(data.toString());
    _qrImage = QrImage(qrCode);
  }

  Future<Widget?> getWidget({
    required double size,
    double margin = 0.05,
  }) async {
    var bytes = await getBinary(size: size, margin: margin);
    if (bytes == null) {
      return null;
    } else {
      return Image.memory(Uint8List.view(bytes.buffer));
    }
  }

  Future<ByteData?> getBinary({
    required double size,
    double margin = 0.05,
  }) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas c = Canvas(recorder);
    c.drawColor(Colors.white, BlendMode.src);
    drawCanvas(c, margin: margin, size: size);
    ui.Picture p = recorder.endRecording();
    final ui.Image f = await p.toImage(size.toInt(), size.toInt());
    return await f.toByteData(format: ui.ImageByteFormat.png);
  }

  void drawCanvas(ui.Canvas c,
      {double margin = 0.0,
      required double size,
      Offset offset = const ui.Offset(0.0, 0.0)}) {
    final fgPaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill
      ..color = Colors.black;
    margin = margin * size;
    final unit = (size - (margin * 2)) / _qrImage.moduleCount;

    for (int y = 0; y < _qrImage.moduleCount; y++) {
      for (int x = 0; x < _qrImage.moduleCount; x++) {
        if (_qrImage.isDark(x, y)) {
          c.drawRect(
              Rect.fromLTWH(offset.dx + (unit * x) + margin,
                  offset.dy + (unit * y) + margin, unit, unit),
              fgPaint);
        }
      }
    }
    _drawLogo(c, margin, size - (margin * 2), offset);
  }

  void _drawLogo(ui.Canvas c, double margin, double qrSize, Offset offset1) {
    double offset = (qrSize - (qrSize * 0.15)) / 2;
    double logoSize = qrSize * 0.15;
    double outerMarginSize = logoSize * 0.15;
    double innerMargin = 0.2;
    double crossWidth = 0.35;

    final p = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    c.drawRect(
        Rect.fromLTWH(offset1.dx + margin + offset,
            offset1.dy + margin + offset, logoSize, logoSize),
        p..color = Colors.white);
    double outerMargin = offset + (outerMarginSize / 2);
    double innerSize = logoSize - outerMarginSize;

    c.drawRect(
        Rect.fromLTWH(offset1.dx + margin + outerMargin,
            offset1.dy + margin + outerMargin, innerSize, innerSize),
        p..color = Colors.black);

    c.drawRect(
        Rect.fromLTWH(
            offset1.dx + margin + outerMargin + (innerSize * (innerMargin / 2)),
            offset1.dy +
                margin +
                ((qrSize - (innerSize * (1.0 - innerMargin) * crossWidth)) / 2),
            innerSize * (1.0 - innerMargin),
            innerSize * (1.0 - innerMargin) * crossWidth),
        p..color = Colors.white);

    c.drawRect(
        Rect.fromLTWH(
            offset1.dx +
                margin +
                ((qrSize - (innerSize * (1.0 - innerMargin) * crossWidth)) / 2),
            offset1.dy + margin + outerMargin + (innerSize * (innerMargin / 2)),
            innerSize * (1.0 - innerMargin) * crossWidth,
            innerSize * (1.0 - innerMargin)),
        p..color = Colors.white);
  }

  int _setVersion(String code) {
    int version = 25;
    for (int i = 25; i > 10; i--) {
      try {
        var test = QrCode(i, QrErrorCorrectLevel.M);
        test.addData(code);
        QrImage(test);
        version--;
      } catch (e) {
        return version + 1;
      }
    }
    return version + 1;
  }
}
