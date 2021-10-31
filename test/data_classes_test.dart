import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:android_content_provider/android_content_provider.dart';

void main() {
  group('Pair', () {
    test('constructor and properties', () {
      const pair = Pair(1, 2);
      expect(pair.first, 1);
      expect(pair.second, 2);
    });

    test('toString', () {
      const pair = Pair(1, 2);
      expect(pair.toString(), 'Pair(1, 2)');
    });

    test('serialization and equality', () {
      const createPair = Pair<int, int>.fromList;
      final pair = createPair([1, 2]);
      expect(pair, createPair([1, 2]));
      expect(pair, isNot(createPair([2, 2])));
    });
  });

  group('CallingIdentity', () {
    test('toString', () {
      final identity = CallingIdentity.fromMap(<String, Object?>{'id': 0});
      ;
      expect(identity.toString(), 'CallingIdentity(0)');
    });

    test('serialization and equality', () {
      CallingIdentity createIdentity(int id) =>
          CallingIdentity.fromMap(<String, Object?>{'id': id});
      final identity = createIdentity(0);
      expect(identity.id, 0);
      expect(identity, createIdentity(0));
      expect(identity, isNot(createIdentity(1)));
    });
  });

  group('PathPermission', () {
    PathPermission createPathPermission({
      String readPermission = 'com.example.permission.READ',
      String writePermission = 'com.example.permission.WRITE',
    }) =>
        PathPermission.fromMap(<String, dynamic>{
          'readPermission': readPermission,
          'writePermission': writePermission,
        });

    test('constructor and properties', () {
      final pathPermission = createPathPermission();
      expect(pathPermission.readPermission, 'com.example.permission.READ');
      expect(pathPermission.writePermission, 'com.example.permission.WRITE');
    });

    test('toString', () {
      final pathPermission = createPathPermission();
      expect(pathPermission.toString(),
          'PathPermission(read: com.example.permission.READ, write: com.example.permission.WRITE)');
    });

    test('serialization and equality', () {
      final pathPermission = createPathPermission();
      expect(pathPermission, createPathPermission());
      expect(pathPermission,
          isNot(createPathPermission(readPermission: 'other_permission')));
      expect(pathPermission,
          isNot(createPathPermission(writePermission: 'other_permission')));
    });
  });

  group('ContentValues ', () {
    const someKey = 'some_key';
    const someValue = 'some_value';

    final uint8list = Uint8List.fromList([1, 2, 3]);

    ContentValues createValues() {
      final values = ContentValues();
      values.putBool('bool_key', false);
      values.putString('string_key', someValue);
      values.putInt('int_key', 1);
      values.putBytes('bytes_key', uint8list);
      return values;
    }

    test('default constructor creates empty values', () {
      final values = ContentValues();
      expect(values.isEmpty, true);
    });

    test('copyFrom and equality', () {
      final values = ContentValues();
      values.putString(someKey, someValue);
      expect(values, ContentValues.copyFrom(values));
      expect(values, isNot(ContentValues()));
    });

    test('toString', () {
      final values = createValues();
      expect(
        values.toString(),
        '{bool_key: false, string_key: some_value, int_key: 1, bytes_key: [1, 2, 3]}',
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
        ['bool_key', 'string_key', 'int_key', 'bytes_key'],
      );
      expect(
        values.values.toList(),
        [
          false,
          'some_value',
          1,
          [1, 2, 3]
        ],
      );
      expect(
        values.entries.toList().toString(),
        '[MapEntry(bool_key: false), MapEntry(string_key: some_value), MapEntry(int_key: 1), MapEntry(bytes_key: [1, 2, 3])]',
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
