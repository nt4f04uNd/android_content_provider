import 'dart:async';

import 'package:flutter/material.dart';
import 'package:android_content_provider/android_content_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  // final List<>

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat();

  @override
  void initState() {
    super.initState();
    // Timer.periodic(const Duration(seconds: 3), (timer) {
    //   fetch();
    // });
  }

  void fetch() async {
    await autoCloseScope(() async {
      final cursor = await AndroidContentResolver.instance.query(
        // uri: 'content://media/external/images/media',
        uri: 'content://media/external/audio/media',
        projection: ['_id'],
        selection: null,
        selectionArgs: null,
        sortOrder: null,
      );
      final ids = [];
      final s = Stopwatch();
      s.start();
      while (await cursor!.moveToNext()) {
        ids.add(await cursor.batchedGet().getInt(0).commit());
      }
      s.stop();
      print(s.elapsedMilliseconds);
      print(ids);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) => RotationTransition(
              turns: controller,
              child: child,
            ),
            child: Container(
              color: Colors.red,
              width: 100,
              height: 100,
            ),
          ),
        ),
      ),
    );
  }
}
