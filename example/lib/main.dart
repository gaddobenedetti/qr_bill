import 'package:flutter/material.dart';
import 'package:qr_bill/qr_bill.dart';
import 'package:qr_bill/bill_generator.dart';

void main() => runApp(QrBillExample());

class QrBillExample extends StatefulWidget {
  const QrBillExample({Key? key}) : super(key: key);

  @override
  State<QrBillExample> createState() => _QrBillExampleState();
}

class _QrBillExampleState extends State<QrBillExample> {
  Widget? qr = null;

  @override
  void initState() {
    _getQR();
    super.initState();
  }

  Future<void> _getQR() async {
    QRBill qrBill = QRBill();
    qrBill.setIBAN("CH4431999123000889012");
    qrBill.setActor(
        typeId: QRBill.actorUCR,
        addressType: QRBill.addTypeStructured,
        name: "Max Muster & Söhne",
        address1: "Musterstrasse",
        address2: "123",
        postalcode: "8000",
        location: "Seldwyla",
        country: "CH");
    qrBill.setActor(
        typeId: QRBill.actorUDR,
        addressType: QRBill.addTypeStructured,
        name: "Sandro Bellucci",
        address1: "Musterstrasse",
        address2: "1",
        postalcode: "8000",
        location: "Seldwyla",
        country: "CH");
    qrBill.setAlternativeSchema(schemas: [
      "Name AV1: UV;UltraPay005;12345",
      "Name AV2: XY;XYService;54321"
    ]);
    qrBill.setAmount(1949.75);
    qrBill.setReference(QRBill.refTypeQRR, "210000000003139471430009017");
    qrBill.setAdditionalInfo(
        "//S1/10/1234/11/201021/30/102673386/32/7.7/40/0:30");

    BillGenerator qrGen = BillGenerator(language: BillGenerator.german);
    qr = await (qrGen.getWidget(qrBill));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: qr ?? Container());
  }
}
