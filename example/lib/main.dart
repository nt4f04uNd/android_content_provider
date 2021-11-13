import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:android_content_provider/android_content_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final c = AndroidContentResolver();
  // final  test =  await c.bulkInsert(uri, ContentValues());
  // print(test)
  final cursor = await c.query(
    Uri.parse(
        'content://com.nt4f04und.android_content_provider_example.ExampleAndroidContentProvider'),
    null,
    null,
    null,
    null,
  );
  print(await cursor?.batchedGet().getColumnNames().commit());
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
  Future<int> bulkInsert(Uri uri, List<ContentValues> values) {
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
  Future<Uri?> canonicalize(Uri url) {
    // TODO: implement canonicalize
    throw UnimplementedError();
  }

  @override
  Future<int> delete(Uri uri, String? selection, List<String>? selectionArgs) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<int> deleteWithExtras(Uri uri, BundleMap? extras) {
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
  Future<List<String>?> getStreamTypes(Uri uri, String mimeTypeFilter) {
    // TODO: implement getStreamTypes
    throw UnimplementedError();
  }

  @override
  Future<String?> getType(Uri uri) {
    // TODO: implement getType
    throw UnimplementedError();
  }

  @override
  Future<String> getWritePermission() {
    // TODO: implement getWritePermission
    throw UnimplementedError();
  }

  @override
  Future<Uri?> insert(Uri uri, ContentValues? values) {
    // TODO: implement insert
    throw UnimplementedError();
  }

  @override
  Future<Uri?> insertWithExtras(
      Uri uri, ContentValues? values, BundleMap? extras) {
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
  Future<Uri> openFile(Uri uri, String mode) {
    // TODO: implement openFile
    throw UnimplementedError();
  }

  @override
  Future<Uri> openFileWithSignal(
      Uri uri, String mode, CancellationSignal cancellationSignal) {
    // TODO: implement openFileWithSignal
    throw UnimplementedError();
  }

  @override
  Future<CursorData> query(Uri uri, List<String>? projection, String? selection,
      List<String>? selectionArgs, String? sortOrder) async {
    print('query');
    return MatrixCursorData(columnNames: ['test'], notificationUris: null);
  }

  @override
  Future<CursorData> queryWithBundle(Uri uri, List<String>? projection,
      BundleMap? queryArgs, CancellationSignal? cancellationSignal) {
    // TODO: implement queryWithBundle
    throw UnimplementedError();
  }

  @override
  Future<CursorData> queryWithSignal(
      Uri uri,
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
      Uri uri, BundleMap? extras, CancellationSignal? cancellationSignal) {
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
  Future<Uri?> uncanonicalize(Uri url) {
    // TODO: implement uncanonicalize
    throw UnimplementedError();
  }

  @override
  Future<int> update(Uri uri, ContentValues? values, String? selection,
      List<String>? selectionArgs) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Future<int> updateWithExtras(
      Uri uri, ContentValues? values, BundleMap? extras) {
    // TODO: implement updateWithExtras
    throw UnimplementedError();
  }
}
