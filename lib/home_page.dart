import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


WebViewController controllerGlobal;
bool isLoading;

_launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class WebViewClass extends StatefulWidget {
  HomePage createState() => HomePage();
}

class HomePage extends State<WebViewClass> {
  num position = 1 ;
  SharedPreferences prefs;
  String sp_fcm_token;
  FirebaseMessaging _firebaseMessaging;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  doneLoading() {
    setState(() {
      position = 0;
    });
  }

  startLoading(){
    setState(() {
      position = 1;
    });
  }

  Future<bool> _exitApp(BuildContext context) async {
    if (await controllerGlobal.canGoBack()) {
      controllerGlobal.goBack();
      startLoading();
      return Future.value(false);
    } else {
      // return Future.value(true);
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you want to exit'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        ),
      ) ??
          false;
    }
  }

  @override
  void initState() {
    super.initState();

    var initializationSettingsAndroid = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new DarwinInitializationSettings();
    var initializationSettings = new InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
    startNotification();
  }

  void startNotification() async {

    await Firebase.initializeApp();
    _firebaseMessaging = FirebaseMessaging.instance;
    _firebaseMessaging.getToken().then((value) async {
      print("*************** " + value);
      await storeLocalFCMToken(value);
    });
    _firebaseMessaging.onTokenRefresh.listen((value) async {
      print("######################### " + value);
      await storeLocalFCMToken(value);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("*************** message recieved");
      showNotification(message.notification.title, message.notification.body);
      print("onMessage: $message");
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('*************** Message clicked!');
      print("onLaunch: $message");
      Navigator.pushNamed(context, '/notify');
    });

  }

  void showNotification(String title, String body) async {
    await _demoNotification(title, body);
  }

  Future<void> _demoNotification(String title, String body) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'channel_ID', 'MD-Educhem',
        channelDescription: 'channel description',
        importance: Importance.max,
        playSound: true,
        showProgress: true,
        priority: Priority.high,
        ticker: 'test ticker');

    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'test');
  }

  Future onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<http.Response> sendFCMToken(String token) {
    return http.post(
      Uri.parse('https://mdeduchem.com/Dashboard/backend/store_token.php'),
      body: <String, String>{
        'token': token,
      },
    );
  }

  void storeLocalFCMToken(String token) async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('fcm_token')) {
      sp_fcm_token = prefs.getString('fcm_token');
      if (sp_fcm_token != token) {
        prefs.setString('fcm_token', token);
        await sendFCMToken(token);
      }
    }
    else {
      prefs.setString('fcm_token', token);
      await sendFCMToken(token);
    }
  }


  @override
  Widget build(BuildContext context) {
    controllerGlobal = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
          NavigationDelegate(
              onProgress: (int progress){},
              onPageFinished: (String url) { doneLoading(); },
              onWebResourceError: (WebResourceError error) {
                doneLoading();
              },
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.contains("occinfotech.in")) {
              _launchURL(request.url);
              return NavigationDecision.prevent;
              }
              if (!request.url.startsWith("http") || request.url.endsWith(".pdf")) {
              _launchURL(request.url);
              return NavigationDecision.prevent;
              }
              startLoading();
              return NavigationDecision.navigate;
              },
          ),
      )
      ..loadRequest(Uri.parse("http://mdeduchem.com"));

    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: position,
              children: <Widget>[
                WebViewWidget(
                  controller: controllerGlobal,
                ),
                Container(
                  color: Colors.white,
                  child: Center(
                      child: CircularProgressIndicator()),
                ),
              ]
          ),
        ),
      ),
    );
  }
}