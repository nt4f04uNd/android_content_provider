// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:typed_data';

// I use it to use `expect` outside of tests
// ignore: implementation_imports
import 'package:test_api/src/expect/async_matcher.dart';
// ignore: implementation_imports
import 'package:test_api/src/expect/util/pretty_print.dart';

import 'package:flutter/foundation.dart';
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
    // will only overflow in dart
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
}

const authority =
    'com.nt4f04und.android_content_provider_integration_test.IntegrationTestAndroidContentProvider';
const providerUri = 'content://$authority';

const overflowingContentValuesTest =
    providerUri + '/overflowingContentValuesTest';
const deleteWithExtrasTest = providerUri + '/deleteWithExtras';
const insertWithExtrasTest = providerUri + '/insertWithExtras';
const queryWithExtrasTest = providerUri + '/queryWithExtras';
const updateWithExtrasTest = providerUri + '/updateWithExtras';

typedef OnChangeCallback = void Function(
  bool selfChange,
  String? uri,
  int? flags,
);
typedef OnChangeUrisCallback = void Function(
  bool selfChange,
  List<String> uris,
  int? flags,
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
  void onChange(bool selfChange, String? uri, int? flags) {
    _onChange?.call(selfChange, uri, flags);
  }

  @override
  void onChangeUris(bool selfChange, List<String> uris, int? flags) {
    _onChangeUris?.call(selfChange, uris, flags);
  }
}

void main() {
  testWidgets("ContentValues overflow", (WidgetTester tester) async {
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
      onChange: (bool selfChange, String? uri, int? flags) {
        // Android seems to be always calling through `onChangeUris`.
        fail('onChange is not expected to be called');
        // Can't really test this, so test only onChangeUris.
      },
      onChangeUris: (bool selfChange, List<String> uris, int? flags) {
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
    testWidgets("getTypeInfo", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.getTypeInfo(
        mimeType: 'image/png',
      );
      expect(result, isNotNull);
      expect(result!.label, "PNG image");
      expect(result.icon, hasLength(greaterThan(100)));
      expect(result.contentDescription, "PNG image");
    });

    // TODO: testing `loadThumbnail` requires exposing [AndroidContentProvider.openTypedAssetFile]
    // testWidgets("loadThumbnail", (WidgetTester tester) async {
    //   final result = await AndroidContentResolver.instance.loadThumbnail(
    //     uri: providerUri,
    //     height: 100,
    //     width: 100,
    //     cancellationSignal: CancellationSignal()..cancel(),
    //   );
    //   expect(result, hasLength(greaterThan(100)));
    // });

    testWidgets("ContentObserver and notifyChange work",
        (WidgetTester tester) async {
      const flags = 1 | 2 | 4 | 8 | 16;
      int calledCounter = 0;
      bool notifyForDescendantsTest = false;
      final observer = TestContentObserver(
        onChange: (bool selfChange, String? uri, int? flags) {
          // Android seems to be always calling through `onChangeUris`
          fail('onChange is not expected to be called');
        },
        onChangeUris: (bool selfChange, List<String> uris, int? flags) {
          calledCounter += 1;
          if (calledCounter == 1) {
            // Not self change
            expect(selfChange, false);
            expect(uris, [
              notifyForDescendantsTest
                  ? providerUri + '/descendantUriShouldNotify'
                  : providerUri
            ]);
            expect(flags, flags);
          } else if (calledCounter == 2) {
            // Self change
            expect(selfChange, true);
            expect(uris, [providerUri]);
            expect(flags, flags);
          } else if (calledCounter == 3) {
            // List of URIs
            expect(selfChange, false);
            expect(uris, [providerUri, providerUri, providerUri]);
            expect(flags, flags);
          } else {
            fail("Observer wasn't unregistered");
          }
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
          uris: [providerUri + '/descendantUriShouldNotNotify'],
          flags: flags,
        );
      } finally {
        await AndroidContentResolver.instance
            .unregisterContentObserver(observer);
      }
      await AndroidContentResolver.instance.notifyChange(
        uri: providerUri,
      );

      expect(calledCounter, 3);
      calledCounter = 0;

      // notifyForDescendants=true test
      notifyForDescendantsTest = true;
      await AndroidContentResolver.instance.registerContentObserver(
        uri: providerUri,
        observer: observer,
        notifyForDescendants: true,
      );
      try {
        await AndroidContentResolver.instance.notifyChangeWithList(
          uris: [providerUri + '/descendantUriShouldNotify'],
          flags: flags,
        );
      } finally {
        await AndroidContentResolver.instance
            .unregisterContentObserver(observer);
      }
      expect(calledCounter, 1);
    });
  });

  // group("AndroidContentProvider", () {
  //   testWidgets("___", (WidgetTester tester) async {

  //   });
  // });

  group("AndroidContentProvider/AndroidContentResolver", () {
    testWidgets("bulkInsert", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.bulkInsert(
        uri: providerUri,
        values: Stubs.contentValuesList,
      );
      expect(result, Stubs.number);
    });

    testWidgets("call", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.call(
        uri: providerUri,
        method: Stubs.string,
        arg: Stubs.string,
        extras: Stubs.bundle,
      );
      expect(result, Stubs.bundle);
    });

    testWidgets("callWithAuthority", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.callWithAuthority(
        authority: authority,
        method: Stubs.string,
        arg: Stubs.string,
        extras: Stubs.bundle,
      );
      expect(result, Stubs.bundle);
    });

    testWidgets("canonicalize", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.canonicalize(
        url: providerUri,
      );
      expect(result, Stubs.string);
    });

    testWidgets("delete", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.delete(
        uri: providerUri,
        selection: Stubs.string,
        selectionArgs: Stubs.stringList,
      );
      expect(result, Stubs.number);
    });

    testWidgets("deleteWithExtras", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.deleteWithExtras(
        uri: deleteWithExtrasTest,
        extras: Stubs.sql_extras,
      );
      expect(result, Stubs.number);
    });

    testWidgets("getStreamTypes", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.getStreamTypes(
        uri: providerUri,
        mimeTypeFilter: Stubs.string,
      );
      expect(result, Stubs.stringList);
    });

    testWidgets("getType", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.getType(
        uri: providerUri,
      );
      expect(result, Stubs.string);
    });

    testWidgets("insert", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.insert(
        uri: providerUri,
        values: Stubs.contentValues,
      );
      expect(result, Stubs.string);
    });

    testWidgets("insertWithExtras", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.insertWithExtras(
        uri: insertWithExtrasTest,
        values: Stubs.contentValues,
        extras: Stubs.sql_extras,
      );
      expect(result, Stubs.string);
    });

    testWidgets("query and queryWithExtras", (WidgetTester tester) async {
      Future<void> doTest(NativeCursor? cursor) async {
        expect(cursor, isNotNull);
        try {
          final expectedColumnCount = Stubs.query_columnNames.length;
          while (await cursor!.moveToNext()) {
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
            final results = await batch.commit();
            expect(results, <Object?>[
              1, // getCount
              0, // getPosition
              true, // isFirst
              true, // isLast
              false, // isBeforeFirst
              false, // isAfterLast
              // getColumnIndex
              ...List.generate(expectedColumnCount, (index) => index),
              -1,
              ...Stubs.query_columnNames, // getColumnName
              Stubs.query_columnNames, // getColumnNames
              expectedColumnCount, // getColumnCount
              // get___ methods
              ...[...List.from(Stubs.query_rowData)..removeLast(), true],
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
        } finally {
          await cursor!.close();
        }
      }

      await doTest(await AndroidContentResolver.instance.query(
        uri: providerUri,
        projection: Stubs.stringList,
        selection: Stubs.string,
        selectionArgs: Stubs.stringList,
        sortOrder: Stubs.string,
      ));

      await doTest(await AndroidContentResolver.instance.queryWithSignal(
        uri: providerUri,
        projection: Stubs.stringList,
        selection: Stubs.string,
        selectionArgs: Stubs.stringList,
        sortOrder: Stubs.string,
        cancellationSignal: CancellationSignal()..cancel(),
      ));

      await doTest(await AndroidContentResolver.instance.queryWithExtras(
        uri: queryWithExtrasTest,
        projection: Stubs.stringList,
        queryArgs: Stubs.sql_extras,
        cancellationSignal: CancellationSignal()..cancel(),
      ));
    });

    testWidgets("refresh", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.refresh(
        uri: providerUri,
        extras: Stubs.bundle,
        cancellationSignal: CancellationSignal()..cancel(),
      );
      expect(result, true);
    });

    testWidgets("uncanonicalize", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.uncanonicalize(
        url: providerUri,
      );
      expect(result, Stubs.string);
    });

    testWidgets("update", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.update(
        uri: providerUri,
        values: Stubs.contentValues,
        selection: Stubs.string,
        selectionArgs: Stubs.stringList,
      );
      expect(result, Stubs.number);
    });

    testWidgets("updateWithExtras", (WidgetTester tester) async {
      final result = await AndroidContentResolver.instance.updateWithExtras(
        uri: updateWithExtrasTest,
        values: Stubs.contentValues,
        extras: Stubs.sql_extras,
      );
      expect(result, Stubs.number);
    });
  });
}

@pragma('vm:entry-point')
void integrationTestContentProviderEntrypoint() async {
  IntegrationTestAndroidContentProvider();
}

class IntegrationTestAndroidContentProvider extends AndroidContentProvider {
  IntegrationTestAndroidContentProvider() : super(authority);

  @override
  Future<int> bulkInsert(String uri, List<ContentValues> values) async {
    if (uri == overflowingContentValuesTest) {
      final actual = values.first.values.toList();
      final expected = Stubs.overflowingContentValues.values.toList();
      _expect(actual.length, expected.length);
      // check values that  overflow only in Java
      for (int i = 0; i < 3; i++) {
        _expect(actual[i], isNot(equals(expected[i])));
      }
      // check values that overflow both in Dart and java
      for (int i = 4; i < 5; i++) {
        _expect(actual.last, expected.last);
      }
    } else {
      _expect(uri, providerUri);
      _expect(values, Stubs.contentValuesList);
    }
    return Stubs.number;
  }

  @override
  Future<BundleMap?> call(String method, String? arg, BundleMap? extras) async {
    _expect(method, Stubs.string);
    _expect(arg, Stubs.string);
    _expect(extras, Stubs.bundle);
    return Stubs.bundle;
  }

  @override
  Future<BundleMap?> callWithAuthority(
    String authority,
    String method,
    String? arg,
    BundleMap? extras,
  ) async {
    _expect(authority, authority);
    _expect(method, Stubs.string);
    _expect(arg, Stubs.string);
    _expect(extras, Stubs.bundle);
    return Stubs.bundle;
  }

  @override
  Future<String?> canonicalize(String url) async {
    _expect(url, providerUri);
    return Stubs.string;
  }

  @override
  Future<int> delete(
    String uri,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    _expect(uri, providerUri);
    _expect(selection, Stubs.string);
    _expect(selectionArgs, Stubs.stringList);
    return Stubs.number;
  }

  @override
  Future<int> deleteWithExtras(String uri, BundleMap? extras) async {
    if (uri == deleteWithExtrasTest) {
      // Android seems to be always calling through `deleteWithExtrasTest`
      _expect(uri, deleteWithExtrasTest);
      _expect(extras, Stubs.sql_extras);
      return Stubs.number;
    } else {
      return super.deleteWithExtras(uri, extras);
    }
  }

  @override
  Future<List<String>?> getStreamTypes(
      String uri, String mimeTypeFilter) async {
    _expect(uri, providerUri);
    _expect(mimeTypeFilter, Stubs.string);
    return Stubs.stringList;
  }

  @override
  Future<String?> getType(String uri) async {
    _expect(uri, providerUri);
    return Stubs.string;
  }

  @override
  Future<String?> insert(String uri, ContentValues? values) async {
    _expect(uri, providerUri);
    _expect(values, Stubs.contentValues);
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
      _expect(uri, insertWithExtrasTest);
      _expect(values, Stubs.contentValues);
      _expect(extras, Stubs.sql_extras);
      return Stubs.string;
    } else {
      return super.insertWithExtras(uri, values, extras);
    }
  }

  @override
  Future<CursorData?> query(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
  ) async {
    _expect(uri, providerUri);
    _expect(projection, selectionArgs);
    _expect(selection, Stubs.string);
    _expect(selectionArgs, selectionArgs);
    _expect(sortOrder, Stubs.string);
    final cursorData = MatrixCursorData(
      columnNames: Stubs.query_columnNames,
      notificationUris: null,
    );
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
      _expect(uri, queryWithExtrasTest);
      _expect(projection, Stubs.stringList);
      _expect(queryArgs, Stubs.sql_extras);
      await waitForSignal(cancellationSignal!);
      final cursorData = MatrixCursorData(
        columnNames: Stubs.query_columnNames,
        notificationUris: null,
      );
      cursorData.addRow(Stubs.query_rowData);
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
    _expect(uri, providerUri);
    _expect(extras, Stubs.bundle);
    await waitForSignal(cancellationSignal!);
    return true;
  }

  @override
  Future<String?> uncanonicalize(String url) async {
    _expect(url, providerUri);
    return Stubs.string;
  }

  @override
  Future<int> update(
    String uri,
    ContentValues? values,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    _expect(uri, providerUri);
    _expect(values, Stubs.contentValues);
    _expect(selection, Stubs.string);
    _expect(selectionArgs, Stubs.stringList);
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
      _expect(uri, updateWithExtrasTest);
      _expect(values, Stubs.contentValues);
      _expect(extras, Stubs.sql_extras);
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

  String formatFailure(Matcher expected, actual, String which,
      {String? reason}) {
    var buffer = StringBuffer();
    buffer.writeln(indent(prettyPrint(expected), first: 'Expected: '));
    buffer.writeln(indent(prettyPrint(actual), first: '  Actual: '));
    if (which.isNotEmpty) buffer.writeln(indent(which, first: '   Which: '));
    if (reason != null) buffer.writeln(reason);
    return buffer.toString();
  }

  String formatter(actual, matcher, matchState, verbose) {
    var mismatchDescription = StringDescription();
    matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);

    return formatFailure(matcher, actual, mismatchDescription.toString());
  }

  dynamic _expect(actual, matcher) {
    matcher = wrapMatcher(matcher);

    if (matcher is AsyncMatcher) {
      // Avoid async/await so that expect() throws synchronously when possible.
      var result = matcher.matchAsync(actual);
      expect(
          result,
          anyOf([
            equals(null),
            const TypeMatcher<Future>(),
            const TypeMatcher<String>()
          ]),
          reason: 'matchAsync() may only return a String, a Future, or null.');

      if (result is String) {
        fail(formatFailure(matcher, actual, result));
      } else if (result is Future) {
        return result.then((realResult) {
          if (realResult == null) {
            return;
          }
          fail(formatFailure(
            matcher as Matcher,
            actual,
            realResult as String,
          ));
        });
      }

      return Future.sync(() {});
    }

    var matchState = {};

    if ((matcher as Matcher).matches(actual, matchState)) {
      return Future.sync(() {});
    }
    fail(formatter(actual, matcher, matchState, false));
  }
}
