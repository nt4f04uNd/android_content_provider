import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:android_content_provider/android_content_provider.dart';

void main() {
  group('ContentValues ', () {
    const someKey = 'some_key';
    const someValue = 'some_value';

    final uint8list = Uint8List.fromList([1, 2, 3]);

    ContentValues createValues() {
      final values = ContentValues();
      values.putString('string_key', someValue);
      values.putByte('byte_key', 0);
      values.putShort('byte_key', 0);
      values.putInt('int_key', 0);
      values.putLong('long_key', 0);
      values.putFloat('float_key', 0.5);
      values.putDouble('double_key', 0.5);
      values.putBool('bool_key', false);
      values.putBytes('bytes_key', uint8list);
      values.putNull('null_key');
      return values;
    }

    test('default constructor creates empty values', () {
      final values = ContentValues();
      expect(values.isEmpty, true);
    });

    test('equality', () {
      final values = createValues();
      values.putString(someKey, someValue);
      expect(values, ContentValues.copyFrom(values));
      expect(values, isNot(ContentValues()));
    });

    test("copyFrom actually copies values", () {
      final values = ContentValues();
      final copyFrom = ContentValues.copyFrom(values);
      values.putString(someKey, someValue);
      expect(copyFrom.isEmpty, true);
    });

    test('toString', () {
      final values = createValues();
      expect(
        values.toString(),
        '{string_key: some_value, byte_key: 0, int_key: 0, long_key: 0, float_key: 0.5, double_key: 0.5, bool_key: false, bytes_key: [1, 2, 3], null_key: null}',
      );
    });

    test('length, isEmpty, isNotEmpty', () {
      final values = ContentValues();
      expect(values.length, 0);
      expect(values.isEmpty, true);
      expect(values.isNotEmpty, false);
      values.putString(someKey, someValue);
      expect(values.length, 1);
      expect(values.isEmpty, false);
      expect(values.isNotEmpty, true);
    });

    test('keys, values, entries', () {
      final values = createValues();
      expect(
        values.keys.toList(),
        [
          'string_key',
          'byte_key',
          'int_key',
          'long_key',
          'float_key',
          'double_key',
          'bool_key',
          'bytes_key',
          'null_key'
        ],
      );
      expect(
        values.values.toList(),
        [
          'some_value',
          0,
          0,
          0,
          0.5,
          0.5,
          false,
          [1, 2, 3],
          null
        ],
      );
      expect(
        values.entries.toList().toString(),
        '[MapEntry(string_key: some_value), MapEntry(byte_key: 0), MapEntry(int_key: 0), MapEntry(long_key: 0), MapEntry(float_key: 0.5), MapEntry(double_key: 0.5), MapEntry(bool_key: false), MapEntry(bytes_key: [1, 2, 3]), MapEntry(null_key: null)]',
      );
    });

    test('containsKey', () {
      final values = ContentValues();
      values.putString(someKey, someValue);
      expect(values.containsKey(someKey), true);
      expect(values.containsKey('some_other_key'), false);
    });

    test('remove', () {
      final values = ContentValues();
      values.putString(someKey, someValue);
      expect(values.remove(someKey), someValue);
      expect(values.remove('some_other_key'), null);
    });

    test('clear', () {
      final values = createValues();
      expect(values.isEmpty, false);
      values.clear();
      expect(values.isEmpty, true);
    });

    test('put/get string', () {
      final values = ContentValues();
      values.putString(someKey, someValue);
      expect(values.getString(someKey), someValue);
    });

    test('byte', () {
      final values = ContentValues();
      values.putByte(someKey, 0);
      expect(values.getInt(someKey), 0);
    });

    test('short', () {
      final values = ContentValues();
      values.putShort(someKey, 0);
      expect(values.getInt(someKey), 0);
    });

    test('int', () {
      final values = ContentValues();
      values.putInt(someKey, 0);
      expect(values.getInt(someKey), 0);
    });

    test('long', () {
      final values = ContentValues();
      values.putLong(someKey, 0);
      expect(values.getInt(someKey), 0);
    });

    test('float', () {
      final values = ContentValues();
      values.putFloat(someKey, 0.5);
      expect(values.getDouble(someKey), 0.5);
    });

    test('double', () {
      final values = ContentValues();
      values.putDouble(someKey, 0.5);
      expect(values.getDouble(someKey), 0.5);
    });

    test('bool', () {
      final values = ContentValues();
      values.putBool(someKey, true);
      expect(values.getBool(someKey), true);
    });

    test('bytes', () {
      final values = ContentValues();
      values.putBytes(someKey, uint8list);
      expect(values.getBytes(someKey), uint8list);
    });
  });
}
