///
/// This example shows off fetching songs from MediaStore with [AndroidContentResolver].
///
///

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

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<List<Object?>>? songs;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  void fetch() async {
    await autoCloseScope(() async {
      final cursor = await AndroidContentResolver.instance.query(
        // MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        uri: 'content://media/external/audio/media',
        projection: ['_id', 'title'],
        selection: null,
        selectionArgs: null,
        sortOrder: null,
      );

      final end = (await cursor!.batchedGet().getCount().commit()).first as int;
      final batch = cursor.batchedGet().getInt(0).getString(1);

      // Fast!
      // While a bit less flexible, commitRange is much faster (approximately 10x)
      await measure(() async {
        songs = await batch.commitRange(0, end);
      });

      if (mounted) {
        setState(() {
          // We loaded the songs.
        });
      }

      // Slow!
      // But can be useful for lots of atomic operations on large cursors.
      var slowSongs = [];
      await measure(() async {
        while (await cursor.moveToNext()) {
          slowSongs.add(await batch.commit());
        }
      });

      // prints true
      print(slowSongs.toString() == songs.toString());
    });
  }

  Future<void> measure(Function callback) async {
    final s = Stopwatch();
    s.start();
    await callback();
    s.stop();
    print('elapsed ${s.elapsedMilliseconds}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AndroidContentProvider plugin example'),
        ),
        body: songs == null
            ? const SizedBox.shrink()
            : ListView.builder(
                itemExtent: 50,
                itemCount: songs!.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(songs![index].last as String),
                ),
              ),
      ),
    );
  }
}
