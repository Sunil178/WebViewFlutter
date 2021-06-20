import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

WebViewController controllerGlobal;
bool isLoading;

Future<bool> _exitApp(BuildContext context) async {
  if (await controllerGlobal.canGoBack()) {
    controllerGlobal.goBack();
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

_launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class HomePage extends StatelessWidget {
  final Completer<WebViewController> _controller = Completer<WebViewController>();
  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Scaffold(
        body: SafeArea(
          child: WebView(
            initialUrl: 'http://mdeduchem.com',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              controllerGlobal = webViewController;
              _controller.complete(webViewController);
            },
              onPageStarted: (String url) {
              isLoading=true;
              print("**********");
              print(url);
              print("**********");
                if (!url.startsWith("http")) {
                  controllerGlobal.evaluateJavascript("window.stop();");
                  _launchURL(url);
                }
              },
          ),
        ),
      ),
    );
  }
}