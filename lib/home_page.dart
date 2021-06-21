import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
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
                    if (request.url.contains("occinfotech.in"))
                      return NavigationDecision.prevent;
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