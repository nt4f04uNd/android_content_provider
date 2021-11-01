import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

/// The android_content_provider plugin binding.
///
/// Allows to create content providers and content resolvers.
abstract class AndroidContentProviderPlugin {
  static late final MethodChannel _channel = () {
    WidgetsFlutterBinding.ensureInitialized();
    return const MethodChannel('com.nt4f04und.android_content_provider.methods')
      ..setMethodCallHandler(_handleMethodCall);
  }();

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'createContentProvider':
        _onCreate.add(call.method);
        break;
      default:
        throw PlatformException(
            code: 'unimplemented',
            message: 'Method not implemented: ${call.method}');
    }
  }

  static late final ReplaySubject<String> _onCreate = ReplaySubject();

  /// Sets up a listener to the platform notifications about content provider
  /// `onCreate` calls.
  ///
  /// All messages received before this was called will be delivered when
  /// first listener is set.
  static void setup({required CreateListener createListener}) {
    if (_onCreate.hasListener) {
      throw StateError("AndroidContentProviderPlugin already was set up");
    }
    _onCreate.listen(createListener);
  }
}

/// Signature for [AndroidContentProviderPlugin.setup] listener argument.
typedef CreateListener = AndroidContentProvider Function(String authority);

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
typedef BundleMap = Map<String, dynamic>;

/// Opaque token representing the identity of an incoming IPC.
class CallingIdentity {
  const CallingIdentity._(this.id);

  /// The ID of this token tied to a native object instance.
  final int id;

  @override
  bool operator ==(Object other) {
    return other is CallingIdentity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'CallingIdentity')}($id)';
  }

  /// Creates an identity from map.
  @visibleForTesting
  factory CallingIdentity.fromMap(BundleMap map) =>
      CallingIdentity._(map['id'] as int);

  /// Converts the identity to map.
  @visibleForTesting
  BundleMap toMap() => <String, dynamic>{'id': id};
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
  @visibleForTesting
  factory PathPermission.fromMap(BundleMap map) => PathPermission(
        readPermission: map['readPermission'] as String?,
        writePermission: map['writePermission'] as String?,
      );

  /// Converts the path permissions to map.
  @visibleForTesting
  BundleMap toMap() => <String, dynamic>{
        'readPermission': readPermission,
        'writePermission': writePermission,
      };
}

/// This class is used to store a set of values that the content provider/resolver can process
/// https://developer.android.com/reference/android/content/ContentValues
class ContentValues {
  /// Creates [ContentValues].
  ContentValues() : _map = <String, Object?>{};
  ContentValues._(Map<String, Object?> map) : _map = map;

  /// Copies values from other [ContentValues] instances.
  ContentValues.copyFrom(ContentValues other) : _map = other._map;

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

/// A wrapper for value in [CotnentValues.putByte].
class _Byte {
  const _Byte(this.value);
  final int value;

  @override
  bool operator ==(Object other) {
    return other is _Byte && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// A wrapper for value in [CotnentValues.putShort].
class _Short {
  const _Short(this.value);
  final int value;

  @override
  bool operator ==(Object other) {
    return other is _Short && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

//
// [CotnentValues.putInt] - integers a stored just as `int`
//

/// A wrapper for value in [CotnentValues.putLong].
class _Long {
  const _Long(this.value);
  final int value;

  @override
  bool operator ==(Object other) {
    return other is _Long && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// A wrapper for value in [CotnentValues.putFloat].
class _Float {
  const _Float(this.value);
  final double value;

  @override
  bool operator ==(Object other) {
    return other is _Float && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

//
// [CotnentValues.putDouble] - doubles a stored just as `double`
//

/// The codec utilized to encode data back and forth between
/// the Dart application and the native platform.
class AndroidContentProviderMessageCodec extends StandardMessageCodec {
  /// Creates the codec.
  const AndroidContentProviderMessageCodec();

  // Java types that need to be supported
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
  void writeValue(WriteBuffer buffer, dynamic value) {
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
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
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

/// A communication interface with native Android ContentProvider.
///
/// The most of methods the native platform calls to dart and they can be overridden
/// to implement some behavior.
///
/// However, some methods that are marked with [native] annotation are meant
/// to be called from dart to native. These methods the platform will never call
/// in dart.
abstract class AndroidContentProvider {
  /// Creates a communication interface with native Android ContentProvider.
  AndroidContentProvider(this.authority)
      : _methodChannel = MethodChannel(authority) {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  /// ContentProvider authority.
  ///
  /// Received from platform in [AndroidContentProviderPlugin.setup] listener.
  final String authority;

  final MethodChannel _methodChannel;

  Future<dynamic> _handleMethodCall(MethodCall methodCall) async {
    final BundleMap? args =
        (methodCall.arguments as Map?)?.cast<String, dynamic>();
    switch (methodCall.method) {
      case 'call':
        return call(
          args!['method'] as String,
          args['arg'] as String?,
          args['extras'] as BundleMap?,
        );
      default:
        throw PlatformException(
            code: 'unimplemented',
            message: 'Method not implemented: ${methodCall.method}');
    }
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

  // attachInfo(Context context, ProviderInfo info)
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#attachinfo
  //
  // Not exposed.
  //
  //

  // bulkInsert(Uri uri, ContentValues[] values)
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#bulkinsert
  //
  // TODO:
  //
  //

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
  Future<Uri?> canonicalize(Uri url);

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
    final result = await _methodChannel
        .invokeMapMethod<String, dynamic>('clearCallingIdentity');
    return CallingIdentity.fromMap(result!);
  }

  /// delete(uri: Uri, selection: String?, selectionArgs: Array<String!>?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#delete
  Future<int> delete(Uri uri, String? selection, List<String>? selectionArgs);

  /// delete(uri: Uri, extras: Bundle?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#delete_1
  Future<int> deleteWithExtras(Uri uri, BundleMap? extras);

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
  Future<List<String>?> getStreamTypes(Uri uri, String mimeTypeFilter);

  /// getType(uri: Uri): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#gettype
  Future<String?> getType(Uri uri);

  /// getWritePermission(): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getwritepermission
  Future<String> getWritePermission();

  /// insert(uri: Uri, values: ContentValues?): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#insert
  Future<Uri?> insert(Uri uri, ContentValues? values);

  /// insert(uri: Uri, values: ContentValues?, extras: Bundle?): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#insert_1
  Future<Uri?> insertWithExtras(
      Uri uri, ContentValues? values, BundleMap? extras);

  /// onCallingPackageChanged(): Unit
  /// [WidgetsBindingObserver]
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#oncallingpackagechanged
  Future<void> onCallingPackageChanged();

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

  /// openFile(uri: Uri, mode: String): ParcelFileDescriptor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#openfile
  Future<Uri> openFile(Uri uri, String mode);

  // openFile(uri: Uri, mode: String, signal: CancellationSignal?): ParcelFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#openfile_1
  //
  // @native, not exposed.
  //
  //

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

  // query(uri: Uri, projection: Array<String!>?, selection: String?, selectionArgs: Array<String!>?, sortOrder: String?): Cursor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#query

  // query(uri: Uri, projection: Array<String!>?, selection: String?, selectionArgs: Array<String!>?, sortOrder: String?, cancellationSignal: CancellationSignal?): Cursor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#query_1

  // query(uri: Uri, projection: Array<String!>?, queryArgs: Bundle?, cancellationSignal: CancellationSignal?): Cursor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#query_2

  // refresh(uri: Uri!, extras: Bundle?, cancellationSignal: CancellationSignal?): Boolean
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#refresh

  // requireContext(): Context
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#requirecontext

  /// restoreCallingIdentity(identity: ContentProvider.CallingIdentity): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#restorecallingidentity
  @native
  Future<void> restoreCallingIdentity(CallingIdentity identity);

  // shutdown(): Unit
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#shutdown

  // uncanonicalize(url: Uri): Uri?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#uncanonicalize

  // update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<String!>?): Int
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#update

  // update(uri: Uri, values: ContentValues?, extras: Bundle?): Int
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#update_1
}

class AndroidContentResolver {}
