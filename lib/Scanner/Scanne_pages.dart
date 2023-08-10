import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRViewExample extends StatefulWidget {
  var id_event;
  QRViewExample({required this.id_event});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  var tk_restant = "0";
  var based_url = 'http://api.pixelga.com/api.php';

  snackbar (text) {
    final snackBar = SnackBar(
      backgroundColor: Colors.redAccent,
      content:Text(text,style: TextStyle(
          color: Colors.white
      ),),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future Ticket_Restant(String id_event)async{
    final uri =
    Uri.parse(based_url);
    var reponse = await http.post(uri,body: {
      'clic':'nb_ticket_restant',
      'id_event': id_event,
    });
    print(reponse.body);
    setState(() {
      tk_restant = reponse.body;
    });

  }

  void Changer_Statut(String num_ticket) async{
    final uri =
    Uri.parse(based_url);
    var reponse = await http.post(uri,body: {
      'clic':'update',
      'num_ticket': num_ticket,
    });
    print(reponse.body);
    if(reponse.body == "deja"){
      snackbar("Ce ticket n'est plus valide");
    }
    if(reponse.body == "bon"){
      snackbar("Ticket validee");
    }
    if(reponse.body == "mauvais"){
      snackbar("Ce ticket n'existe pas pour cet evenement");
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    Ticket_Restant(widget.id_event);
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: Stack(
            children: [
              _buildQrView(context),
              Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    width: 80,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: ()async{
                        await controller?.toggleFlash();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        primary: Colors.green,
                      ),
                      child: Text(tk_restant,style: TextStyle(
                        color: Colors.white,
                        fontSize: 30
                      ),),
                    ),
                  )
              ),
              Positioned(
                  bottom: size.height/20,
                  left: size.width/2.48,
                  child: Container(
                    width: 80,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: ()async{
                        await controller?.toggleFlash();
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        primary: Colors.green,
                      ),
                      child: FutureBuilder(
                        future: controller?.getFlashStatus(),
                        builder: (context, snapshot) {
                          return Icon(
                            snapshot.data == true ?Icons.flash_on:Icons.flash_off,
                            color: Colors.white,
                            size: 36,
                          );
                        },
                      ),
                    ),
                  )
              ),
            ],
          )),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                        'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                  else
                    const Text('Scan a code',style: TextStyle(
                      fontSize: 10
                    ),),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        Changer_Statut('${scanData.code}'.split(':')[1]);
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}