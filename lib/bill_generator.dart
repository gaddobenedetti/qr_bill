library qr_bill;

import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;

import './qr_bill.dart';
import './qr_generator.dart';

class BillGenerator {
  List<QRBill> qrBills;
  String language;

  static const english = "en";
  static const german = "de";
  static const french = "fr";
  static const italian = "it";

  static const styleHeader = TextStyle(
      fontFamily: "OpenSans",
      color: Colors.black,
      fontSize: 22.0,
      fontWeight: FontWeight.bold);
  static const styleDefault = TextStyle(
      fontFamily: "OpenSans",
      color: Colors.black,
      fontSize: 18.0,
      fontWeight: FontWeight.normal);
  static const styleLabel = TextStyle(
      fontFamily: "OpenSans",
      color: Colors.black,
      fontSize: 14.0,
      fontWeight: FontWeight.bold);
  static const styleFootnote = TextStyle(
      fontFamily: "OpenSans",
      color: Colors.black,
      fontSize: 14.0,
      fontWeight: FontWeight.normal);

  static const _width = 1000.0;
  static const _height = 575.0;
  static const _margin = 20.0;
  static const _qrRatio = 0.2;
  static const _panelRatio = 0.4;
  static const _majorGap = 10.0;
  static const _minorGap = 0.0;

  BillGenerator(this.qrBills, {this.language = english});

  Future<Uint8List?> getBinary(QRBill qrBill) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas c = Canvas(recorder);

    const l = _margin;
    const t = _margin;
    const w = _width - _margin;
    const h = _height - _margin;

    // Draws white background
    c.drawColor(Colors.white, BlendMode.src);

    // Draws dashed border
    _drawBorders(c, t, l, w, h);

    // Draws Left Panel
    Offset bLeft = _drawText(c,
        offset: const Offset(l + _majorGap, t + _majorGap),
        text: _getText("headingPaymentPart"),
        style: styleHeader,
        bottomPadding: _majorGap);

    bLeft = _drawBlocPaymentDetails(c, bLeft, qrBill, false);

    _drawText(c,
        offset: const Offset(((_width - _margin) * _panelRatio) - 20.0,
            (_height - _margin) - 50.0),
        text: _getText("acceptancePoint"),
        style: styleLabel,
        rightAligned: true,
        rhc: true,
        bottomPadding: 0.0);

    // Draws Right Panel
    Offset bRight = const Offset((w * _panelRatio) + 20.0, t + _majorGap);

    Offset bRight2 = _drawBlocPaymentDetails(c,
        bRight + const Offset((_width * _qrRatio) + 40.0, 0.0), qrBill, true);

    bRight = _drawText(c,
        offset: bRight,
        text: _getText("headingReceipt"),
        style: styleHeader,
        rhc: true,
        bottomPadding: 40.0);

    bRight = _drawQRImage(c, bRight, qrBill);

    // Draws bottom Amount section
    bRight = bRight2 > bRight ? Offset(bRight.dx, bRight2.dy) : bRight;
    double amountHeight = bRight.dy > bLeft.dy ? bRight.dy : bLeft.dy;
    if (amountHeight < (t + h) * (2 / 3)) amountHeight = (t + h) * (2 / 3);
    _drawAmountBox(c, Offset(bLeft.dx, amountHeight), qrBill, false);
    bRight = _drawAmountBox(c, Offset(bRight.dx, amountHeight), qrBill, true);

    if (qrBill.getAlternativeSchema().isNotEmpty) {
      StringBuffer as = StringBuffer();
      as.writeAll(qrBill.getAlternativeSchema(), "\n");

      bRight = _drawText(c,
          offset: Offset(bRight.dx, _height - _margin - 50.0),
          text: as.toString().trim(),
          style: styleFootnote,
          wrap: true,
          rhc: true,
          bottomPadding: _minorGap);
    }

    // Converts the final invoice into PNG image data
    ui.Picture p = recorder.endRecording();
    final ui.Image f = await p.toImage(_width.toInt(), _height.toInt());
    ByteData? data = await f.toByteData(format: ui.ImageByteFormat.png);

    return data == null ? null : Uint8List.view(data.buffer);
  }

  Future<Uint8List?> generateInvoices() async {
    pw.Document pdf = pw.Document();
    int validBills = 0;
    for (QRBill qrBill in qrBills) {
      Uint8List? image = await getBinary(qrBill);
      if (image != null) {
        validBills++;
        pdf.addPage(pw.Page(build: (pw.Context context) {
          return pw.Image(pw.MemoryImage(image)); // Center
        }));
      }
    }
    return validBills == 0 ? null : await pdf.save();
  }

  _drawBorders(Canvas c, double t, double l, double w, double h,
      [bool complete = true]) {
    _drawDashedLine(c, Offset(l, t), Offset(w, t));
    if (complete) {
      _drawDashedLine(c, Offset(w, t), Offset(w, h));
      _drawDashedLine(c, Offset(w, h), Offset(l, h));
      _drawDashedLine(c, Offset(l, h), Offset(l, t));
    }
    _drawDashedLine(c, Offset(w * _panelRatio, t), Offset(w * _panelRatio, h));
  }

  String _formatIBAN(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    StringBuffer iban = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i % 4 == 0 && i > 0) {
        iban.write(" ");
      }
      iban.write(raw[i]);
    }
    return iban.toString();
  }

  Offset _drawQRImage(Canvas c, Offset offset, QRBill qrBill) {
    QRGenerator qr = QRGenerator(qrBill);
    qr.drawCanvas(c, offset: offset, size: _width * _qrRatio);

    return offset + const Offset(0.0, (_width * _qrRatio));
  }

  Offset _drawBox(Canvas c, Offset offset, Size size, [double length = 20.0]) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    offset += const Offset(0.0, 10.0);
    c.drawLine(offset, offset + Offset(0.0, length), paint);
    c.drawLine(offset, offset + Offset(length, 0.0), paint);
    c.drawLine(Offset(offset.dx + size.width, offset.dy),
        Offset(offset.dx + size.width, offset.dy + length), paint);
    c.drawLine(Offset(offset.dx + size.width, offset.dy),
        Offset(offset.dx + size.width - length, offset.dy), paint);
    c.drawLine(
        Offset(offset.dx + size.width, offset.dy + size.height),
        Offset(offset.dx + size.width, offset.dy + size.height - length),
        paint);
    c.drawLine(
        Offset(offset.dx + size.width, offset.dy + size.height),
        Offset(offset.dx + size.width - length, offset.dy + size.height),
        paint);
    c.drawLine(Offset(offset.dx, offset.dy + size.height),
        Offset(offset.dx + length, offset.dy + size.height), paint);
    c.drawLine(Offset(offset.dx, offset.dy + size.height),
        Offset(offset.dx, offset.dy + size.height - length), paint);

    return offset + Offset(0.0, size.height);
  }

  Offset _drawBlocPaymentDetails(
      Canvas c, Offset offset, QRBill qrBill, bool rhc) {
    offset = _drawText(c,
        offset: offset,
        text: _getText("account"),
        style: styleLabel,
        rhc: rhc,
        bottomPadding: _minorGap);

    offset = _drawText(c,
        offset: offset,
        text: _formatIBAN(qrBill.getIBAN()),
        rhc: rhc,
        bottomPadding: _minorGap);

    offset = _drawAddress(c, offset, qrBill, QRBill.actorCR, rhc);

    if (qrBill.getReference() != null && qrBill.getReference()!.isNotEmpty) {
      offset = _drawText(c,
          offset: offset,
          text: _getText("reference"),
          rhc: rhc,
          style: styleLabel,
          bottomPadding: _minorGap);

      offset = _drawText(c,
          offset: offset,
          text: qrBill.getReference() ?? "",
          rhc: rhc,
          bottomPadding: _majorGap);
    }

    if (rhc) {
      StringBuffer additionalInfo = StringBuffer();
      if (qrBill.getAdditionalInfo().isNotEmpty) {
        additionalInfo.writeln(qrBill.getAdditionalInfo());
      }
      if (qrBill.getBillInfo() != null && qrBill.getBillInfo()!.isNotEmpty) {
        additionalInfo.writeln(qrBill.getBillInfo());
      }
      if (additionalInfo.isNotEmpty) {
        offset = _drawText(c,
            offset: offset,
            text: _getText("additionalInfo"),
            style: styleLabel,
            rhc: rhc,
            bottomPadding: _minorGap);

        offset = _drawText(c,
            offset: offset,
            text: additionalInfo.toString(),
            bottomPadding: _majorGap,
            rhc: rhc,
            wrap: true);
      }
    }

    offset = _drawText(c,
        offset: offset,
        text: _getText("payableByDetails"),
        style: styleLabel,
        rhc: rhc,
        bottomPadding: _minorGap);

    offset = _drawAddress(c, offset, qrBill, QRBill.actorUDR, rhc);

    offset = offset += Offset(0.0, styleLabel.height ?? 14.0 + _majorGap);

    return offset;
  }

  void _drawDashedLine(Canvas c, Offset p1, Offset p2) {
    const dashWidth = 5.0, dashSpace = dashWidth;
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    final dX = p2.dx - p1.dx;
    final dY = p2.dy - p1.dy;
    final angle = atan2(dY, dX);
    final totalLength = sqrt(pow(dX, 2) + pow(dY, 2));

    double drawnLength = 0.0;
    final cosine = cos(angle);
    final sine = sin(angle);

    while (drawnLength < totalLength) {
      c.drawLine(
          Offset(p1.dx + cosine * drawnLength, p1.dy + sine * drawnLength),
          Offset(p1.dx + cosine * (drawnLength + dashWidth),
              p1.dy + sine * (drawnLength + dashWidth)),
          paint);

      drawnLength += dashWidth + dashSpace;
    }
  }

  Offset _drawAddress(
      Canvas c, Offset offset, QRBill qrBill, int type, bool rhc) {
    if (qrBill.getActorAddressType(type).isNotEmpty) {
      if (qrBill.getActorName(type).isNotEmpty) {
        offset = _drawText(c,
            offset: offset,
            text: qrBill.getActorName(type),
            bottomPadding: _minorGap);
      }
      if (qrBill.getActorAddressType(type) == QRBill.addTypeStructured) {
        if (qrBill.getActorStreet(type).isNotEmpty) {
          StringBuffer line1 = StringBuffer(qrBill.getActorStreet(type));
          if (qrBill.getActorHouseNumber(type).isNotEmpty) {
            line1.write(" ");
            line1.write(qrBill.getActorHouseNumber(type));
          }
          offset = _drawText(c,
              offset: offset,
              text: line1.toString(),
              bottomPadding: _minorGap,
              rhc: rhc);
        }
        StringBuffer line2 = StringBuffer();
        if (qrBill.getActorPostcode(type).isNotEmpty) {
          line2.write(qrBill.getActorPostcode(type));
          if (qrBill.getActorLocation(type).isNotEmpty) {
            line2.write(" ");
          }
        }
        if (qrBill.getActorLocation(type).isNotEmpty) {
          line2.write(qrBill.getActorLocation(type));
        }
        String country = "";
        if (qrBill.getActorCountry(type).isNotEmpty &&
            qrBill.getActorCountry(type) != "CH" &&
            line2.isNotEmpty) {
          country = " - ${qrBill.getActorCountry(type)}";
        }
        offset = _drawText(c,
            offset: offset,
            text: country + line2.toString(),
            bottomPadding: _minorGap,
            rhc: rhc);
      } else {
        if (qrBill.getActorStreet(type).isNotEmpty) {
          offset = _drawText(c,
              offset: offset,
              text: qrBill.getActorStreet(type),
              bottomPadding: _minorGap,
              rhc: rhc);
        }
        if (qrBill.getActorHouseNumber(type).isNotEmpty) {
          StringBuffer line2 = StringBuffer();
          if (qrBill.getActorCountry(type).isNotEmpty &&
              qrBill.getActorCountry(type) != "CH" &&
              line2.isNotEmpty) {
            line2.write(" - ");
            line2.write(qrBill.getActorCountry(type));
          }
          line2.write(qrBill.getActorHouseNumber(type));
          offset = _drawText(c,
              offset: offset,
              text: line2.toString(),
              bottomPadding: _minorGap,
              rhc: rhc);
        }
      }
    } else {
      offset = _drawBox(c, offset, Size(rhc ? 300.0 : 330.0, 100.0));
    }
    return offset + const Offset(0.0, _majorGap);
  }

  Offset _drawAmountBox(Canvas c, Offset offset, QRBill qrBill, bool rhc) {
    // Finish Amount box
    Offset secondLine = _drawText(c,
        offset: offset,
        text: _getText("currency"),
        style: styleLabel,
        rhc: rhc,
        bottomPadding: _minorGap);
    _drawText(c,
        offset: offset + const Offset(90.0, 0.0),
        text: _getText("amount"),
        style: styleLabel,
        rhc: rhc,
        bottomPadding: _minorGap);
    _drawText(c,
        offset: secondLine,
        text: qrBill.getCurrency() ?? "CH",
        style: styleDefault,
        rhc: rhc,
        bottomPadding: _majorGap);
    if (qrBill.getAmount() == null || qrBill.getAmount() == 0.0) {
      if (rhc) {
        _drawBox(
            c, secondLine + const Offset(90.0, 0.0), const Size(200.0, 60.0));
      } else {
        _drawBox(c, offset + const Offset(160.0, -10.0),
            const Size(150.0, 50.0), 7.0);
      }
    } else {
      _drawText(c,
          offset: secondLine + const Offset(90.0, 0.0),
          text: qrBill.getAmount().toString(),
          style: styleDefault,
          rhc: rhc,
          bottomPadding: _majorGap);
    }

    return offset;
  }

  Offset _drawText(Canvas c,
      {required Offset offset,
      required String text,
      TextStyle style = styleDefault,
      bool rightAligned = false,
      double bottomPadding = 5.0,
      bool wrap = false,
      bool rhc = true}) {
    TextPainter textPainter = TextPainter(
        text: TextSpan(style: style, text: text.trim()),
        textDirection: TextDirection.ltr,
        textAlign: rightAligned ? TextAlign.right : TextAlign.left);
    if (wrap) {
      textPainter.layout(
          maxWidth: (rhc ? _width : _width * _panelRatio) - offset.dx - 30.0);
    } else {
      textPainter.layout();
    }
    Offset finalOffset = offset;
    if (rightAligned) {
      finalOffset = offset + Offset(-textPainter.size.width, 0.0);
    }
    textPainter.paint(c, finalOffset);
    return finalOffset +
        Offset(0.0, textPainter.size.height + bottomPadding - 0.10);
  }

  String _getText(String? key) {
    if (key != null &&
        _labels.containsKey(key) &&
        _labels[key]!.containsKey(language)) {
      return _labels[key]![language]!;
    } else {
      return "";
    }
  }

  final Map<String, Map<String, String>> _labels = {
    "headingPaymentPart": {
      english: "Payment part",
      german: "Zahlteil",
      french: "Section paiement",
      italian: "Sezione pagamento"
    },
    "headingReceipt": {
      english: "Receipt",
      german: "Empfangsschein",
      french: "Récépissé",
      italian: "Ricevuta"
    },
    "account": {
      english: "Account / Payable to",
      german: "Konto / Zahlbar an",
      french: "Compte / Payable à",
      italian: "Conto / Pagabile a"
    },
    "reference": {
      english: "Reference",
      german: "Referen",
      french: "Référence",
      italian: "Riferimento"
    },
    "additionalInfo": {
      english: "Additional information",
      german: "Zusätzliche Informationen",
      french: "Informations supplémentaires",
      italian: "Informazioni supplementari"
    },
    "payableBy": {
      english: "Payable by",
      german: "Zahlbar durch",
      french: "Payable par",
      italian: "Pagabile da"
    },
    "payableByDetails": {
      english: "Payable by (name/address)",
      german: "Zahlbar durch (Name/Adresse)",
      french: "Payable par (nom/adresse)",
      italian: "Pagabile da (nome/indirizzo)"
    },
    "currency": {
      english: "Currency",
      german: "Währung",
      french: "Monnaie",
      italian: "Valuta"
    },
    "amount": {
      english: "Amount",
      german: "Betrag",
      french: "Montant",
      italian: "Importo"
    },
    "acceptancePoint": {
      english: "Acceptance point",
      german: "Annahmestelle",
      french: "Point de dépôt",
      italian: "Punto di accettazione"
    },
    "SeperateBefore": {
      english: "Separate before paying in",
      german: "Vor der Einzahlung abzutrennen",
      french: "A détacher avant le versement",
      italian: "Da staccare prima del versamento"
    },
    "inFavourOf": {
      english: "In favour of",
      german: "Zugunsten",
      french: "En faveur de",
      italian: "A favore di"
    },
    "qrBill": {
      english: "QR-bill",
      german: "QR-Rechnung",
      french: "QR-facture",
      italian: "QR-fattura"
    },
    "qrReference": {
      english: "QR reference",
      german: "QR-Referenz",
      french: "Référence QR",
      italian: "Riferimento QR"
    },
    "qrId": {
      english: "QR-IID",
      german: "QR-IID",
      french: "QR-IID",
      italian: "QR-IID"
    },
    "qrIban": {
      english: "QR-IBAN",
      german: "QR-IBAN",
      french: "QR-IBAN",
      italian: "QR-IBAN"
    },
    "billingInfo": {
      english: "Billing information",
      german: "Rechnungsinformationen",
      french: "Informations de facture",
      italian: "Informazioni per la fattura"
    },
    "alternatives": {
      english: "Alternative procedures",
      german: "Alternative Verfahren",
      french: "Procédures alternatives",
      italian: "Procedure alternative"
    },
  };
}
