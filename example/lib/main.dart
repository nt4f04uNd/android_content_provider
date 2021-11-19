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
void androidContentProviderEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  AndroidContentProviderPlugin.setUp(factory: (authority) {
    return Test(authority);
  });
}

class Test extends AndroidContentProvider {
  Test(String authority) : super(authority);

  @override
  Future<int> bulkInsert(String uri, List<ContentValues> values) {
    // TODO: implement bulkInsert
    throw UnimplementedError();
  }

  @override
  Future<BundleMap?> call(String method, String? arg, BundleMap? extras) {
    // TODO: implement call
    throw UnimplementedError();
  }

  @override
  Future<BundleMap?> callWithAuthority(
      String authority, String method, String? arg, BundleMap? extras) {
    // TODO: implement callWithAuthority
    throw UnimplementedError();
  }

  @override
  Future<String?> canonicalize(String url) {
    // TODO: implement canonicalize
    throw UnimplementedError();
  }

  @override
  Future<int> delete(
      String uri, String? selection, List<String>? selectionArgs) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<int> deleteWithExtras(String uri, BundleMap? extras) {
    // TODO: implement deleteWithExtras
    throw UnimplementedError();
  }

  @override
  Future<String> dump(List<String> args) {
    // TODO: implement dump
    throw UnimplementedError();
  }

  @override
  Future<List<PathPermission>> getPathPermissions() {
    // TODO: implement getPathPermissions
    throw UnimplementedError();
  }

  @override
  Future<String> getReadPermission() {
    // TODO: implement getReadPermission
    throw UnimplementedError();
  }

  @override
  Future<List<String>?> getStreamTypes(String uri, String mimeTypeFilter) {
    // TODO: implement getStreamTypes
    throw UnimplementedError();
  }

  @override
  Future<String?> getType(String uri) {
    // TODO: implement getType
    throw UnimplementedError();
  }

  @override
  Future<String> getWritePermission() {
    // TODO: implement getWritePermission
    throw UnimplementedError();
  }

  @override
  Future<String?> insert(String uri, ContentValues? values) {
    // TODO: implement insert
    throw UnimplementedError();
  }

  @override
  Future<String?> insertWithExtras(
      String uri, ContentValues? values, BundleMap? extras) {
    // TODO: implement insertWithExtras
    throw UnimplementedError();
  }

  @override
  Future<void> onLowMemory() {
    // TODO: implement onLowMemory
    throw UnimplementedError();
  }

  @override
  Future<void> onTrimMemory(int level) {
    // TODO: implement onTrimMemory
    throw UnimplementedError();
  }

  @override
  Future<String> openFile(String uri, String mode) {
    // TODO: implement openFile
    throw UnimplementedError();
  }

  @override
  Future<String> openFileWithSignal(
      String uri, String mode, CancellationSignal cancellationSignal) {
    // TODO: implement openFileWithSignal
    throw UnimplementedError();
  }

  @override
  Future<CursorData> query(String uri, List<String>? projection,
      String? selection, List<String>? selectionArgs, String? sortOrder) async {
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
  Future<CursorData> queryWithBundle(String uri, List<String>? projection,
      BundleMap? queryArgs, CancellationSignal? cancellationSignal) {
    // TODO: implement queryWithBundle
    throw UnimplementedError();
  }

  @override
  Future<CursorData> queryWithSignal(
      String uri,
      List<String>? projection,
      String? selection,
      List<String>? selectionArgs,
      String? sortOrder,
      CancellationSignal? cancellationSignal) {
    // TODO: implement queryWithSignal
    throw UnimplementedError();
  }

  @override
  Future<bool> refresh(
      String uri, BundleMap? extras, CancellationSignal? cancellationSignal) {
    // TODO: implement refresh
    throw UnimplementedError();
  }

  @override
  Future<void> restoreCallingIdentity(CallingIdentity identity) {
    // TODO: implement restoreCallingIdentity
    throw UnimplementedError();
  }

  @override
  Future<void> shutdown() {
    // TODO: implement shutdown
    throw UnimplementedError();
  }

  @override
  Future<String?> uncanonicalize(String url) {
    // TODO: implement uncanonicalize
    throw UnimplementedError();
  }

  @override
  Future<int> update(String uri, ContentValues? values, String? selection,
      List<String>? selectionArgs) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Future<int> updateWithExtras(
      String uri, ContentValues? values, BundleMap? extras) {
    // TODO: implement updateWithExtras
    throw UnimplementedError();
  }
}
