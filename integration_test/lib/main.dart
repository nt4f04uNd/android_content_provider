// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_content_provider/android_content_provider.dart';

class Stubs {
  static const number = 10;
  static const string = 'string';
  static const stringList = ['1', '2', '3'];
  static const BundleMap bundle = {
    'key': 'value',
    'stringList': stringList,
  };
  static final contentValues = ContentValues()
    ..putString('0', 'value')
    ..putByte('1', 127)
    ..putShort('2', 32767)
    ..putInt('3', 2147483647)
    ..putLong('4', 9223372036854775807)
    ..putFloat('5', 3.4028234663852886e+38)
    ..putDouble('6', double.maxFinite)
    ..putBool('7', false)
    ..putNull('8');
  static final overflowingContentValues = ContentValues()
    // will only overflow in Dart
    ..putByte('0', 127 + 1)
    ..putShort('1', 32767 + 1)
    ..putInt('2', 2147483647 + 1)
    ..putFloat('3', 3.4028234663852886e+38 + 1)
    // overflow both in Dart and and Java
    ..putLong('4', 9223372036854775807 + 1)
    ..putDouble('5', double.maxFinite + 1);
  static final contentValuesList = [
    contentValues,
    contentValues,
    contentValues,
  ];

  static const sql_extras = {
    AndroidContentResolver.QUERY_ARG_SQL_SELECTION: string + string,
    AndroidContentResolver.QUERY_ARG_SQL_SELECTION_ARGS: stringList,
  };

  static final query_columnNames = List.generate(8, (index) => 'column_$index');
  static final query_rowData = [
    Uint8List.fromList([0, 1, 2]), // getBytes
    'string', // getString
    0, // getShort
    0, // getInt
    0, // getLong
    0.5, // getFloat
    0.5, // getDouble
    null, // isNull
  ];
  static final query_rowDataAllNulls = [
    null, // getBytes
    null, // getString
    null, // getShort
    null, // getInt
    null, // getLong
    null, // getFloat
    null, // getDouble
    null, // isNull
  ];
  static final query_rowDataAllNullsToExpect = [
    null, // getBytes
    null, // getString
    0, // getShort
    0, // getInt
    0, // getLong
    0.0, // getFloat
    0.0, // getDouble
    true, // isNull
  ];
}

const authority =
    'com.nt4f04und.android_content_provider_integration_test.IntegrationTestAndroidContentProvider';
const providerUri = 'content://$authority';

const overflowingContentValuesTest =
    '$providerUri/overflowingContentValuesTest';
const deleteWithExtrasTest = '$providerUri/deleteWithExtrasTest';
const insertWithExtrasTest = '$providerUri/insertWithExtrasTest';
const queryWithExtrasTest = '$providerUri/queryWithExtrasTest';
const updateWithExtrasTest = '$providerUri/updateWithExtrasTest';
const queryCursorInvalidNotificationUriTest =
    '$providerUri/queryCursorInvalidNotificationUriTest';
const nullableCursorTest = '$providerUri/nullableCursorTest';

final throwsSecurityException = throwsA(isA<PlatformException>().having(
  (e) => e.details,
  'details',
  stringContainsInOrder([
    'SecurityException',
    'expected to find a valid ContentProvider for this authority',
  ]),
));

final throwsMissingColumn = throwsA(isA<PlatformException>().having(
  (e) => e.details,
  'details',
  contains("column 'missing-column' does not exist"),
));

typedef OnChangeCallback = void Function(
  bool selfChange,
  String? uri,
  int flags,
);
typedef OnChangeUrisCallback = void Function(
  bool selfChange,
  List<String?> uris,
  int flags,
);

class TestContentObserver extends ContentObserver {
  TestContentObserver({
    OnChangeCallback? onChange,
    OnChangeUrisCallback? onChangeUris,
  })  : _onChange = onChange,
        _onChangeUris = onChangeUris;

  final OnChangeCallback? _onChange;
  final OnChangeUrisCallback? _onChangeUris;

  @override
  void onChange(bool selfChange, String? uri, int flags) {
    _onChange?.call(selfChange, uri, flags);
  }

  @override
  void onChangeUris(bool selfChange, List<String?> uris, int flags) {
    _onChangeUris?.call(selfChange, uris, flags);
  }
}

Future<void> main() async {
  test("ContentProvider isolate communication", () async {
    final hostedPort = ReceivePort();
    IsolateNameServer.removePortNameMapping('main');
    IsolateNameServer.registerPortWithName(hostedPort.sendPort, 'main');

    // Ping "contentProvider" isolate hosted port
    final receivePort = ReceivePort();
    IsolateNameServer.lookupPortByName('contentProvider')!
        .send(receivePort.sendPort);
    expect(await receivePort.first, 'send back');
    receivePort.close();

    // Send response to hosted port ping.
    //
    // This also waits before all tests will run in the content provider isolate,
    // because the ping will be emitted in content provider isolate `tearDownAll`.
    final responsePort = await hostedPort.first;
    responsePort.send('send back');
    hostedPort.close();
  });

  test("ContentValues overflow", () async {
    final result = await AndroidContentResolver.instance.bulkInsert(
      uri: overflowingContentValuesTest,
      values: [Stubs.overflowingContentValues],
    );
    expect(result, Stubs.number);
  });

  testWidgets("ContentObserver reports exceptions",
      (WidgetTester tester) async {
    final completer = Completer();
    final observer = TestContentObserver(
      onChange: (bool selfChange, String? uri, int flags) {
        // Android seems to be always calling through `onChangeUris`.
        fail('onChange is not expected to be called');
        // Can't really test this, so test only onChangeUris.
      },
      onChangeUris: (bool selfChange, List<String?> uris, int flags) {
        completer.complete();
        final oldDebugPrint = debugPrint;
        // Don't dump errors to console - we call takeException and what's being printed is just a log.
        debugPrint = (String? message, {int? wrapWidth}) {};
        try {
          fail('dummy fail');
        } finally {
          Future.microtask(() {
            debugPrint = oldDebugPrint;
          });
        }
      },
    );
    await AndroidContentResolver.instance.registerContentObserver(
      uri: providerUri,
      observer: observer,
    );
    try {
      await AndroidContentResolver.instance.notifyChange(
        uri: providerUri,
        flags: 1,
      );
      await completer.future;
      final exception = tester.takeException();
      expect(
        exception,
        isA<TestFailure>().having((e) => e.message, 'message', 'dummy fail'),
      );
    } finally {
      await AndroidContentResolver.instance.unregisterContentObserver(observer);
    }
  });

  group("AndroidContentResolver", () {
    test("getTypeInfo", () async {
      final result = await AndroidContentResolver.instance.getTypeInfo(
        mimeType: 'image/png',
      );
      expect(result, isNotNull);
      expect(result!.label, contains("PNG"));
      expect(result.icon, hasLength(greaterThan(100)));
      expect(result.contentDescription, contains("PNG"));
    });

    // TODO: testing `loadThumbnail` requires exposing [AndroidContentProvider.openTypedAssetFile]
    // test("loadThumbnail", () async {
    //   final result = await AndroidContentResolver.instance.loadThumbnail(
    //     uri: providerUri,
    //     height: 100,
    //     width: 100,
    //     cancellationSignal: CancellationSignal()..cancel(),
    //   );
    //   expect(result, hasLength(greaterThan(100)));
    // });

    test("ContentObserver and notifyChange work", () async {
      const flags = 1 | 2 | 4 | 8 | 16;
      int callCount = 0;
      bool notifyForDescendantsTest = false;
      var streamController = StreamController();
      addTearDown(streamController.close);
      final observer = TestContentObserver(
        onChange: (bool selfChange, String? uri, int flags) {
          // Android seems to be always calling through `onChangeUris`
          fail('onChange is not expected to be called');
        },
        onChangeUris: (bool selfChange, List<String?> uris, int flags) {
          callCount += 1;
          print('callCount: $callCount');
          if (callCount == 1) {
            // Not self change
            expect(selfChange, false);
            expect(uris, [
              notifyForDescendantsTest
                  ? '$providerUri/descendantUriShouldNotify'
                  : providerUri
            ]);
            expect(flags, flags);
          } else if (callCount == 2) {
            // Self change
            expect(selfChange, true);
            expect(uris, [providerUri]);
            expect(flags, flags);
          } else if (callCount == 3) {
            // List of URIs
            expect(selfChange, false);
            expect(uris, [providerUri, providerUri, providerUri]);
            expect(flags, flags);
          } else {
            fail("Observer wasn't unregistered");
          }
          streamController.add(callCount);
        },
      );
      await AndroidContentResolver.instance.registerContentObserver(
        uri: providerUri,
        observer: observer,
      );
      // notifyForDescendants=false test
      try {
        await AndroidContentResolver.instance.notifyChange(
          uri: providerUri,
          flags: flags,
        );
        await AndroidContentResolver.instance.notifyChange(
          uri: providerUri,
          observer: observer,
          flags: flags,
        );
        await AndroidContentResolver.instance.notifyChangeWithList(
          uris: [providerUri, providerUri, providerUri],
          flags: flags,
        );
        await AndroidContentResolver.instance.notifyChangeWithList(
          uris: ['$providerUri/descendantUriShouldNotNotify'],
          flags: flags,
        );
        await streamController.stream.firstWhere((callCount) => callCount == 3);
        expect(callCount, 3);
      } finally {
        await AndroidContentResolver.instance
            .unregisterContentObserver(observer);
      }

      callCount = 0;
      streamController = StreamController();
      addTearDown(streamController.close);

      // notifyForDescendants=true test
      notifyForDescendantsTest = true;
      await AndroidContentResolver.instance.registerContentObserver(
        uri: providerUri,
        observer: observer,
        notifyForDescendants: true,
      );
      try {
        await AndroidContentResolver.instance.notifyChangeWithList(
          uris: ['$providerUri/descendantUriShouldNotify'],
          flags: flags,
        );
        await streamController.stream.firstWhere((callCount) => callCount == 1);
        expect(callCount, 1);
      } finally {
        await AndroidContentResolver.instance
            .unregisterContentObserver(observer);
      }
    });
  });

  group("AndroidContentProvider/AndroidContentResolver", () {
    test("bulkInsert", () async {
      final result = await AndroidContentResolver.instance.bulkInsert(
        uri: providerUri,
        values: Stubs.contentValuesList,
      );
      expect(result, Stubs.number);
    });

    test("call", () async {
      final result = await AndroidContentResolver.instance.call(
        uri: providerUri,
        method: Stubs.string,
        arg: Stubs.string,
        extras: Stubs.bundle,
      );
      expect(result, Stubs.bundle);
    });

    test("callWithAuthority", () async {
      final result = await AndroidContentResolver.instance.callWithAuthority(
        authority: authority,
        method: Stubs.string,
        arg: Stubs.string,
        extras: Stubs.bundle,
      );
      expect(result, Stubs.bundle);
    });

    test("canonicalize", () async {
      final result = await AndroidContentResolver.instance.canonicalize(
        url: providerUri,
      );
      expect(result, Stubs.string);
    });

    test("delete", () async {
      final result = await AndroidContentResolver.instance.delete(
        uri: providerUri,
        selection: Stubs.string,
        selectionArgs: Stubs.stringList,
      );
      expect(result, Stubs.number);
    });

    test("deleteWithExtras", () async {
      final result = await AndroidContentResolver.instance.deleteWithExtras(
        uri: deleteWithExtrasTest,
        extras: Stubs.sql_extras,
      );
      expect(result, Stubs.number);
    });

    test("getStreamTypes", () async {
      final result = await AndroidContentResolver.instance.getStreamTypes(
        uri: providerUri,
        mimeTypeFilter: Stubs.string,
      );
      expect(result, Stubs.stringList);
    });

    test("getType", () async {
      final result = await AndroidContentResolver.instance.getType(
        uri: providerUri,
      );
      expect(result, Stubs.string);
    });

    test("insert", () async {
      final result = await AndroidContentResolver.instance.insert(
        uri: providerUri,
        values: Stubs.contentValues,
      );
      expect(result, Stubs.string);
    });

    test("insertWithExtras", () async {
      final result = await AndroidContentResolver.instance.insertWithExtras(
        uri: insertWithExtrasTest,
        values: Stubs.contentValues,
        extras: Stubs.sql_extras,
      );
      expect(result, Stubs.string);
    });

    test("NativeCursor - general test, also query and queryWithExtras",
        () async {
      Future<void> testCursor(NativeCursor? cursor) async {
        cursor!;

        await cursor.setNotificationUri(providerUri);

        Future<void> testCursorObserver(String notificationUri) async {
          final completer = Completer();
          final observer = TestContentObserver(
            onChange: (bool selfChange, String? uri, int flags) {
              // Android seems to be always calling through `onChangeUris`
              fail('onChange is not expected to be called');
            },
            onChangeUris: (bool selfChange, List<String?> uris, int flags) {
              completer.complete();
            },
          );
          try {
            await cursor.registerContentObserver(observer);
            await AndroidContentResolver.instance.notifyChange(
              uri: notificationUri,
              flags: 1,
            );
            await completer.future;
          } finally {
            await cursor.unregisterContentObserver(observer);
            await AndroidContentResolver.instance.notifyChange(
              uri: notificationUri,
              flags: 1,
            );
          }
        }

        await testCursorObserver(providerUri);

        expect(await cursor.getNotificationUri(), providerUri);
        expect(await cursor.getNotificationUris(), [providerUri]);

        await expectLater(
          () => cursor.setNotificationUri('uri'),
          throwsSecurityException,
        );

        const newNotificationUri = '$providerUri/uri';
        await cursor.setNotificationUri(newNotificationUri);
        expect(await cursor.getNotificationUri(), newNotificationUri);
        expect(await cursor.getNotificationUris(), [newNotificationUri]);

        await testCursorObserver(providerUri);

        expect(await cursor.getExtras(), Stubs.bundle);

        await cursor.setExtras(Stubs.sql_extras);
        expect(await cursor.getExtras(), Stubs.sql_extras);

        expect(await cursor.respond(const {}), const {});

        final expectedColumnCount = Stubs.query_columnNames.length;
        final batch = cursor.batchedGet();
        batch
          ..getCount()
          ..getPosition()
          ..isFirst()
          ..isLast()
          ..isBeforeFirst()
          ..isAfterLast();
        for (final columnName in Stubs.query_columnNames) {
          batch.getColumnIndex(columnName);
        }
        batch.getColumnIndex('missing-column');
        // skip getColumnIndexOrThrow - it has a separate test
        for (int i = 0; i < expectedColumnCount; i++) {
          batch.getColumnName(i);
        }
        batch
          ..getColumnNames()
          ..getColumnCount();
        batch
          ..getBytes(0)
          ..getString(1)
          ..getShort(2)
          ..getInt(3)
          ..getLong(4)
          ..getFloat(5)
          ..getDouble(6)
          ..isNull(7);
        for (int i = 0; i < expectedColumnCount; i++) {
          batch.getType(i);
        }

        void verifyRow(List<Object?> row) {
          expect(row, <Object?>[
            1, // getCount
            0, // getPosition
            true, // isFirst
            true, // isLast
            false, // isBeforeFirst
            false, // isAfterLast
            // getColumnIndex
            ...List.generate(expectedColumnCount, (index) => index),
            -1, // getColumnIndex - missing-column
            ...Stubs.query_columnNames, // getColumnName
            Stubs.query_columnNames, // getColumnNames
            expectedColumnCount, // getColumnCount
            ...[
              // get___ methods
              ...List.from(Stubs.query_rowData)..removeLast(),
              true, // isNull
            ],
            // getType
            ...<Type>[
              Uint8List,
              String,
              int,
              int,
              int,
              double,
              double,
              Null,
            ]
          ]);
        }

        expect(await cursor.move(0), false);
        expect(await cursor.moveToPosition(0), true);
        expect(await cursor.moveToFirst(), true);
        expect(await cursor.moveToLast(), true);
        expect(await cursor.moveToNext(), false);
        expect(await cursor.moveToPrevious(), true);

        // returns false, but needed so that moveToNext loop below works properly
        expect(await cursor.moveToPosition(-1), false);

        // verify commit
        int rowCount = 0;
        while (await cursor.moveToNext()) {
          rowCount += 1;
          final row = await batch.commit();
          verifyRow(row);
        }
        expect(rowCount, 1);

        // verify commitRange
        final rows = await batch.commitRange(0, 1);
        expect(rows, hasLength(1));
        for (final row in rows) {
          verifyRow(row);
        }

        cursor.close();
      }

      await testCursor(await AndroidContentResolver.instance.query(
        uri: providerUri,
        projection: Stubs.stringList,
        selection: Stubs.string,
        selectionArgs: Stubs.stringList,
        sortOrder: Stubs.string,
      ));

      final queryWithSignalSignal = CancellationSignal();
      Future.delayed(
        const Duration(milliseconds: 100),
        queryWithSignalSignal.cancel,
      );
      await testCursor(await AndroidContentResolver.instance.queryWithSignal(
        uri: providerUri,
        projection: Stubs.stringList,
        selection: Stubs.string,
        selectionArgs: Stubs.stringList,
        sortOrder: Stubs.string,
        cancellationSignal: queryWithSignalSignal,
      ));

      final queryWithExtrasSignal = CancellationSignal();
      Future.delayed(
        const Duration(milliseconds: 100),
        queryWithExtrasSignal.cancel,
      );
      await testCursor(await AndroidContentResolver.instance.queryWithExtras(
        uri: queryWithExtrasTest,
        projection: Stubs.stringList,
        queryArgs: Stubs.sql_extras,
        cancellationSignal: queryWithExtrasSignal,
      ));
    });

    test("query fails with invalid notification URIs", () async {
      final queryWithExtrasInvalidSignal = CancellationSignal();
      Future.delayed(
        const Duration(milliseconds: 100),
        queryWithExtrasInvalidSignal.cancel,
      );
      expect(
        () => AndroidContentResolver.instance.queryWithExtras(
          uri: queryCursorInvalidNotificationUriTest,
          projection: Stubs.stringList,
          queryArgs: Stubs.sql_extras,
          cancellationSignal: queryWithExtrasInvalidSignal,
        ),
        throwsSecurityException,
      );
    });

    test("NativeCursor - can get null values", () async {
      final cursor = await AndroidContentResolver.instance.query(
        uri: nullableCursorTest,
        projection: null,
        selection: null,
        selectionArgs: null,
        sortOrder: null,
      );
      final batch = cursor!.batchedGet()
        ..getBytes(0)
        ..getString(1)
        ..getShort(2)
        ..getInt(3)
        ..getLong(4)
        ..getFloat(5)
        ..getDouble(6)
        ..isNull(7);
      while (await cursor.moveToNext()) {
        final row = await batch.commit();
        expect(row, Stubs.query_rowDataAllNullsToExpect);
      }
      final rows = await batch.commitRange(0, 1);
      for (final row in rows) {
        expect(row, Stubs.query_rowDataAllNullsToExpect);
      }
      cursor.close();
    });

    test("NativeCursor - getColumnIndexOrThrow", () async {
      final cursor = await AndroidContentResolver.instance.query(
        uri: nullableCursorTest,
        projection: null,
        selection: null,
        selectionArgs: null,
        sortOrder: null,
      );

      final goodBatch = cursor!.batchedGet()
        ..getColumnIndexOrThrow(Stubs.query_columnNames.first);
      final badBatch = cursor.batchedGet()
        ..getColumnIndexOrThrow('missing-column');

      while (await cursor.moveToNext()) {
        expect(() => goodBatch.commit(), returnsNormally);
        expect(() => badBatch.commit(), throwsMissingColumn);
      }
      expect(() => goodBatch.commitRange(0, 1), returnsNormally);
      expect(() => badBatch.commitRange(0, 1), throwsMissingColumn);
      cursor.close();
    });

    test("refresh", () async {
      final result = await AndroidContentResolver.instance.refresh(
        uri: providerUri,
        extras: Stubs.bundle,
        cancellationSignal: CancellationSignal()..cancel(),
      );
      expect(result, true);
    });

    test("uncanonicalize", () async {
      final result = await AndroidContentResolver.instance.uncanonicalize(
        url: providerUri,
      );
      expect(result, Stubs.string);
    });

    test("update", () async {
      final result = await AndroidContentResolver.instance.update(
        uri: providerUri,
        values: Stubs.contentValues,
        selection: Stubs.string,
        selectionArgs: Stubs.stringList,
      );
      expect(result, Stubs.number);
    });

    test("updateWithExtras", () async {
      final result = await AndroidContentResolver.instance.updateWithExtras(
        uri: updateWithExtrasTest,
        values: Stubs.contentValues,
        extras: Stubs.sql_extras,
      );
      expect(result, Stubs.number);
    });
  });
}

const callingInfoTest = 'callingInfo';

@pragma('vm:entry-point')
void integrationTestContentProviderEntrypoint() async {
  // Initialize the port as soon as we can
  final ReceivePort hostedPort = ReceivePort();
  IsolateNameServer.removePortNameMapping('contentProvider');
  IsolateNameServer.registerPortWithName(
    hostedPort.sendPort,
    'contentProvider',
  );

  late final IntegrationTestAndroidContentProvider provider;
  setUpAll(() {
    // wrap into a setUp to allow `expect`s and other test related APIs to work
    provider = IntegrationTestAndroidContentProvider();
  });

  tearDownAll(() async {
    // See the "ContentProvider isolate communication" test

    // Send response to hosted port ping
    final responsePort = await hostedPort.first;
    responsePort.send('send back');
    hostedPort.close();

    // Ping "main" isolate hosted port
    final receivePort = ReceivePort();
    IsolateNameServer.lookupPortByName('main')!.send(receivePort.sendPort);
    expect(await receivePort.first, 'send back');
    receivePort.close();
  });

  test("clearCallingIdentity and restoreCallingIdentity", () async {
    final identity = await provider.clearCallingIdentity();
    await provider.restoreCallingIdentity(identity!);
  });

  test(
      "callingInfo - getCallingAttributionTag, getCallingPackage, getCallingPackageUnchecked and onCallingPackageChanged",
      () async {
    expect(await provider.getCallingAttributionTag(), null);
    expect(await provider.getCallingPackage(), null);
    expect(await provider.getCallingPackageUnchecked(), null);
    // warm-up call to start recording
    await AndroidContentResolver.instance.callWithAuthority(
      authority: authority,
      method: callingInfoTest,
      arg: 'start',
    );
    final resolverResult =
        await AndroidContentResolver.instance.callWithAuthority(
      authority: authority,
      method: callingInfoTest,
      arg: 'end',
    );
    expect(resolverResult!['result'], [
      {
        'getCallingAttributionTag': null,
        'getCallingPackage': null,
        'getCallingPackageUnchecked': null,
      },
      {
        'getCallingAttributionTag': null,
        'getCallingPackage':
            'com.nt4f04und.android_content_provider_integration_test',
        'getCallingPackageUnchecked':
            'com.nt4f04und.android_content_provider_integration_test',
      },
    ]);
  });

  // Not testable:
  //  * onLowMemory
  //  * onTrimMemory

  // TODO: testing `openFile` and `openFileWithSignal` requires exposing Java APIs for reading and writing files
  // test("openFile and openFileWithSignal", () async {

  // });
}

class IntegrationTestAndroidContentProvider extends AndroidContentProvider {
  IntegrationTestAndroidContentProvider() : super(authority);

  @override
  Future<int> bulkInsert(String uri, List<ContentValues> values) async {
    if (uri == overflowingContentValuesTest) {
      final actual = values.first.values.toList();
      final expected = Stubs.overflowingContentValues.values.toList();
      expect(actual.length, expected.length);
      // check values that  overflow only in Java
      for (int i = 0; i < 3; i++) {
        expect(actual[i], isNot(equals(expected[i])));
      }
      // check values that overflow both in Dart and java
      for (int i = 4; i < 5; i++) {
        expect(actual.last, expected.last);
      }
    } else {
      expect(uri, providerUri);
      expect(values, Stubs.contentValuesList);
    }
    return Stubs.number;
  }

  @override
  Future<BundleMap?> call(String method, String? arg, BundleMap? extras) async {
    expect(method, Stubs.string);
    expect(arg, Stubs.string);
    expect(extras, Stubs.bundle);
    return Stubs.bundle;
  }

  bool recordningCallingInfo = false;
  var callingInfo = <BundleMap>[];

  @override
  Future<BundleMap?> callWithAuthority(
    String authority,
    String method,
    String? arg,
    BundleMap? extras,
  ) async {
    if (method == callingInfoTest) {
      if (arg == 'start') {
        callingInfo = [];
        // warm-up call to start recording
        recordningCallingInfo = true;
        return null;
      } else {
        recordningCallingInfo = false;
        expect(arg, 'end');
        return {'result': callingInfo};
      }
    }
    expect(authority, authority);
    expect(method, Stubs.string);
    expect(arg, Stubs.string);
    expect(extras, Stubs.bundle);
    return Stubs.bundle;
  }

  @override
  Future<String?> canonicalize(String url) async {
    expect(url, providerUri);
    return Stubs.string;
  }

  @override
  Future<int> delete(
    String uri,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    expect(uri, providerUri);
    expect(selection, Stubs.string);
    expect(selectionArgs, Stubs.stringList);
    return Stubs.number;
  }

  @override
  Future<int> deleteWithExtras(String uri, BundleMap? extras) async {
    if (uri == deleteWithExtrasTest) {
      // Android seems to be always calling through `deleteWithExtrasTest`
      expect(uri, deleteWithExtrasTest);
      expect(extras, Stubs.sql_extras);
      return Stubs.number;
    } else {
      return super.deleteWithExtras(uri, extras);
    }
  }

  @override
  Future<List<String>?> getStreamTypes(
    String uri,
    String mimeTypeFilter,
  ) async {
    expect(uri, providerUri);
    expect(mimeTypeFilter, Stubs.string);
    return Stubs.stringList;
  }

  @override
  Future<String?> getType(String uri) async {
    expect(uri, providerUri);
    return Stubs.string;
  }

  @override
  Future<String?> insert(String uri, ContentValues? values) async {
    expect(uri, providerUri);
    expect(values, Stubs.contentValues);
    return Stubs.string;
  }

  @override
  Future<String?> insertWithExtras(
    String uri,
    ContentValues? values,
    BundleMap? extras,
  ) async {
    if (uri == insertWithExtrasTest) {
      // Android seems to be always calling through `insertWithExtras`
      expect(uri, insertWithExtrasTest);
      expect(values, Stubs.contentValues);
      expect(extras, Stubs.sql_extras);
      return Stubs.string;
    } else {
      return super.insertWithExtras(uri, values, extras);
    }
  }

  @override
  Future<void> onCallingPackageChanged() async {
    if (recordningCallingInfo) {
      callingInfo.add({
        'getCallingAttributionTag': await getCallingAttributionTag(),
        'getCallingPackage': await getCallingPackage(),
        'getCallingPackageUnchecked': await getCallingPackageUnchecked(),
      });
    }
  }

  @override
  void onLowMemory() {
    // Not testable
  }

  @override
  void onTrimMemory(int level) {
    // Not testable
  }

  @override
  Future<String?> openFile(String uri, String mode) {
    // TODO: testing `openFile` and `openFileWithSignal` requires exposing Java APIs for reading and writing files
    return super.openFile(uri, mode);
  }

  @override
  Future<String?> openFileWithSignal(
    String uri,
    String mode,
    ReceivedCancellationSignal? cancellationSignal,
  ) {
    // TODO: testing `openFile` and `openFileWithSignal` requires exposing Java APIs for reading and writing files
    return super.openFileWithSignal(uri, mode, cancellationSignal);
  }

  @override
  Future<CursorData?> query(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
  ) async {
    expect(uri, providerUri);
    expect(projection, selectionArgs);
    expect(selection, Stubs.string);
    expect(selectionArgs, selectionArgs);
    expect(sortOrder, Stubs.string);
    final cursorData = MatrixCursorData(
      columnNames: Stubs.query_columnNames,
      notificationUris: [providerUri],
    )..extras = Stubs.bundle;
    cursorData.addRow(Stubs.query_rowData);
    return cursorData;
  }

  @override
  Future<CursorData?> queryWithSignal(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
    ReceivedCancellationSignal? cancellationSignal,
  ) async {
    if (cancellationSignal == null) {
      return query(uri, projection, selection, selectionArgs, sortOrder);
    } else {
      await waitForSignal(cancellationSignal);
      return query(uri, projection, selection, selectionArgs, sortOrder);
    }
  }

  @override
  Future<CursorData?> queryWithExtras(
    String uri,
    List<String>? projection,
    BundleMap? queryArgs,
    ReceivedCancellationSignal? cancellationSignal,
  ) async {
    if (uri == queryWithExtrasTest) {
      // Android seems to be always calling through `queryWithExtras`
      expect(uri, queryWithExtrasTest);
      expect(projection, Stubs.stringList);
      expect(queryArgs, Stubs.sql_extras);
      await waitForSignal(cancellationSignal!);
      final cursorData = MatrixCursorData(
        columnNames: Stubs.query_columnNames,
        notificationUris: [providerUri],
      )..extras = Stubs.bundle;
      cursorData.addRow(Stubs.query_rowData);
      return cursorData;
    } else if (uri == queryCursorInvalidNotificationUriTest) {
      final cursorData = MatrixCursorData(
        columnNames: Stubs.query_columnNames,
        notificationUris: ['queryCursorInvalidNotificationUri'],
      )..extras = Stubs.bundle;
      cursorData.addRow(Stubs.query_rowData);
      return cursorData;
    } else if (uri == nullableCursorTest) {
      final cursorData = MatrixCursorData(
        columnNames: Stubs.query_columnNames,
        notificationUris: [providerUri],
      )..extras = Stubs.bundle;
      cursorData.addRow(Stubs.query_rowDataAllNulls);
      return cursorData;
    } else {
      return super.queryWithExtras(
        uri,
        projection,
        queryArgs,
        cancellationSignal,
      );
    }
  }

  @override
  Future<bool> refresh(
    String uri,
    BundleMap? extras,
    ReceivedCancellationSignal? cancellationSignal,
  ) async {
    expect(uri, providerUri);
    expect(extras, Stubs.bundle);
    await waitForSignal(cancellationSignal!);
    return true;
  }

  @override
  Future<String?> uncanonicalize(String url) async {
    expect(url, providerUri);
    return Stubs.string;
  }

  @override
  Future<int> update(
    String uri,
    ContentValues? values,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    expect(uri, providerUri);
    expect(values, Stubs.contentValues);
    expect(selection, Stubs.string);
    expect(selectionArgs, Stubs.stringList);
    return Stubs.number;
  }

  @override
  Future<int> updateWithExtras(
    String uri,
    ContentValues? values,
    BundleMap? extras,
  ) async {
    if (uri == updateWithExtrasTest) {
      // Android seems to be always calling through `updateWithExtras`
      expect(uri, updateWithExtrasTest);
      expect(values, Stubs.contentValues);
      expect(extras, Stubs.sql_extras);
      return Stubs.number;
    } else {
      return super.updateWithExtras(uri, values, extras);
    }
  }

  Future<void> waitForSignal(ReceivedCancellationSignal cancellationSignal) {
    final completer = Completer<void>();
    cancellationSignal.setCancelListener(() {
      completer.complete();
    });
    return completer.future.timeout(const Duration(seconds: 10));
  }
}
