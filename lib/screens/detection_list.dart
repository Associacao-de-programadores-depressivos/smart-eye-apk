import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:smart_eye_apk/models/api.dart';
import 'package:smart_eye_apk/models/detection.dart';
import 'dart:async';

FlutterLocalNotificationsPlugin localNotification =
    new FlutterLocalNotificationsPlugin();

const String notificationChannelId = "default_notification_channel_id";
const String notificationChannelName = "Smart Eye notification channel";
const String notificationChannelDescription =
    "Smart Eye notification configuration";

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

  static Future<dynamic> myBackgroundMessageHandler(
      Map<String, dynamic> message) async {
    print("bg message");
  }

  Future<void> refresh() async {
    setState(() {
      _hasMore = true;
      _pageNumber = 0;
      _error = false;
      _loading = true;
      _detections = [];
      fetchDetections();
    });
  }

  Future<void> showDetectionDialog(Detection detection) async {
    Dialog detectionDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        height: 400.0,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.network(
              detection.boundaryImage,
              fit: BoxFit.fitWidth,
              width: double.infinity,
              height: 260.0,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                detection.detectionText(),
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12.0,
                ),
              ),
            ),
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Fechar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await showDialog(context: context, builder: (_) => detectionDialog);
  }

  Future<dynamic> onSelectNotification(String payload) async {
    var data = jsonDecode(payload);
    Detection detection = Detection.fromDynamic(data);
    await showDetectionDialog(detection);
  }

  static Future<void> _showNotification(
    int notificationId,
    String notificationTitle,
    String notificationContent,
    String payload, {
    String channelId = notificationChannelId,
    String channelTitle = notificationChannelName,
    String channelDescription = notificationChannelDescription,
    Priority notificationPriority = Priority.high,
    Importance notificationImportance = Importance.max,
  }) async {
    try {
      var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        channelId,
        channelTitle,
        channelDescription,
        playSound: true,
        importance: notificationImportance,
        priority: notificationPriority,
      );

      var iOSPlatformChannelSpecifics =
          new IOSNotificationDetails(presentSound: false);

      var platformChannelSpecifics = new NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);

      await localNotification.show(
        notificationId,
        notificationTitle,
        notificationContent,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _hasMore = true;
    _pageNumber = 0;
    _error = false;
    _loading = true;
    _detections = [];
    fetchDetections();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        var data = message["data"];
        try {
          Detection detection = Detection.fromDynamic(data);
          _showNotification(
              0, "Nova detecção!", detection.detectionText(), jsonEncode(data));
        } catch (e) {
          print(e);
        }
      },
      onLaunch: (Map<String, dynamic> message) async {},
      onResume: (Map<String, dynamic> message) async {
        try {
          var data = message["data"];
          Detection detection = Detection.fromDynamic(data);
          showDetectionDialog(detection);
        } catch (e) {
          print(e);
        }
      },
      onBackgroundMessage: myBackgroundMessageHandler,
    );

    _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
          sound: true, badge: true, alert: true, provisional: true),
    );

    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });

    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      print("Push Messaging token: $token");
    });

    try {
      var initializationSettingsAndroid =
          new AndroidInitializationSettings('app_icon');
      var initializationSettingsIOS = new IOSInitializationSettings();
      var initializationSettings = new InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS);

      localNotification.initialize(initializationSettings,
          onSelectNotification: onSelectNotification);

      var androidNotificationChannel = AndroidNotificationChannel(
          notificationChannelId,
          notificationChannelName,
          notificationChannelDescription,
          enableVibration: true,
          importance: Importance.max);

      localNotification
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          .createNotificationChannel(androidNotificationChannel)
          .then((value) => print("Created channel!"))
          .catchError((e) => print(e));
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detecções"),
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
      debugPrint(e.toString());
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
          ),
        );
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
              child: Text(
                  "Erro ao carregar as detecções, toque para tentar novamente."),
            ),
          ),
        );
      }
    } else {
      return RefreshIndicator(
        child: ListView.builder(
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
                        child: Text(
                            "Erro ao carregar as imagens, toque para tentar novamente."),
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              }

              final Detection detection = _detections[index];

              return GestureDetector(
                child: Card(
                  child: Column(
                    children: <Widget>[
                      Image.network(
                        detection.rawImg,
                        fit: BoxFit.fitWidth,
                        width: double.infinity,
                        height: 260,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 8.0),
                        child: Text(
                          detection.detectionText(),
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewFullImage(detection: detection),
                    ),
                  );
                },
              );
            }),
        onRefresh: refresh,
      );
    }

    return Container();
  }
}

class ViewFullImage extends StatelessWidget {
  final Detection detection;

  ViewFullImage({Key key, @required this.detection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Hero(
            tag: 'Detecção',
            child: Image.network(
              detection.rawImg,
            ),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
