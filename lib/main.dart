import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import 'check_code.dart';



void main() {
 

 runApp(MaterialApp(
      home: Home(),
    ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
   List<File> _files = [];
  final pdf = pw.Document();
  @override
  Widget build(BuildContext context) {
    return Home();
    
  }
}
