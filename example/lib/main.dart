import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:android_content_provider/android_content_provider.dart';

const c = AndroidContentResolver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // final  test =  await c.bulkInsert(uri, ContentValues());
  // print(test)
  final cursor = await c.query(
    'content://com.nt4f04und.android_content_provider_example.ExampleAndroidContentProvider',
    null,
    null,
    null,
    null,
  );
  if (cursor != null) {
    try {
      final columnNames = (await cursor.batchedGet().getColumnNames().commit())
          .first as List<String>;
      print(columnNames);
      while (await cursor.moveToNext()) {
        print(await cursor
            .batchedGet()
            .getInt(0)
            .getString(1)
            .getBytes(2)
            .commit());
      }
    } finally {
      await cursor.close();
    }
  } else {
    print('cursor is null');
  }
  print('done');
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
void exampleContentProviderEntrypoint() async {
  ExampleAndroidContentProvider();
}

class ExampleAndroidContentProvider extends AndroidContentProvider {
  ExampleAndroidContentProvider() : super('com.nt4f04und.android_content_provider_example.ExampleAndroidContentProvider');

  @override
  Future<int> delete(
    String uri,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    return 0;
  }

  @override
  Future<String?> getType(String uri) async {
    return null;
  }

  @override
  Future<String?> insert(String uri, ContentValues? values) async {
    return null;
  }

  @override
  Future<CursorData?> query(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
  ) async {
    final cursorData = MatrixCursorData(
      columnNames: ['column_1', 'column_2', 'column_3'],
      notificationUris: [
        'content://com.nt4f04und.android_content_provider_example.ExampleAndroidContentProvider'
      ],
    );
    for (int i = 0; i < 100; i++) {
      cursorData.addRow([
        i,
        'string_$i',
        Uint8List.fromList([i, i + 1, i + 2]),
      ]);
    }
    return cursorData;
  }

  @override
  Future<int> update(
    String uri,
    ContentValues? values,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    return 0;
  }
}

