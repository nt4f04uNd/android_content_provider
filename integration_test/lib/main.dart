// ignore_for_file: non_constant_identifier_names

import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:android_content_provider/android_content_provider.dart';

class Stubs {
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

const providerUri =
    'content://com.nt4f04und.android_content_provider_integration_test.IntegrationTestAndroidContentProvider';

void main() {
  testWidgets("query", (WidgetTester tester) async {
    final cursor = await AndroidContentResolver.instance.query(
      providerUri,
      null,
      null,
      null,
      null,
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
        expect(results, [
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
}

@pragma('vm:entry-point')
void integrationTestContentProviderEntrypoint() async {
  IntegrationTestAndroidContentProvider();
}

class IntegrationTestAndroidContentProvider extends AndroidContentProvider {
  IntegrationTestAndroidContentProvider()
      : super(
            'com.nt4f04und.android_content_provider_integration_test.IntegrationTestAndroidContentProvider');

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

  @override
  noSuchMethod(Invocation invocation) {
    final f = invocation;
    return super.noSuchMethod(invocation);
  }
}
