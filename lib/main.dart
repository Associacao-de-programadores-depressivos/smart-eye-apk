import 'package:flutter/material.dart';
import 'package:smart_eye_apk/screens/detection_list.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(SmartEye());
}

class SmartEye extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'Smart Eye',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[750],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DetectionList(),
    );
  }
}
