import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:android_content_provider/android_content_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(color: Colors.red),
      ),
    );
  }
}


@pragma('vm:entry-point')
void androidContentProviderEntrypoint() async {
  print(await AndroidContentProviderBinding.getAuthority());
  AndroidContentProviderBinding.setupProvider(Test());
}

class Test extends AndroidContentProvider {
  @override
  String? getType(Uri uri) {
    return 'test';
  }
}