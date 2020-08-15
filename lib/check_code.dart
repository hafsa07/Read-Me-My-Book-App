import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_multiple_image_picker/flutter_multiple_image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<State<StatefulWidget>> shareWidget = GlobalKey();
  final GlobalKey<State<StatefulWidget>> pickWidget = GlobalKey();
  final GlobalKey<State<StatefulWidget>> previewContainer = GlobalKey();
  Printer selectedPrinter;
  PrintingInfo printingInfo;
  File _image;
  File _tempImage;
  final pdf = pw.Document();
  int index;
  List texts = [];
  bool isLoading = false;
  bool ocr = false;
  List<dynamic> images_list = new List<Widget>();

  List resultList;
  String error;
  Future getImageCamera() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    List resultList;

    if (!mounted) return;

    setState(() {
      images_list.add(image);
    });
  }

  Future getImageGallery() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (_image == null) {
        _image = image;
      } else {
        _tempImage = _image;
        _image = image;
      }
    });
  }

  void createPDF(File _image) async {
    var temp_image = _image;
    final image = await PdfImage.file(
      pdf.document,
      bytes: temp_image.readAsBytesSync(),
    );
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return <pw.Widget>[pw.Image(image)]; // Center
        }));

    final output = await getExternalStorageDirectory();
    print("${output.path}/example.pdf");
    final file = File("${output.path}/Document$index.pdf");
    index = index + 1;

    try {
      final bool result = await Printing.layoutPdf(
          // onLayout: (PdfPageFormat format2) async => pdf.save());
          onLayout: (PdfPageFormat format2) async => pdf.save());
      _showPrintedToast(result);
    } catch (e) {
      print(e.toString());
    }
    await Printing.sharePdf(bytes: pdf.save(), filename: 'my-document.pdf');
  }

  void savePDF() async {
    final output = await getExternalStorageDirectory();
    // print(output[0]);
    print("${output.path}/example.pdf");
    final file = File("${output.path}/example.pdf");

    await file.writeAsBytes(pdf.save());

    print('Print ...');
    try {
      final bool result = await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
      _showPrintedToast(result);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<Uint8List> _printPdf() async {
    print('Print ...');
    try {
      final bool result = await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
      // _showPrintedToast(result);
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void initState() {
    Printing.info().then((PrintingInfo info) {
      setState(() {
        printingInfo = info;
        index = 1;
      });
    });
    super.initState();
  }

  void _showPrintedToast(bool printed) {
    printed ? print("Successfully printed") : print("Image is not printed");
  }

  Future readText() async {
    var text = "";
    var temporary_image = _image;
    List temporary_list = [];
    texts = temporary_list;
    FirebaseVisionImage mySelectedImage =
        FirebaseVisionImage.fromFile(temporary_image);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(mySelectedImage);
    print("hi");

    for (TextBlock b in readText.blocks) {
      for (TextLine l in b.lines) {
        for (TextElement word in l.elements) {
          text = text + word.text + ' ';
          // print(text);
        }
        print(text);
        texts.add(text);
        text = '';
      }
    }

    setState(() {
      this.texts = this.texts;
      ocr = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final themeProvider = Provider.of<DynamicTheme>(context);
    return MaterialApp(
      theme: ThemeData.dark(),
      title: 'READ ME BOOK APP',
      home: RepaintBoundary(
        key: previewContainer,
        child: Scaffold(
          appBar: AppBar(
            title: Text('READ ME BOOK APP'),
            actions: <Widget>[
              ocr == true
                  ? IconButton(
                      icon: Icon(Icons.print),
                      onPressed: () {
                        createPDF(_image);
                        // _printPdf();
                      })
                  : Text(''),
            ],
          ),
          body: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _image != null
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 180,
                              height: 40,
                              child: RaisedButton(
                                child: Text("OCR"),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                ),
                                onPressed: () {
                                  this.readText();
                                },
                              ),
                            ),
                          )
                        : Text(''),
                    Container(
                        padding: EdgeInsets.all(4),
                        child: _image == null
                            ? SizedBox(
                                height: 200,
                                child: Text(
                                  'No Image Selected !!!\nPlease select Image ',
                                  style: TextStyle(fontSize: 20),
                                ))
                            : Image.file(_image)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ScanButton(getImageCamera, getImageGallery),
                    ),
                    ocr == true
                        ? Column(
                            // padding: const EdgeInsets.all(18.0),
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Text Extracted from current picture ",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),

                              ListView.builder(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.vertical,
                                  itemCount: texts.length,
                                  itemBuilder: (BuildContext ctxt, int index) {
                                    return new Text(texts[index]);
                                  }),

                              // ),
                            ],
                          )
                        : _image != null
                            ? Text("Click on OCR Button to get text")
                            : Text(''),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanButton extends StatelessWidget {
  Function getImageCamera;
  Function getImageGallery;
  ScanButton(this.getImageCamera, this.getImageGallery);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                child: SizedBox(
                  height: 50,
                  child: RaisedButton(
                    onPressed: getImageCamera,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.camera_alt,
                        ),
                        Text('Scan')
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                child: SizedBox(
                  height: 50,
                  child: RaisedButton(
                    onPressed: getImageGallery,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.photo,
                        ),
                        Text('Gallery')
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
