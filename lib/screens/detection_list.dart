import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:smart_eye_apk/models/api.dart';
import 'package:smart_eye_apk/models/detection.dart';
import 'dart:async';

class DetectionList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DetectionListState();
  }
}

class DetectionListState extends State<DetectionList> {
  bool _hasMore;
  int _pageNumber;
  bool _error;
  bool _loading;
  final int _detectionsPerPage = 10;
  final int _nextPageThreshold = 5;
  List<Detection> _detections;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    _hasMore = true;
    _pageNumber = 1;
    _error = false;
    _loading = true;
    _detections = [];
    fetchDetections();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: true));

    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });

    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      print("Push Messaging token: $token");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detection list"),
      ),
      body: getBody(),
    );
  }

  Future<void> fetchDetections() async {
    try {
      final response = await API.getDetections(_pageNumber);
      List<Detection> detections =
          Detection.parseList(json.decode(response.body));

      setState(() {
        _hasMore = detections.length == _detectionsPerPage;
        _loading = false;
        _pageNumber = _pageNumber + 1;
        _detections.addAll(detections);
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Widget getBody() {
    if (_detections.isEmpty) {
      if (_loading) {
        return Center(
            child: Padding(
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ));
      } else if (_error) {
        return Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _loading = true;
                _error = false;
                fetchDetections();
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Error while loading detections, tap to try agin"),
            ),
          ),
        );
      }
    } else {
      return ListView.builder(
          itemCount: _detections.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _detections.length - _nextPageThreshold) {
              fetchDetections();
            }

            if (index == _detections.length) {
              if (_error) {
                return Center(
                    child: InkWell(
                  onTap: () {
                    setState(() {
                      _loading = true;
                      _error = false;
                      fetchDetections();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text("Error while loading photos, tap to try agin"),
                  ),
                ));
              } else {
                return Center(
                    child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ));
              }
            }

            final Detection detection = _detections[index];

            return Card(
              child: Column(
                children: <Widget>[
                  Image.network(
                    detection.imgUrl,
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                    height: 160,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(detection.title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          });
    }

    return Container();
  }
}
