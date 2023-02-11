// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_bill/bill_generator.dart';

import 'package:qr_bill/qr_bill.dart';
import 'package:qr_bill/qr_generator.dart';

void main() {
  List<QRBill> qrBills = [
    QRBill(
        data:
            "SPC\n0200\n1\nCH4431999123000889012\nS\nMax Muster & Söhne\nMusterstrasse\n123\n8000\nSeldwyla\nCH\n\n\n\n\n\n\n\n1949.75\nCHF\nS\nSimon Muster\nMusterstrasse\n1\n8000\nSeldwyla\nCH\nQRR\n210000000003139471430009017\nOrder from 15.10. 2020\nEPD\n//S1/10/1234/11/201021/30/102673386/32/7.7/40/0:30\nName AV1: UV;UltraPay005;12345\nName AV2: XY;XYService;54321"),
    QRBill(
        data:
            "SPC\n0200\n1\nCH5204835012345671000\nS\nSample Foundation\nP.O. Box\n\n3001\nBern\nCH\n\n\n\n\n\n\n\n\nCHF\n\n\n\n\n\n\n\nNON\n\n\nEPD\n\n"),
    QRBill(
        data:
            "SPC\n0100\n1\nCH4431999123000889012\nRobert Schneider AG\nRue du Lac\n1268\n2501\nBiel\nCH\nRobert Schneider Services Switzerland AG\nRue du Lac\n1268\n2501\nBiel\nCH\n1949.75\nCHF\n2019-10-31\nPia-Maria Rutschmann-Schnyder\nGrosse Marktgasse\n28\n9400\nRorschach\nCH\nQRR\n210000000003139471430009017\nAuftrag vom 15.09.2019##S1/01/20170309/11/10201409/20/14000000/22/36958/30/CH106017086/40/1020/41/3010\nUV1;1.1;1278564;1A-2F-43-AC-9B-33-21-B0-CC-D4-28-56;TCXVMKC22;2019-02-10T15:12:39; 2019-02-10T15:18:16\nXY2;2a-2.2r;_R1-CH2_ConradCH-2074-1_3350_2019-03-13T10:23:47_16,99_0,00_0,00_0,00_0,00_+8FADt/DQ=_1=="),
    // 001319256248\nS\nAjax Versicherung AG\nZürichstrasse\n25\n8600\nDübendorf\nCH\n\n\n\n\n\n\n\n382.45\nCHF\nK\nGiuseppe Rossi\nFriedheimstrasse 35\n8404 Winterthur\n\n\nCH\nQRR\n122469264581358644667404405\nRechnung Nr. 20 455 264 210 vom 02.02.2023 / zahlbar bis 01.03.2023\nEPD"),
    QRBill(
        // This QR should fail to validate
        // QRBill(
        //     data:
        //         "SPC\n0200\n1\nCH2630000
        data:
            "SPC\n0200\n1\nCH9300762011623852957\nK\nOtto's Praxis\nBahnhoffstrasse 1\n8400 Winterthur\n\n\n\nS\n\n\n\n\n\n\n805.95\nCHF\nK\nUrsula Bamert\nFrauenfelderstrasse 55\n8404 Winterthur\n\n\n\nNON\n\n\nEPD"),
  ];

  Future<File> saveFile(String filename, Uint8List filedata) async {
    const filesDir = "test_output";
    Directory dir = Directory.current;
    File file = File("${dir.path}\\$filesDir\\$filename");
    if (await file.exists()) file.delete();
    await file.writeAsBytes(filedata);
    return file;
  }

  test('Test generate QR Widget', () async {
    QRGenerator qrg = QRGenerator(qrBills[0]);
    Widget? qr = await qrg.getWidget(size: 300.0);
    expect(qr == null, false);
  });

  test('Test generate QR Image', () async {
    QRGenerator qrg = QRGenerator(qrBills[0]);
    ByteData? qr = await qrg.getBinary(size: 300.0);
    expect(qr == null, false);
    File? file;
    if (qr != null) {
      file = await saveFile('testImage.png', Uint8List.view(qr.buffer));
    }
    expect(file != null && await file.exists(), true);
  });

  test('Test QRBill Objects', () {
    List<int> testQRs = [1, 2, 3];
    for (int i = 0; i < testQRs.length; i++) {
      print("${testQRs[i]}: ${qrBills[testQRs[i]].isValid()}");
      if (!qrBills[testQRs[i]].isValid()) {
        for (QRBillException e in qrBills[testQRs[i]].qrExceptions) {
          print("  * ${e.getMessage()} (id: ${e.getErrorId()})");
        }
      }
    }
  });

  test('Test generate QR Invoice', () async {
    // Fonts must be loaded to display properly in test outputs
    final regularFont = File('assets/fonts/OpenSans-Regular.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final boldFont = File('assets/fonts/OpenSans-Bold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));

    final fontLoader = FontLoader('OpenSans')
      ..addFont(regularFont)
      ..addFont(boldFont);
    await fontLoader.load();

    BillGenerator bg = BillGenerator(qrBills, language: BillGenerator.english);
    Uint8List? bill = await bg.generateInvoices();
    expect(bill == null, false);
    File? file;
    if (bill != null) {
      file = await saveFile('testBills_${bg.language}.pdf', bill);
    }
    expect(file != null && await file.exists(), true);
  });

  test('Test generate QR Invoice Image', () async {
    // Fonts must be loaded to display properly in test outputs
    final regularFont = File('assets/fonts/OpenSans-Regular.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final boldFont = File('assets/fonts/OpenSans-Bold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));

    final fontLoader = FontLoader('OpenSans')
      ..addFont(regularFont)
      ..addFont(boldFont);
    await fontLoader.load();

    BillGenerator bg = BillGenerator(qrBills, language: BillGenerator.english);
    Uint8List? bill = await bg.getBinary(qrBills[3]);
    expect(bill == null, false);
    File? file;
    if (bill != null) {
      file = await saveFile('testBills_${bg.language}.png', bill);
    }
    expect(file != null && await file.exists(), true);
  });

  test('Test QRBill Serialization', () {
    QRBill test = qrBills[2];
    Map<String, dynamic> json = test.toJson();
    print(json);
    expect(QRBill.fromJson(json).isValid(), true);
  });
}
