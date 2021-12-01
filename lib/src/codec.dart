part of android_content_provider;

List<T>? _asList<T>(Object? value) {
  return (value as List?)?.cast<T>();
}

Map<K, V>? _asMap<K, V>(Object? value) {
  return (value as Map?)?.cast<K, V>();
}

class _NumberWrapper<T extends num> {
  const _NumberWrapper(this.value);

  /// Wrapped number value.
  final T value;
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
///
/// Decoded values will use `List<Object?>` and `Map<Object?, Object?>`
/// irrespective of content.
class AndroidContentProviderMessageCodec extends StandardMessageCodec {
  /// Creates the codec.
  const AndroidContentProviderMessageCodec();

  // Uri is only sent from native and converted to String.
  static const int _kUri = 134;
  // Bundle is only sent from native.
  // From Dart it's easier to just send the Map<String, Object?>
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
