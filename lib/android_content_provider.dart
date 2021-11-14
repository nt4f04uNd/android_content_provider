import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:meta/meta.dart';

const _uuid = Uuid();
const _channelPrefix = 'com.nt4f04und.android_content_provider';

/// The android_content_provider plugin binding.
///
/// Allows to create set a factory for [AndroidContentProvider]s.
abstract class AndroidContentProviderPlugin {
  AndroidContentProviderPlugin._();

  static const _pluginMethodCodec =
      StandardMethodCodec(AndroidContentProviderMessageCodec());

  static const _methodChannel = MethodChannel('$_channelPrefix/plugin');

  static late final StreamController<String> _onCreateStreamController =
      StreamController();

  static Future<void> _handleMethodCall(MethodCall call) async {
    final BundleMap? args = (call.arguments as Map?)?.cast<String, Object?>();
    switch (call.method) {
      case 'createContentProvider':
        _onCreateStreamController.add(args!['authority']! as String);
        break;
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Method not implemented: ${call.method}',
        );
    }
  }

  /// Sets up a factory to create [AndroidContentProvider]s from the platform requests
  /// when the native ContentProvider `onCreate` is called.
  ///
  /// Call this from the `androidContentProviderEntrypoint` function if you use the
  /// [AndroidContentProvider].
  static void setUp({required AndroidContentProviderFactory factory}) {
    WidgetsFlutterBinding.ensureInitialized();
    if (_onCreateStreamController.hasListener) {
      throw StateError(
          "AndroidContentProviderPlugin has already been set up for this engine");
    }
    _onCreateStreamController.stream.listen(factory);
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }
}

/// Signature for [AndroidContentProviderPlugin.setup] listener argument.
typedef AndroidContentProviderFactory = AndroidContentProvider Function(
    String authority);

/// Annotation on [AndroidContentProvider] methods that indicates that the method
/// is has a default native implmentation and can be called by dart code to perform some action or
/// receive data.
///
/// In contrast, platform will never call these callbacks in dart, so overriding
/// on dart side affects only dart side.
const native = _Native();

class _Native {
  const _Native();
}

/// Map type alias that is used in place of Android Bundle
/// https://developer.android.com/reference/android/os/Bundle.
typedef BundleMap = Map<String, Object?>;

/// Opaque token representing the identity of an incoming IPC.
class CallingIdentity extends Interoperable {
  /// Creates native cursor from an existing ID.
  @internal
  CallingIdentity.fromId(String id) : super.fromId(id);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'CallingIdentity')}($id)';
  }
}

/// Description of permissions needed to access a particular path in a content provider
/// https://developer.android.com/reference/kotlin/android/content/pm/PathPermission
///
/// See also https://developer.android.com/guide/topics/manifest/path-permission-element
/// on how to declare these paths.
class PathPermission {
  /// Creates a [PathPermission].
  const PathPermission({
    this.readPermission,
    this.writePermission,
  });

  /// Read permission.
  /// For example "com.example.permission.READ".
  final String? readPermission;

  /// Write permission.
  /// For example "com.example.permission.WRITE".
  final String? writePermission;

  @override
  bool operator ==(Object other) {
    return other is PathPermission &&
        other.readPermission == readPermission &&
        other.writePermission == writePermission;
  }

  @override
  int get hashCode => hashValues(readPermission, writePermission);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'PathPermission')}(read: $readPermission, write: $writePermission)';
  }

  /// Creates path permissions from map.
  factory PathPermission.fromMap(BundleMap map) => PathPermission(
        readPermission: map['readPermission'] as String?,
        writePermission: map['writePermission'] as String?,
      );

  /// Converts the path permissions to map.
  BundleMap toMap() => BundleMap.unmodifiable(<String, Object?>{
        'readPermission': readPermission,
        'writePermission': writePermission,
      });
}

/// This class is used to store a set of values that the content provider/resolver can process
/// https://developer.android.com/reference/android/content/ContentValues
class ContentValues {
  /// Creates [ContentValues].
  ContentValues() : _map = <String, Object?>{};
  ContentValues._(this._map);

  /// Copies values from other [ContentValues] instances.
  ContentValues.copyFrom(ContentValues other) : _map = Map.from(other._map);

  /// Content values map.
  final Map<String, Object?> _map;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ContentValues &&
        mapEquals<Object?, Object?>(_map, other._map);
  }

  @override
  int get hashCode => hashList(_map.values);

  @override
  String toString() {
    final buffer = StringBuffer('{');
    bool first = true;
    for (final entry in entries) {
      if (!first) {
        buffer.write(', ');
      }
      first = false;
      buffer.write(entry.key);
      buffer.write(': ');
      buffer.write(entry.value);
    }
    buffer.write('}');
    return buffer.toString();
  }

  /// The number of values.
  int get length => _map.length;

  /// Whether this collection is empty.
  bool get isEmpty => _map.isEmpty;

  /// Whether there is at least one value in this collection.
  bool get isNotEmpty => _map.isNotEmpty;

  /// The keys of these [ContentValues].
  Iterable<String> get keys => _map.keys;

  /// The values of these [ContentValues].
  Iterable<Object?> get values {
    return _map.values.map((Object? value) => _maybeUnwrapValue(value));
  }

  /// The entries of these [ContentValues].
  Iterable<MapEntry<String, Object?>> get entries {
    return keys.map((String key) =>
        MapEntry<String, Object?>(key, _maybeUnwrapValue(_map[key])));
  }

  // Unwraps the values and returns a primitive.
  Object? _maybeUnwrapValue(Object? value) {
    if (value is _Byte) {
      value = value.value;
    } else if (value is _Short) {
      value = value.value;
    } else if (value is _Long) {
      value = value.value;
    } else if (value is _Float) {
      value = value.value;
    }
    return value;
  }

  /// Returns true if this object has a value by given [key].
  bool containsKey(String key) {
    return _map.containsKey(key);
  }

  /// Removes [key] and its associated value, if present, from the map.
  ///
  /// Returns the value associated with [key] before it was removed.
  Object? remove(String key) {
    return _map.remove(key);
  }

  /// Removes all values.
  void clear() {
    _map.clear();
  }

  /// Adds the string [value] to the set by the given [key].
  void putString(String key, String? value) {
    _map[key] = value;
  }

  /// Adds the byte [value] to the set by the given [key].
  void putByte(String key, int? value) {
    _map[key] = value == null ? null : _Byte(value);
  }

  /// Adds the short [value] to the set by the given [key].
  void putShort(String key, int? value) {
    _map[key] = value == null ? null : _Short(value);
  }

  /// Adds the integer [value] to the set by the given [key].
  void putInt(String key, int? value) {
    _map[key] = value;
  }

  /// Adds the long [value] to the set by the given [key].
  void putLong(String key, int? value) {
    _map[key] = value == null ? null : _Long(value);
  }

  /// Adds the float [value] to the set by the given [key].
  void putFloat(String key, double? value) {
    _map[key] = value == null ? null : _Float(value);
  }

  /// Adds the double [value] to the set by the given [key].
  void putDouble(String key, double? value) {
    _map[key] = value;
  }

  /// Adds the bool [value] to the set by the given [key].
  void putBool(String key, bool? value) {
    _map[key] = value;
  }

  /// Adds the byte array [value] to the set by the given [key].
  void putBytes(String key, Uint8List? value) {
    _map[key] = value;
  }

  /// Adds a null value to the set by the given [key].
  void putNull(String key) {
    _map[key] = null;
  }

  /// Gets a value by the given [key].
  Object? getObject(String key) {
    return _maybeUnwrapValue(_map[key]);
  }

  /// Gets a string value by the given [key].
  String? getString(String key) {
    return _maybeUnwrapValue(_map[key]) as String?;
  }

  /// Gets an int value by the given [key].
  ///
  /// Java's integer number type can be used with this method:
  ///  * Byte
  ///  * Short
  ///  * Integer
  ///  * Long
  int? getInt(String key) {
    return _maybeUnwrapValue(_map[key]) as int?;
  }

  /// Gets a double value by the given [key].
  ///
  /// Java's floating number type can be used with this method:
  ///  * Float
  ///  * Double
  double? getDouble(String key) {
    return _maybeUnwrapValue(_map[key]) as double?;
  }

  /// Gets a bool value by the given [key].
  bool? getBool(String key) {
    return _maybeUnwrapValue(_map[key]) as bool?;
  }

  /// Gets a byte array value by the given [key].
  Uint8List? getBytes(String key) {
    return _maybeUnwrapValue(_map[key]) as Uint8List?;
  }
}

class _NumberWrapper<T extends num> {
  const _NumberWrapper(this.value);

  /// Wrapped number value.
  final T value;

  @override
  bool operator ==(Object other) {
    return other is num && other == value ||
        other is _NumberWrapper && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// A wrapper for value in [ContentValues.putByte].
class _Byte extends _NumberWrapper<int> {
  const _Byte(int value) : super(value);

  @override
  String toString() {
    return '${objectRuntimeType(this, '_Byte')}($value)';
  }
}

/// A wrapper for value in [ContentValues.putShort].
class _Short extends _NumberWrapper<int> {
  const _Short(int value) : super(value);

  @override
  String toString() {
    return '${objectRuntimeType(this, '_Short')}($value)';
  }
}

//
// [ContentValues.putInt] - integers a stored just as `int`
//

/// A wrapper for value in [ContentValues.putLong].
class _Long extends _NumberWrapper<int> {
  const _Long(int value) : super(value);

  @override
  String toString() {
    return '${objectRuntimeType(this, '_Long')}($value)';
  }
}

/// A wrapper for value in [ContentValues.putFloat].
class _Float extends _NumberWrapper<double> {
  const _Float(double value) : super(value);

  @override
  String toString() {
    return '${objectRuntimeType(this, '_Float')}($value)';
  }
}

//
// [ContentValues.putDouble] - doubles a stored just as `double`
//

/// The codec utilized to encode data back and forth between
/// the Dart and the native platform.
///
/// Extends the default Flutter [StandartMessageCodec], adding
/// a support for these classes:
///
///  * `Uri` - when sending from native, converts it to [String]. Sending from Dart is not allowed and will throw.
///  * `Bundle` - when sending from native, converts it to [BundleMap]. Sending from Dart is not allowed and will throw.
///  * [ContentValues] - also treats all numeric types like Byte, Short, etc. literally, converting
///    them into native counterparts.
class AndroidContentProviderMessageCodec extends StandardMessageCodec {
  /// Creates the codec.
  const AndroidContentProviderMessageCodec();

  // Uri is only sent from native and converted to String.
  static const int _kUri = 134;
  // Bundle is only sent from native.
  // From dart it's easier to just send the Map<String, Object?>
  static const int _kBundle = 133;
  static const int _kContentValues = 132;

  // Java types that need to be supported in the ContentValues:
  static const int _kByte = 128;
  static const int _kShort = 129;
  // value copied from the [StandardMessageCodec._valueInt32]
  static const int _kInteger = 3;
  // value copied from the [StandardMessageCodec._valueInt64]
  static const int _kLong = 4;
  static const int _kFloat = 131;
  // value copied from the [StandardMessageCodec._valueFloat64]
  static const int _kDouble = 6;

  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    // - skip _kUri
    // - skip _kBundle
    if (value is ContentValues) {
      buffer.putUint8(_kContentValues);
      writeSize(buffer, value.length);
      value._map.forEach((Object? key, Object? value) {
        writeValue(buffer, key);
        if (value is _Byte) {
          buffer.putUint8(_kByte);
          buffer.putInt32(value.value);
        } else if (value is _Short) {
          buffer.putUint8(_kShort);
          buffer.putInt32(value.value);
        } else if (value is int) {
          buffer.putUint8(_kInteger);
          buffer.putInt32(value);
        } else if (value is _Long) {
          buffer.putUint8(_kLong);
          buffer.putInt64(value.value);
        } else if (value is _Float) {
          buffer.putUint8(_kFloat);
          buffer.putFloat64(value.value);
        } else if (value is double) {
          buffer.putUint8(_kDouble);
          buffer.putFloat64(value);
        } else {
          writeValue(buffer, value);
        }
      });
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case _kUri:
        final int length = readSize(buffer);
        return utf8.decoder.convert(buffer.getUint8List(length));
      case _kBundle:
        final int length = readSize(buffer);
        final Map<String, Object?> result = <String, Object?>{};
        for (int i = 0; i < length; i++) {
          result[readValue(buffer) as String] = readValue(buffer);
        }
        return result;
      case _kContentValues:
        final int length = readSize(buffer);
        final Map<String, Object?> result = <String, Object?>{};
        for (int i = 0; i < length; i++) {
          result[readValue(buffer) as String] = readValue(buffer);
        }
        return ContentValues._(result);
      case _kByte:
      case _kShort:
      case _kInteger:
        return buffer.getInt32();
      case _kLong:
        return buffer.getInt64();
      case _kFloat:
      case _kDouble:
        return buffer.getFloat64();
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

/// The cursor that calls in to platform Cursor
/// https://developer.android.com/reference/android/database/Cursor
///
/// The operations are packed into [NativeCursorGetBatch] to achieve the best performance
/// by reducing Flutter channel bottle-necking. Cursor operations can often be
/// represented as batches, such as reading all values from each row.
///
/// Returned from [AndroidContentResolver.query].
///
/// See also:
///  * [MatrixCursorData], which is a class, returned from [AndroidContentProvider.query].
class NativeCursor extends Interoperable {
  /// Creates native cursor.
  NativeCursor() : this.fromId(_uuid.v4());

  /// Creates native cursor from an existing ID.
  @internal
  NativeCursor.fromId(String id)
      : _methodChannel = MethodChannel(
          '$_channelPrefix/Cursor/$id',
          AndroidContentProviderPlugin._pluginMethodCodec,
        ),
        super.fromId(id);

  /// Supported types in Android SQLite.
  ///
  /// On of these types will be returned from [NativeCursorGetBatch.getType].
  ///
  /// Represents these static Cursor fields:
  ///  * FIELD_TYPE_NULL
  ///  * FIELD_TYPE_INTEGER
  ///  * FIELD_TYPE_FLOAT
  ///  * FIELD_TYPE_STRING
  ///  * FIELD_TYPE_BLOB
  static List<Type> supportedFieldTypes = [
    Null,
    int,
    double,
    String,
    Uint8List,
  ];

  final MethodChannel _methodChannel;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'NativeCursor')}($id)';
  }

  bool get closed => _closed;
  bool _closed = false;

  Future<void> close() {
    _closed = true;
    return _methodChannel.invokeMethod<void>('close');
  }

  Future<bool> move(int offset) async {
    final result = await _methodChannel.invokeMethod<bool>('move', {
      'offset': offset,
    });
    return result!;
  }

  Future<bool> moveToPosition(int position) async {
    final result = await _methodChannel.invokeMethod<bool>('moveToPosition', {
      'position': position,
    });
    return result!;
  }

  Future<bool> moveToFirst() async {
    final result = await _methodChannel.invokeMethod<bool>('moveToFirst');
    return result!;
  }

  Future<bool> moveToLast() async {
    final result = await _methodChannel.invokeMethod<bool>('moveToLast');
    return result!;
  }

  Future<bool> moveToNext() async {
    final result = await _methodChannel.invokeMethod<bool>('moveToNext');
    return result!;
  }

  Future<bool> moveToPrevious() async {
    final result = await _methodChannel.invokeMethod<bool>('moveToPrevious');
    return result!;
  }

  Future<void> registerContentObserver(ContentObserver observer) {
    return _methodChannel.invokeMethod<bool>('registerContentObserver', {
      'observer': observer.id,
    });
  }

  Future<void> unregisterContentObserver(ContentObserver observer) {
    return _methodChannel.invokeMethod<bool>('unregisterContentObserver', {
      'observer': observer.id,
    });
  }

  Future<void> registerDataSetObserver(DataSetObserver observer) {
    return _methodChannel.invokeMethod<bool>('registerDataSetObserver', {
      'observer': observer.id,
    });
  }

  Future<void> unregisterDataSetObserver(DataSetObserver observer) {
    return _methodChannel.invokeMethod<bool>('unregisterDataSetObserver', {
      'observer': observer.id,
    });
  }

  Future<void> setNotificationUri(String uri) {
    return _methodChannel.invokeMethod<bool>('setNotificationUri', {
      'uri': uri,
    });
  }

  Future<void> setNotificationUris(List<String> uris) {
    return _methodChannel.invokeMethod<bool>('setNotificationUris', {
      'uris': uris,
    });
  }

  Future<String?> getNotificationUri() {
    return _methodChannel.invokeMethod<String>('getNotificationUri');
  }

  Future<List<String>?> getNotificationUris() {
    return _methodChannel.invokeListMethod<String>('getNotificationUris');
  }

  Future<void> setExtras(BundleMap extras) {
    return _methodChannel.invokeMethod<bool>('setExtras', {
      'extras': extras,
    });
  }

  Future<BundleMap> getExtras() async {
    final result =
        await _methodChannel.invokeMapMethod<String, Object?>('getExtras');
    return result!;
  }

  Future<BundleMap> respond(BundleMap extras) async {
    final result = await _methodChannel
        .invokeMapMethod<String, Object?>('respond', {'extras': extras});
    return result!;
  }

  // Not exposed methods:
  //  * copyStringToBuffer - it's not possible to send a buffer through a native channel,
  //    and doing so will be more expensive than just getting a string
  //  * deactivate - deprecated
  //  * requery - deprecated
  //  * getWantsAllOnMoveCalls - intended to be overriden, which doesn't fit this class.
  //    Also, it doesn't seem to be useful in dart

  /// Creates a batch operation of getting data from cursor.
  NativeCursorGetBatch batchedGet() {
    return NativeCursorGetBatch._(this);
  }
}

/// Represents a batched get operation from native cursor.
///
/// This class uses a builder pattern so methods can be called one after another.
///
/// To commit the batch and get the data, call [commit].
///
/// Cursor get operations are can often be represented as batches, such as
/// reading all values from each row. This representation allows
/// to reduce Flutter channel bottle-necking.
///
/// Used in [NativeCursor].
class NativeCursorGetBatch {
  NativeCursorGetBatch._(this._cursor);
  final NativeCursor _cursor;

  final List<List<Object?>> _operations = [];
  List<List<Object?>> get operations => List.unmodifiable(_operations);

  void _add(String method, [Object? argument]) {
    _operations.add([method, argument]);
  }

  /// Commits a batch
  Future<List<Object?>> commit() async {
    final result = await _cursor._methodChannel
        .invokeListMethod<Object>('commitGetBatch', {
      'operations': _operations,
    });
    return result!;
  }

  /// Will return [int].
  NativeCursorGetBatch getCount() {
    _add('getCount');
    return this;
  }

  /// Will return [int].
  NativeCursorGetBatch getPosition() {
    _add('getPosition');
    return this;
  }

  /// Will return [bool].
  NativeCursorGetBatch isFirst() {
    _add('isFirst');
    return this;
  }

  /// Will return [bool].
  NativeCursorGetBatch isLast() {
    _add('isLast');
    return this;
  }

  /// Will return [bool].
  NativeCursorGetBatch isBeforeFirst() {
    _add('isBeforeFirst');
    return this;
  }

  /// Will return [bool].
  NativeCursorGetBatch isAfterLast() {
    _add('isAfterLast');
    return this;
  }

  /// Will return [int].
  NativeCursorGetBatch getColumnIndex(String columnName) {
    _add('getColumnIndex', columnName);
    return this;
  }

  /// Will return [int].
  NativeCursorGetBatch getColumnIndexOrThrow(String columnName) {
    _add('getColumnIndexOrThrow', columnName);
    return this;
  }

  /// Will return [String].
  NativeCursorGetBatch getColumnName(int columnIndex) {
    _add('getColumnName', columnIndex);
    return this;
  }

  /// Will return `List<String>`.
  NativeCursorGetBatch getColumnNames() {
    _add('getColumnNames');
    return this;
  }

  /// Will return [int].
  NativeCursorGetBatch getColumnCount() {
    _add('getColumnCount');
    return this;
  }

  /// Will return [Uint8List].
  NativeCursorGetBatch getBytes(int columnIndex) {
    _add('getBytes', columnIndex);
    return this;
  }

  /// Will return [String].
  NativeCursorGetBatch getString(int columnIndex) {
    _add('getString', columnIndex);
    return this;
  }

  /// Will return [int].
  NativeCursorGetBatch getShort(int columnIndex) {
    _add('getShort', columnIndex);
    return this;
  }

  /// Will return [int].
  NativeCursorGetBatch getInt(int columnIndex) {
    _add('getInt', columnIndex);
    return this;
  }

  /// Will return [int].
  NativeCursorGetBatch getLong(int columnIndex) {
    _add('getLong', columnIndex);
    return this;
  }

  /// Will return [double].
  NativeCursorGetBatch getFloat(int columnIndex) {
    _add('getFloat', columnIndex);
    return this;
  }

  /// Will return [double].
  NativeCursorGetBatch getDouble(int columnIndex) {
    _add('getDouble', columnIndex);
    return this;
  }

  /// Will return a [Type] that is one of the types listed in [NativeCursor.supportedFieldTypes].
  NativeCursorGetBatch getType(int columnIndex) {
    _add('getType', columnIndex);
    return this;
  }

  /// Will return [Bool].
  NativeCursorGetBatch isNull(int columnIndex) {
    _add('isNull', columnIndex);
    return this;
  }
}

/// Builds and contains a data of a platform Cursor
/// https://developer.android.com/reference/android/database/Cursor
///
/// This class then will be converted with [toMap] and sent to the platform,
/// which should have an Cursor implementation which can use the data of this class
/// and return this native Cursor from content provider.
///
/// Returned from [AndroidContentProvider.query].
///
/// See also:
///  * [MatrixCursorData], which is a cursor data implementation backed by an array of [Object]s
abstract class CursorData {
  /// Creates cursor data.
  CursorData({required this.notificationUris});

  /// Actual payload data.
  Object? get payload;

  /// A map with extra values.
  final List<String>? notificationUris;

  /// A map with extra values.
  BundleMap? extras;

  /// Converts the cursor to map to send it to platform.
  BundleMap toMap() => BundleMap.unmodifiable(<String, Object?>{
        'payload': payload,
        'notificationUris': notificationUris,
        'extras': extras,
      });
}

/// A data for Android's MatrixCursor, a mutable cursor implementation backed by an array of [Object]s
/// https://developer.android.com/reference/android/database/MatrixCursor
class MatrixCursorData extends CursorData {
  /// Creates the matrix cursor data.
  MatrixCursorData({
    required List<String> columnNames,
    required List<String>? notificationUris,
  })  : _columnNames = List.unmodifiable(columnNames),
        super(notificationUris: notificationUris);

  /// All column names, given on cursor data creation.
  List<String> get columnNames => List.unmodifiable(_columnNames);
  final List<String> _columnNames;
  final List<Object?> _data = [];
  int _rowCount = 0;

  int get _columnCount => columnNames.length;

  @override
  Object? get payload => {
        'columnNames': _columnNames,
        'data': _data,
        'rowCount': _rowCount,
      };

  /// Ensures that this cursor has enough capacity.
  void _ensureCapacity(int size) {
    if (size > _data.length) {
      int newSize = _data.length * 2;
      if (newSize < size) {
        newSize = size;
      }
      _data.addAll(List.generate(newSize - _data.length, (index) => null));
    }
  }

  /// Adds a new row to the end and returns a builder for that row.
  MatrixCursorDataRowBuilder newRow() {
    final int row = _rowCount;
    _rowCount += 1;
    final int endIndex = _rowCount * _columnCount;
    _ensureCapacity(endIndex);
    return MatrixCursorDataRowBuilder._(row, this);
  }

  /// Adds a new row to the end with the given [columnValues].
  ///
  /// The [columnValues] must have the same length as [columnNames] and have the
  /// same order.
  void addRow(List<Object?> columnValues) {
    if (columnValues.length != _columnCount) {
      throw ArgumentError(
        "The `columnValues` parameter must have the same length as `columnNames`. "
        "The lengths were: columnValues = ${columnValues.length}, columnNames = ${_columnNames.length}",
      );
    }

    int start = _rowCount * _columnCount;
    _rowCount += 1;
    _ensureCapacity(start + _columnCount);
    _data.setRange(start, _columnCount, columnValues);
  }
}

/// A row builder for [MatrixCursorData].
///
/// Undefined values are left as null.
///
/// A counterpart of MatrixCursor.RowBuilder
/// https://developer.android.com/reference/android/database/MatrixCursor.RowBuilder
class MatrixCursorDataRowBuilder {
  MatrixCursorDataRowBuilder._(int row, this._cursorData)
      : _index = row * _cursorData._columnCount {
    _endIndex = _index + _cursorData._columnCount;
  }

  final MatrixCursorData _cursorData;
  late final int _endIndex;

  int _index;

  /// Sets the next column value in this row.
  ///
  /// Returns this builder to support chaining.
  ///
  /// Throws [CursorRangeError] if you try to add too many values
  MatrixCursorDataRowBuilder add(Object columnValue) {
    if (_index == _endIndex) {
      throw CursorRangeError("No more columns left.");
    }

    _cursorData._data[_index] = columnValue;
    _index += 1;
    return this;
  }
}

/// An error indicating that a cursor is out of bounds.
///
/// A counterpart of CursorIndexOutOfBoundsException
/// https://developer.android.com/reference/android/database/CursorIndexOutOfBoundsException
class CursorRangeError extends RangeError {
  /// Crerates cursor range error.
  CursorRangeError(String message) : super(message);
}

/// An object that can be associated with some native counterpart instance.
abstract class Interoperable {
  /// Creates an object with UUID v4 [id].
  ///
  /// Used to create an object and send it to the platform to create a native instance.
  Interoperable() : id = _uuid.v4();

  /// Creates an object from an existing ID.
  ///
  /// The of opposite [Interoperable.new].
  /// Used when the platform creats an object and needs a dart counterpart.
  ///
  /// Marked as internal because it's generally not what an API user should use.
  /// However, it could be useful for custom implementations of [NativeCursor]
  /// or [AndroidContentProvider] (i.e. those using `implements`).
  @internal
  const Interoperable.fromId(this.id);

  /// An ID of an object.
  ///
  /// Typically an UUID v4 string.
  final String id;

  @override
  bool operator ==(Object other) {
    return other is Interoperable && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Provides the ability to cancel an operation in progress
/// https://developer.android.com/reference/android/os/CancellationSignal
class CancellationSignal extends Interoperable {
  /// Creates cancellation signal.
  CancellationSignal() : this.fromId(_uuid.v4());

  /// Creates cancellation signal from an existing ID.
  @internal
  CancellationSignal.fromId(String id)
      : _methodChannel =
            MethodChannel('$_channelPrefix/CancellationSignal/$id'),
        super.fromId(id) {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }
  final MethodChannel _methodChannel;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'CancellationSignal')}($id)';
  }

  /// Whether the operation is cancalled.
  bool get cancelled => _cancelled;
  bool _cancelled = false;

  VoidCallback? _cancelListener;

  /// Sets the cancellation [listener] to be called when canceled.
  ///
  /// If already cancelled, the listener will be called immediately
  void setCancelListener(VoidCallback? listener) {
    if (listener == _cancelListener) {
      return;
    }
    _cancelListener = listener;
    if (_cancelled) {
      listener?.call();
    }
  }

  /// Cancels the operation and signals the cancellation listener.
  /// If the operation has not yet started, then it will be canceled as soon as it does.
  Future<void> cancel() async {
    if (_cancelled) {
      return;
    }
    try {
      _cancelled = true;
      _cancelListener?.call();
      _methodChannel.setMethodCallHandler(null);
      await _methodChannel.invokeMethod<void>('cancel', {'id': id});
    } catch (ex) {
      // Swallow exceptions in case the channel has not been initialized yet.
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (_cancelled) {
      return;
    }
    switch (call.method) {
      case 'cancel':
        _cancelled = true;
        _cancelListener?.call();
        _methodChannel.setMethodCallHandler(null);
        break;
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Method not implemented: ${call.method}',
        );
    }
  }
}

/// A communication interface with native Android ContentProvider
/// https://developer.android.com/reference/android/content/ContentProvider
///
/// The native class is `AndroidContentProvider`.
///
/// Generally, you should use `extends` and NOT `implements` on this class, because it will remove
/// a binding to the platofrm with a method channel.
///
/// However, `implements` could be used for:
///  * using this class just as interface, or
///  * for creating a custom native implementation by extending from `AndroidContentProvider`
///
/// The majority of the methods are called by the native platform to dart. They can be overridden
/// to implement some behavior.
///
/// But also, vice verca, some methods that are marked with [native] annotation are meant
/// to be called from dart to native. These methods will never be called from native to dart.
abstract class AndroidContentProvider {
  /// Creates a communication interface with native Android ContentProvider.
  AndroidContentProvider(this.authority)
      : _methodChannel = MethodChannel(
            '$_channelPrefix/ContentProvider/$authority',
            AndroidContentProviderPlugin._pluginMethodCodec) {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  /// ContentProvider's authority.
  ///
  /// Received from platform in [AndroidContentProviderPlugin.setup] listener.
  final String authority;

  final MethodChannel _methodChannel;

  Future<dynamic> _handleMethodCall(MethodCall methodCall) async {
    final BundleMap? args =
        (methodCall.arguments as Map?)?.cast<String, Object?>();
    switch (methodCall.method) {
      case 'bulkInsert':
        return bulkInsert(
          args!['uri'] as String,
          args['values'] as List<ContentValues>,
        );
      case 'call':
        return call(
          args!['method'] as String,
          args['arg'] as String?,
          args['extras'] as BundleMap?,
        );
      case 'query':
        return query(
          args!['uri'] as String,
          args['projection'] as List<String>?,
          args['selection'] as String?,
          args['selectionArgs'] as List<String>?,
          args['sortOrder'] as String?,
        );
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Method not implemented: ${methodCall.method}',
        );
    }
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'AndroidContentProvider')}($authority)';
  }

  // applyBatch(authority: String, operations: ArrayList<ContentProviderOperation!>): Array<ContentProviderResult!>
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#applybatch
  //
  // applyBatch(operations: ArrayList<ContentProviderOperation!>): Array<ContentProviderResult!>
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#applybatch_1
  //
  // TODO: Batch operations are not implemented yet
  //
  //

  // attachInfo(context: Context!, info: ProviderInfo!): Unit
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#attachinfo
  //
  // @native, not exposed.
  //
  //

  /// bulkInsert(uri: Uri, values: Array<ContentValues!>): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#bulkinsert
  Future<int> bulkInsert(String uri, List<ContentValues> values);

  /// Call a provider-defined method.
  /// This can be used to implement interfaces that are cheaper and/or unnatural for a table-like model.
  ///
  /// WARNING: The framework does no permission checking on this entry into the content provider
  /// besides the basic ability for the application to get access to the provider at all.
  /// For example, it has no idea whether the call being executed may read or write data in
  /// the provider, so can't enforce those individual permissions.
  /// Any implementation of this method must do its own permission checks on incoming calls
  /// to make sure they are allowed.
  ///
  /// --- References ---
  ///
  /// call(method: String, arg: String?, extras: Bundle?): Bundle?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#call_1
  Future<BundleMap?> call(String method, String? arg, BundleMap? extras);

  /// call(authority: String, method: String, arg: String?, extras: Bundle?): Bundle?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#call
  Future<BundleMap?> callWithAuthority(
      String authority, String method, String? arg, BundleMap? extras);

  /// canonicalize(url: Uri): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#call(kotlin.String,%20kotlin.String,%20kotlin.String,%20android.os.Bundle)
  Future<String?> canonicalize(String url);

  /// Reset the identity of the incoming IPC on the current thread.
  ///
  /// This can be useful if, while handling an incoming call, you will be calling on interfaces
  /// of other objects that may be local to your process and need to do permission checks
  /// on the calls coming into them (so they will check the permission of your own local process,
  /// and not whatever process originally called you).
  ///
  /// Returns an opaque token that can be used to restore the original calling identity by passing
  /// it to [restoreCallingIdentity].
  ///
  /// --- References ---
  ///
  /// clearCallingIdentity(): ContentProvider.CallingIdentity
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#clearcallingidentity
  @native
  Future<CallingIdentity> clearCallingIdentity() async {
    final result =
        await _methodChannel.invokeMethod<String>('clearCallingIdentity');
    return CallingIdentity.fromId(result!);
  }

  /// delete(uri: Uri, selection: String?, selectionArgs: Array<String!>?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#delete
  Future<int> delete(String uri, String? selection, List<String>? selectionArgs);

  /// delete(uri: Uri, extras: Bundle?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#delete_1
  Future<int> deleteWithExtras(String uri, BundleMap? extras);

  /// dump(fd: FileDescriptor!, writer: PrintWriter!, args: Array<String!>!): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#dump
  Future<String> dump(List<String> args);

  // getCallingAttributionSource(): AttributionSource?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#getcallingattributionsource
  //
  // @native, not exposed.
  //
  //

  /// getCallingAttributionTag(): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getcallingattributiontag
  @native
  Future<String> getCallingAttributionTag() async {
    final result =
        await _methodChannel.invokeMethod<String>('getCallingAttributionTag');
    return result!;
  }

  /// getCallingPackage(): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getcallingpackage
  @native
  Future<String> getCallingPackage() async {
    final result =
        await _methodChannel.invokeMethod<String>('getCallingPackage');
    return result!;
  }

  /// getCallingPackageUnchecked(): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getcallingpackageunchecked
  @native
  Future<String> getCallingPackageUnchecked() async {
    final result =
        await _methodChannel.invokeMethod<String>('getCallingPackageUnchecked');
    return result!;
  }

  // getContext(): Context?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#getcontext
  //
  // @native, not exposed.
  //
  //

  /// getPathPermissions(): Array<PathPermission!>?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getpathpermissions
  Future<List<PathPermission>> getPathPermissions();

  /// getReadPermission(): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getreadpermission
  Future<String> getReadPermission();

  /// getStreamTypes(uri: Uri, mimeTypeFilter: String): Array<String!>?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getstreamtypes
  Future<List<String>?> getStreamTypes(String uri, String mimeTypeFilter);

  /// getType(uri: Uri): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#gettype
  Future<String?> getType(String uri);

  /// getWritePermission(): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getwritepermission
  Future<String> getWritePermission();

  /// insert(uri: Uri, values: ContentValues?): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#insert
  Future<String?> insert(String uri, ContentValues? values);

  /// insert(uri: Uri, values: ContentValues?, extras: Bundle?): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#insert_1
  Future<String?> insertWithExtras(
      String uri, ContentValues? values, BundleMap? extras);

  /// onCallingPackageChanged(): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#oncallingpackagechanged
  Future<void> onCallingPackageChanged() async {}

  // onConfigurationChanged(newConfig: Configuration): Unit
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#onconfigurationchanged
  //
  // Use [WidgetsBindingObserver] instead, which listens to application configuration changes.
  //
  //

  // onCreate(): Boolean
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#oncreate
  //
  // Use [AndroidContentProviderPlugin.setup] create listener.
  // Usually AndroidContentProvider should be created in this listener, so constructor can be used instead.
  //
  //

  /// onLowMemory(): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#onlowmemory
  Future<void> onLowMemory();

  /// onTrimMemory(level: Int): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#onlowmemory
  Future<void> onTrimMemory(int level);

  // openAssetFile(uri: Uri, mode: String): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#openassetfile
  //
  // @native, not exposed.
  //
  //

  // openAssetFile(uri: Uri, mode: String, signal: CancellationSignal?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#openassetfile_1
  //
  // @native, not exposed.
  //
  //

  /// openFile(uri: Uri, mode: String): ParcelFileDescriptor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#openfile
  Future<String> openFile(String uri, String mode);

  /// openFile(uri: Uri, mode: String, signal: CancellationSignal?): ParcelFileDescriptor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#openfile_1
  Future<String> openFileWithSignal(
    String uri,
    String mode,
    CancellationSignal cancellationSignal,
  );

  // openPipeHelper(uri: Uri, mimeType: String, opts: Bundle?, args: T?, func: ContentProvider.PipeDataWriter<T>): ParcelFileDescriptor
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#openpipehelper
  //
  // @native, not exposed.
  //
  // TODO: consider exposing writeDataToPipe to support writing as stream from dart
  // For example see https://android.googlesource.com/platform/development/+/4779ab6f9aa4d6b691f051e069ffac31475f850a/samples/NotePad/src/com/example/android/notepad/NotePadProvider.java
  //
  //

  // openTypedAssetFile(uri: Uri, mimeTypeFilter: String, opts: Bundle?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#opentypedassetfile
  //
  // @native, not exposed.
  //
  //

  // openTypedAssetFile(uri: Uri, mimeTypeFilter: String, opts: Bundle?, signal: CancellationSignal?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#opentypedassetfile_1
  //
  // @native, not exposed.
  //
  //

  /// query(uri: Uri, projection: Array<String!>?, selection: String?, selectionArgs: Array<String!>?, sortOrder: String?): Cursor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#query
  Future<CursorData> query(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
  );

  /// query(uri: Uri, projection: Array<String!>?, selection: String?, selectionArgs: Array<String!>?, sortOrder: String?, cancellationSignal: CancellationSignal?): Cursor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#query_1
  Future<CursorData> queryWithSignal(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
    CancellationSignal? cancellationSignal,
  );

  /// query(uri: Uri, projection: Array<String!>?, queryArgs: Bundle?, cancellationSignal: CancellationSignal?): Cursor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#query_2
  Future<CursorData> queryWithBundle(
    String uri,
    List<String>? projection,
    BundleMap? queryArgs,
    CancellationSignal? cancellationSignal,
  );

  /// refresh(uri: Uri!, extras: Bundle?, cancellationSignal: CancellationSignal?): Boolean
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#refresh
  Future<bool> refresh(
    String uri,
    BundleMap? extras,
    CancellationSignal? cancellationSignal,
  );

  // requireContext(): Context
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#requirecontext
  //
  // The `getContext` is not exposed.
  //
  // Also, the plugin is initialized in `onCreate`, i.e. this would be possible to be called only
  // when the context is already available.
  //
  //

  /// restoreCallingIdentity(identity: ContentProvider.CallingIdentity): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#restorecallingidentity
  @native
  Future<void> restoreCallingIdentity(CallingIdentity identity);

  /// shutdown(): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#shutdown
  Future<void> shutdown();

  /// uncanonicalize(url: Uri): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#uncanonicalize
  Future<String?> uncanonicalize(String url);

  /// update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<String!>?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#update
  Future<int> update(
    String uri,
    ContentValues? values,
    String? selection,
    List<String>? selectionArgs,
  );

  /// update(uri: Uri, values: ContentValues?, extras: Bundle?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#update_1
  Future<int> updateWithExtras(
      String uri, ContentValues? values, BundleMap? extras);
}

/// Detailed description of a specific MIME type, including an icon and label that describe the type
/// https://developer.android.com/reference/android/content/ContentResolver.MimeTypeInfo
class MimeTypeInfo {
  /// Creates a detailed description of a specific MIME type.
  const MimeTypeInfo({
    required this.label,
    required this.icon,
    required this.contentDescription,
  });

  /// A textual representation of this MIME type.
  final String label;

  /// A visual representation of this MIME type.
  final Uint8List icon;

  /// A content description for this MIME type.
  final String contentDescription;

  /// Creates a MIME type description from map.
  factory MimeTypeInfo.fromMap(BundleMap map) => MimeTypeInfo(
        label: map['label'] as String,
        icon: map['icon'] as Uint8List,
        contentDescription: map['contentDescription'] as String,
      );

  /// Converts the MIME type description to map.
  BundleMap toMap() => BundleMap.unmodifiable(<String, Object?>{
        'label': label,
        'icon': icon,
        'contentDescription': contentDescription,
      });

  static const _iconLogLength = 10;

  @override
  String toString() {
    final buffer = StringBuffer(objectRuntimeType(this, 'MimeTypeInfo'));
    buffer.write('(');
    buffer.write('label: $label, ');
    // A list of values to show.
    final iconValuesToShow =
        icon.sublist(0, math.min(_iconLogLength, icon.length)).join(', ');
    buffer.write('icon: [$iconValuesToShow');
    if (icon.length > _iconLogLength) {
      buffer.write(', ... and ${icon.length - _iconLogLength} more');
    }
    buffer.write('], contentDescription: $contentDescription)');
    return buffer.toString();
  }
}

/// Receives call backs for changes to content
/// https://developer.android.com/reference/android/database/ContentObserver
abstract class ContentObserver extends Interoperable {
  /// Creates content observer.
  ContentObserver() : this._(_uuid.v4());
  ContentObserver._(this._id)
      : _methodChannel = MethodChannel(
          '$_channelPrefix/ContentObserver/$_id',
          AndroidContentProviderPlugin._pluginMethodCodec,
        ) {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  String get id => _id;
  final String _id;

  final MethodChannel _methodChannel;

  Future<dynamic> _handleMethodCall(MethodCall methodCall) async {
    final BundleMap? args =
        (methodCall.arguments as Map?)?.cast<String, Object?>();
    switch (methodCall.method) {
      case 'onChange':
        final uri = args!['uri'] as String?;
        return onChange(
          args['selfChange'] as bool,
          uri,
          args['flags'] as int?,
        );
      case 'onChangeUris':
        final uris = args!['uris'] as List<String>;
        return onChangeUris(
          args['selfChange'] as bool,
          uris,
          args['flags'] as int?,
        );
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Method not implemented: ${methodCall.method}',
        );
    }
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'ContentObserver')}($id)';
  }

  /// Gets called when a content change occurs.
  /// Includes the changed content [uri] when available.
  ///
  /// Subclasses should override this method to handle content changes.
  ///
  /// The [selfChange] will be true if this is a self-change notification.
  ///
  /// The [flags] are indicating details about this change.
  void onChange(bool selfChange, String? uri, int? flags) {}

  /// Gets called when a content change occurs.
  /// Includes the changed content [uris] when available.
  ///
  /// By default calls [onChange] on all the [uris].
  void onChangeUris(bool selfChange, List<String> uris, int? flags) {
    for (final uri in uris) {
      onChange(selfChange, uri, flags);
    }
  }

  // Dispatch methods are not exposed. They can only be useful to dispatch
  // messages on a different supplied handler. Dart doesn't have a way to allow
  // this, thus dispatching can only be overriden natively.
  //
  // If you were just looking for a way to dispatch a notification - just call [onChange] or
  // [onChangeUris] directly. This is what native [dispatch] does anyways, when there's no
  // handler supplied.
}

/// Receives call backs when a data set has been changed, or made invalid.
/// https://developer.android.com/reference/android/database/DataSetObserver
abstract class DataSetObserver extends Interoperable {
  /// Creates content observer.
  DataSetObserver() : this._(_uuid.v4());
  DataSetObserver._(this._id)
      : _eventChannel = EventChannel('$_channelPrefix/DataSetObserver/$_id') {
    _eventChannel.receiveBroadcastStream().listen(_handleEvent);
  }

  @override
  String get id => _id;
  final String _id;

  final EventChannel _eventChannel;

  void _handleEvent(Object? event) async {
    switch (event) {
      case 'onChanged':
        return onChanged();
      case 'onInvalidated':
        return onInvalidated();
      default:
        throw PlatformException(
          code: 'unimplemented',
          message: 'Invalid event: $event',
        );
    }
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'DataSetObserver')}($id)';
  }

  /// Gets called when the entire data set has changed,
  /// most likely through a call not exposed in [NativeCursor] deprecated method `requery`.
  void onChanged() {}

  /// Gets called when the entire data becomes invalid, most likely through
  /// a call to [NativeCursor.close], or not exposed in [NativeCursor] deprecated method `deactivate`.
  void onInvalidated() {}
}

/// A communication interface with native Android ContentResolver
/// https://developer.android.com/reference/android/content/ContentResolver
///
/// Doesn't expose a subset of methods related to sync API and URI permissions,
/// it seems like they would fit separate packages.
class AndroidContentResolver {
  /// Creates a communication interface with native Android ContentResolver.
  const AndroidContentResolver();

  /// Default AndroidContentResovler instance.
  ///
  /// There's no much sense in creating multiple instances of resolver, because
  /// all of them will ultimately call the same method channel.
  static const instance = AndroidContentResolver();

  static const MethodChannel _methodChannel = MethodChannel(
      '$_channelPrefix/ContentResolver',
      AndroidContentProviderPlugin._pluginMethodCodec);

  // acquireContentProviderClient(uri: Uri): ContentProviderClient?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#acquirecontentproviderclient
  //
  // acquireContentProviderClient(name: String): ContentProviderClient?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#acquirecontentproviderclient_1
  //
  // acquireUnstableContentProviderClient(uri: Uri): ContentProviderClient?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#acquireunstablecontentproviderclient
  //
  // acquireUnstableContentProviderClient(name: String): ContentProviderClient?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#acquireunstablecontentproviderclient_1
  //
  //
  // TODO: implement clients
  //
  //

  // static addStatusChangeListener(mask: Int, callback: SyncStatusObserver!): Any!
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#addstatuschangelistener
  //
  // TODO: implement
  //
  //

  // applyBatch(authority: String, operations: ArrayList<ContentProviderOperation!>): Array<ContentProviderResult!>
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#applybatch
  //
  // TODO: implement batches
  //
  //

  /// bulkInsert(uri: Uri, values: Array<ContentValues!>): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#bulkinsert
  Future<int> bulkInsert(String uri, List<ContentValues> values) async {
    final result = await _methodChannel.invokeMethod<int>('bulkInsert', {
      'uri': uri,
      'values': values,
    });
    return result!;
  }

  /// call(uri: Uri, method: String, arg: String?, extras: Bundle?): Bundle?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#call
  Future<BundleMap?> call(
      String uri, String method, String? arg, BundleMap? extras) {
    return _methodChannel.invokeMapMethod<String, Object?>('call', {
      'uri': uri,
      'method': method,
      'arg': arg,
      'extras': extras,
    });
  }

  /// call(authority: String, method: String, arg: String?, extras: Bundle?): Bundle?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#call_1
  Future<BundleMap?> callWithAuthority(
      String authority, String method, String? arg, BundleMap? extras) {
    return _methodChannel
        .invokeMapMethod<String, Object?>('callWithAuthority', {
      'authority': authority,
      'method': method,
      'arg': arg,
      'extras': extras,
    });
  }

  /// canonicalize(url: Uri): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#canonicalize
  Future<String?> canonicalize(String url) {
    return _methodChannel.invokeMethod<String>('canonicalize', {
      'url': url,
    });
  }

  /// delete(uri: Uri, arg: String?, selectionArgs: Array<String!>?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#delete
  Future<int> delete(
      String uri, String? selection, List<String>? selectionArgs) async {
    final result = await _methodChannel.invokeMethod<int>('delete', {
      'uri': uri,
      'selection': selection,
      'selectionArgs': selectionArgs,
    });
    return result!;
  }

  /// delete(uri: Uri, extras: Bundle?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#delete_1
  Future<int> deleteWithExtras(String uri, BundleMap? extras) async {
    final result = await _methodChannel.invokeMethod<int>('deleteWithExtras', {
      'uri': uri,
      'extras': extras,
    });
    return result!;
  }

  /// getStreamTypes(uri: Uri, mimeTypeFilter: String): Array<String!>?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#getstreamtypes
  Future<List<String>?> getStreamTypes(String uri, String mimeTypeFilter) {
    return _methodChannel.invokeListMethod<String>('getStreamTypes', {
      'uri': uri,
      'mimeTypeFilter': mimeTypeFilter,
    });
  }

  /// getType(uri: Uri): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#gettype
  Future<String?> getType(String uri) {
    return _methodChannel.invokeMethod<String>('getType', {
      'uri': uri,
    });
  }

  /// getTypeInfo(mimeType: String): ContentResolver.MimeTypeInfo
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#gettypeinfo
  Future<MimeTypeInfo> getTypeInfo(String mimeType) async {
    final result =
        await _methodChannel.invokeMapMethod<String, Object?>('getTypeInfo', {
      'mimeType': mimeType,
    });
    return MimeTypeInfo.fromMap(result!);
  }

  /// insert(uri: Uri, values: ContentValues?): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#insert
  Future<String?> insert(String uri, ContentValues? values) {
    return _methodChannel.invokeMethod<String>('insert', {
      'uri': uri,
      'values': values,
    });
  }

  /// insert(uri: Uri, values: ContentValues?, extras: Bundle?): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#insert_1
  Future<String?> insertWithExtras(
      String uri, ContentValues? values, BundleMap? extras) {
    return _methodChannel.invokeMethod<String>('insertWithExtras', {
      'uri': uri,
      'values': values,
      'extras': extras,
    });
  }

  /// loadThumbnail(uri: Uri, size: Size, signal: CancellationSignal?): Bitmap
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#loadthumbnail
  Future<Uint8List?> loadThumbnail(String uri, int width, int height,
      CancellationSignal? cancellationSignal) async {
    final result =
        await _methodChannel.invokeMethod<Uint8List>('loadThumbnail', {
      'uri': uri,
      'width': width,
      'height': height,
      'cancellationSignal': cancellationSignal?.id,
    });
    return result!;
  }

  /// notifyChange(uri: Uri, observer: ContentObserver?): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#notifychange
  ///
  /// notifyChange(uri: Uri, observer: ContentObserver?, flags: Int): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#notifychange_2
  Future<void> notifyChange(
    String uri,
    ContentObserver? observer, [
    int? flags,
  ]) {
    return _methodChannel.invokeMethod<void>('notifyChange', {
      'uri': uri,
      'observer': observer?.id,
      'flags': flags,
    });
  }

  // notifyChange(uri: Uri, observer: ContentObserver?, syncToNetwork: Boolean): Unit
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#notifychange_1
  //
  // Deprecated
  //
  //

  /// notifyChange(uris: MutableCollection<Uri!>, observer: ContentObserver?, flags: Int): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#notifychange_3
  Future<void> notifyChangeWithList(
    List<String> uris,
    ContentObserver? observer,
    int flags,
  ) {
    return _methodChannel.invokeMethod<void>('notifyChangeWithList', {
      'uris': uris,
      'observer': observer?.id,
      'flags': flags,
    });
  }

  // openAssetFile(uri: Uri, mode: String, signal: CancellationSignal?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#openassetfile
  //
  // openAssetFileDescriptor(uri: Uri, mode: String): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#openassetfiledescriptor
  //
  // openAssetFileDescriptor(uri: Uri, mode: String, cancellationSignal: CancellationSignal?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#openassetfiledescriptor_1
  //
  // openFile(uri: Uri, mode: String, signal: CancellationSignal?): ParcelFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#openfile
  //
  // openFileDescriptor(uri: Uri, mode: String): ParcelFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#openfiledescriptor
  //
  // openFileDescriptor(uri: Uri, mode: String, cancellationSignal: CancellationSignal?): ParcelFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#openfiledescriptor_1
  //
  // openInputStream(uri: Uri): InputStream?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#openinputstream
  //
  // openOutputStream(uri: Uri): OutputStream?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#openoutputstream
  //
  // openOutputStream(uri: Uri, mode: String): OutputStream?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#openoutputstream_1
  //
  // openTypedAssetFile(uri: Uri, mimeTypeFilter: String, opts: Bundle?, signal: CancellationSignal?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#opentypedassetfile
  //
  // openTypedAssetFileDescriptor(uri: Uri, mimeType: String, opts: Bundle?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#opentypedassetfiledescriptor
  //
  // openTypedAssetFileDescriptor(uri: Uri, mimeType: String, opts: Bundle?, cancellationSignal: CancellationSignal?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#opentypedassetfiledescriptor_1
  //
  // TODO: implement
  //
  //

  /// query(uri: Uri, projection: Array<String!>?, selection: String?, selectionArgs: Array<String!>?, sortOrder: String?): Cursor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query
  Future<NativeCursor?> query(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
  ) async {
    final result = await _methodChannel.invokeMethod<String>('query', {
      'uri': uri,
      'projection': projection,
      'selection': selection,
      'selectionArgs': selectionArgs,
      'sortOrder': sortOrder,
    });
    return result == null ? null : NativeCursor.fromId(result);
  }

  /// query(uri: Uri, projection: Array<String!>?, selection: String?, selectionArgs: Array<String!>?, sortOrder: String?, cancellationSignal: CancellationSignal?): Cursor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_1
  Future<NativeCursor?> queryWithSignal(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
    CancellationSignal? cancellationSignal,
  ) async {
    final result = await _methodChannel.invokeMethod<String>('query', {
      'uri': uri,
      'projection': projection,
      'selection': selection,
      'selectionArgs': selectionArgs,
      'sortOrder': sortOrder,
      'cancellationSignal': cancellationSignal?.id,
    });
    return result == null ? null : NativeCursor.fromId(result);
  }

  /// query(uri: Uri, projection: Array<String!>?, queryArgs: Bundle?, cancellationSignal: CancellationSignal?): Cursor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_2
  Future<NativeCursor?> queryWithBundle(
    String uri,
    List<String>? projection,
    BundleMap? queryArgs,
    CancellationSignal? cancellationSignal,
  ) async {
    final result =
        await _methodChannel.invokeMethod<String>('queryWithBundle', {
      'uri': uri,
      'projection': projection,
      'queryArgs': queryArgs,
      'cancellationSignal': cancellationSignal?.id,
    });
    return result == null ? null : NativeCursor.fromId(result);
  }

  /// refresh(uri: Uri, extras: Bundle?, cancellationSignal: CancellationSignal?): Boolean
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#refresh
  Future<bool> refresh(
    String uri,
    BundleMap? extras,
    CancellationSignal? cancellationSignal,
  ) async {
    final result = await _methodChannel.invokeMethod<bool>('refresh', {
      'uri': uri,
      'extras': extras,
      'cancellationSignal': cancellationSignal?.id,
    });
    return result!;
  }

  /// registerContentObserver(uri: Uri, notifyForDescendants: Boolean, observer: ContentObserver): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#registercontentobserver
  Future<void> registerContentObserver(
    String uri,
    bool notifyForDescendants,
    ContentObserver observer,
  ) {
    return _methodChannel.invokeMethod<void>('registerContentObserver', {
      'uri': uri,
      'notifyForDescendants': notifyForDescendants,
      'observer': observer.id,
    });
  }

  // static removeStatusChangeListener(handle: Any!): Unit
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#removestatuschangelistener
  //
  // TODO: implement
  //
  //

  /// uncanonicalize(url: Uri): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#uncanonicalize
  Future<String?> uncanonicalize(String url) {
    return _methodChannel.invokeMethod<String>('uncanonicalize', {
      'url': url,
    });
  }

  /// unregisterContentObserver(observer: ContentObserver): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#unregistercontentobserver
  Future<void> unregisterContentObserver(ContentObserver observer) {
    return _methodChannel.invokeMethod<void>('unregisterContentObserver', {
      'observer': observer.id,
    });
  }

  /// update(uri: Uri, values: ContentValues?, arg: String?, selectionArgs: Array<String!>?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#update
  Future<int> update(
    String uri,
    ContentValues? values,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    final result = await _methodChannel.invokeMethod<int>('update', {
      'uri': uri,
      'values': values,
      'selection': selection,
      'selectionArgs': selectionArgs,
    });
    return result!;
  }

  /// update(uri: Uri, values: ContentValues?, extras: Bundle?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#update_1
  Future<int> updateWithExtras(
    String uri,
    ContentValues? values,
    BundleMap? extras,
  ) async {
    final result = await _methodChannel.invokeMethod<int>('updateWithExtras', {
      'uri': uri,
      'values': values,
      'extras': extras,
    });
    return result!;
  }
}
