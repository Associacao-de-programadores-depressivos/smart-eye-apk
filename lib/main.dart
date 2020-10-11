import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smart_eye_apk/screens/detection_list.dart';

void main() {
  runApp(SmartEye());
}

class SmartEye extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Eye',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DetectionList(),
    );
  }
}
