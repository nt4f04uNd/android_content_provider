part of '../android_content_provider.dart';

/// This class is used to store a set of values that the content provider/resolver can process
/// https://developer.android.com/reference/android/content/ContentValues
///
/// This class allows storing Java types that are not presented in Dart:
///  * Byte
///  * Short
///  * Integer
///  * Float
///
/// They are still represented by corresponding Dart types `int` and `double`, and when put
/// into [ContentValues], keep being stored as is, without overflowing.
///
/// For example, if `500` is passed into `putByte`, it will remain `500` on `getByte`.
///
/// But, when sent over native channels, these values are converted to actual Java types,
/// and therefore an overflow will happen.
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
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType || other is! ContentValues) {
      return false;
    }
    if (length != other.length) {
      return false;
    }
    for (final String key in keys) {
      if (!other.containsKey(key) ||
          _maybeUnwrapValue(other._map[key]) != _maybeUnwrapValue(_map[key])) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_map.values);

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
