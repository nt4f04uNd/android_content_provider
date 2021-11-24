// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

// I use it to use `expect` outside of tests
// ignore: implementation_imports
import 'package:test_api/src/expect/async_matcher.dart';
// ignore: implementation_imports
import 'package:test_api/src/expect/util/pretty_print.dart';

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
    AndroidContentResolver.QUERY_ARG_SQL_SELECTION: Stubs.string,
    AndroidContentResolver.QUERY_ARG_SQL_SELECTION_ARGS: Stubs.stringList,
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

void main() {
  testWidgets("ContentValues overflow", (WidgetTester tester) async {
    final result = await AndroidContentResolver.instance.bulkInsert(
      uri: overflowingContentValuesTest,
      values: [Stubs.overflowingContentValues],
    );
    expect(result, Stubs.number);
  });

  group("ContentProvider/ContentResolver", () {
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
        uri: providerUri,
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

    testWidgets("query", (WidgetTester tester) async {
      final cursor = await AndroidContentResolver.instance.query(
        uri: providerUri,
        projection: Stubs.stringList,
        selection: Stubs.string,
        selectionArgs: Stubs.stringList,
        sortOrder: Stubs.string,
      );
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
          expect(results, <Object>[
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
    _expect(uri, providerUri);
    _expect(extras, Stubs.sql_extras);
    return Stubs.number;
  }

  @override
  Future<List<String>?> getStreamTypes(String uri, String mimeTypeFilter) async {
    _expect(uri, providerUri);
    _expect(mimeTypeFilter, Stubs.string);
    return Stubs.stringList;
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
  Future<int> update(
    String uri,
    ContentValues? values,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    return 0;
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
