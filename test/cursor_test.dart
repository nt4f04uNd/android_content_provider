import 'package:android_content_provider/android_content_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeContentObserver extends ContentObserver {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeCursor', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.nt4f04und.android_content_provider/Cursor/id'),
        (call) {
          return null;
          // no-op
        },
      );
    });

    test('toString', () {
      final cursor = NativeCursor.fromId('id');
      expect(cursor.toString(), 'NativeCursor(id)');
      cursor.close();
    });

    test('batch commitRange throws with invalid ranges', () {
      final cursor = NativeCursor.fromId('id');
      final batch = cursor.batchedGet();
      expect(() => batch.commitRange(0, 0), returnsNormally);
      expect(() => batch.commitRange(0, -1), throwsAssertionError);
      expect(() => batch.commitRange(-1, 0), throwsAssertionError);
      cursor.close();
    });

    test('cursor and batch methods throw when closed, except close() itself',
        () {
      int callCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.nt4f04und.android_content_provider/Cursor/id'),
        (call) {
          callCount += 1;
          expect(call.method, 'close');
          return null;
        },
      );
      final cursor = NativeCursor.fromId('id');
      final batch = cursor.batchedGet();

      // check the batch returns normally
      expect(() => batch.getCount(), returnsNormally);
      // check the cursor close returns normally
      expect(() => cursor.close(), returnsNormally);
      // check subsequent cursor close return normally
      expect(() => cursor.close(), returnsNormally);
      // check other methods throw
      expect(() => cursor.move(0), throwsAssertionError);
      expect(() => cursor.moveToPosition(0), throwsAssertionError);
      expect(() => cursor.moveToFirst(), throwsAssertionError);
      expect(() => cursor.moveToLast(), throwsAssertionError);
      expect(() => cursor.moveToNext(), throwsAssertionError);
      expect(() => cursor.moveToPrevious(), throwsAssertionError);
      expect(
        () => cursor.registerContentObserver(FakeContentObserver()),
        throwsAssertionError,
      );
      expect(
        () => cursor.unregisterContentObserver(FakeContentObserver()),
        throwsAssertionError,
      );
      expect(() => cursor.setNotificationUri(''), throwsAssertionError);
      expect(() => cursor.setNotificationUris([]), throwsAssertionError);
      expect(() => cursor.getNotificationUri(), throwsAssertionError);
      expect(() => cursor.getNotificationUris(), throwsAssertionError);
      expect(() => cursor.setExtras(const {}), throwsAssertionError);
      expect(() => cursor.getExtras(), throwsAssertionError);
      expect(() => cursor.respond(const {}), throwsAssertionError);
      expect(() => cursor.batchedGet(), throwsAssertionError);

      // check the batch throws
      expect(() => batch.commit(), throwsAssertionError);
      expect(() => batch.commitRange(0, 0), throwsAssertionError);
      expect(() => batch.getCount(), throwsAssertionError);
      expect(() => batch.getPosition(), throwsAssertionError);
      expect(() => batch.isFirst(), throwsAssertionError);
      expect(() => batch.isLast(), throwsAssertionError);
      expect(() => batch.isBeforeFirst(), throwsAssertionError);
      expect(() => batch.isAfterLast(), throwsAssertionError);
      expect(() => batch.getColumnIndex(''), throwsAssertionError);
      expect(() => batch.getColumnIndexOrThrow(''), throwsAssertionError);
      expect(() => batch.getColumnName(0), throwsAssertionError);
      expect(() => batch.getColumnNames(), throwsAssertionError);
      expect(() => batch.getColumnCount(), throwsAssertionError);
      expect(() => batch.getBytes(0), throwsAssertionError);
      expect(() => batch.getString(0), throwsAssertionError);
      expect(() => batch.getShort(0), throwsAssertionError);
      expect(() => batch.getInt(0), throwsAssertionError);
      expect(() => batch.getLong(0), throwsAssertionError);
      expect(() => batch.getFloat(0), throwsAssertionError);
      expect(() => batch.getDouble(0), throwsAssertionError);
      expect(() => batch.getType(0), throwsAssertionError);
      expect(() => batch.isNull(0), throwsAssertionError);

      expect(callCount, 1);

      cursor.close();
    });
  });

  group('MatrixCursorData', () {
    MatrixCursorData createData() => MatrixCursorData(
          columnNames: ['column'],
          notificationUris: ['uri'],
        );

    test('constructor and properties', () {
      final data = createData();
      expect(data.columnNames, ['column']);
      expect(() => data.columnNames[0] = 'value', throwsUnsupportedError);
      expect(data.notificationUris, ['uri']);

      expect(data.extras, null);
      data.extras = {};
      expect(data.extras, <String, Object?>{});

      expect(data.payload, <String, Object>{
        'columnNames': ['column'],
        'data': <Object>[],
        'rowCount': 0,
      });
    });

    test('addRow', () {
      final data = createData();
      data.addRow(['value']);
      final payload = data.payload as BundleMap;
      expect(payload['data'], ['value']);
      expect(payload['rowCount'], 1);
      expect(
        () => data.addRow(['value', 'value that exceeds the row']),
        throwsA(
          isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains(
                  'The `columnValues` parameter must have the same length as `columnNames`')),
        ),
      );
    });

    test('newRow', () {
      final data = createData();
      final builder = data.newRow();
      builder.add('value');
      final payload = data.payload as BundleMap;
      expect(payload['data'], ['value']);
      expect(payload['rowCount'], 1);
      expect(
        () => builder.add('value'),
        throwsA(isA<CursorRangeError>().having(
          (e) => e.message,
          'message',
          'No more columns left.',
        )),
      );
    });

    test('serialization', () {
      final data = createData();
      expect(() => data.toMap()..['key'] = 'value', throwsUnsupportedError);
    });
  });
}
