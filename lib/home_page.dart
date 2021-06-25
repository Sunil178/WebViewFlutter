import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  FirebaseMessaging messaging;
  num position = 1 ;

  final key = UniqueKey();

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
            FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('No'),
            ),
            FlatButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        ),
      ) ??
          false;
    }
  }


  final Completer<WebViewController> _controller = Completer<WebViewController>();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  @override

  void initState() {
    super.initState();
    registerNotification();

    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  registerNotification() async {
    await Firebase.initializeApp();
    messaging = FirebaseMessaging.instance;
    messaging.getToken().then((value){
      print("*************** " + value);
    });
    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("*************** message recieved");
      _showNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('*************** Message clicked!');
    });
  }


  Future _showNotification(RemoteMessage message) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    print(message.data);
    Map<String, dynamic> data = message.data;
    AndroidNotification android = message.notification?.android;
    if (data != null) {
      flutterLocalNotificationsPlugin.show(
        0,
        data['title'],
        data['body'],
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channel.description,
            icon: android?.smallIcon
          ),
          iOS: IOSNotificationDetails(presentAlert: true, presentSound: true),
        ),
        payload: 'Default_Sound',
      );
    }
  }

  Future selectNotification(String payload) async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: position,
              children: <Widget>[
                WebView(
                  initialUrl: 'http://mdeduchem.com',
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (WebViewController webViewController) {
                    controllerGlobal = webViewController;
                    _controller.complete(webViewController);
                  },
                  navigationDelegate: (NavigationRequest request) {
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
                  key: key,
                  onPageFinished: (String url) { doneLoading(); },
                  onWebResourceError: (WebResourceError error) {
                    doneLoading();
                  },
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