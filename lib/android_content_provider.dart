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

/// Container for two values.
class Pair<T, K> {
  /// Creates a pair of two values.
  const Pair(this.first, this.second);

  /// First value.
  final T first;

  /// Second value.
  final K second;

  @override
  bool operator ==(Object other) {
    return other is Pair && other.first == first && other.second == second;
  }

  @override
  int get hashCode => hashValues(first, second);

  Pair._fromList(List<Object?> list)
      : first = list[0] as T,
        second = list[1] as K;
  List<Object> _toList() => [first as Object, second as Object];
}

/// Opaque token representing the identity of an incoming IPC.
class CallingIdentity {
  /// Creates a [CallingIdentity].
  const CallingIdentity({
    required this.binderToken,
    required this.callingPackage,
  });

  /// The value return by Binder to restore the identity.
  final int binderToken;

  /// The information about the calling package.
  ///
  /// The first value is the package name, the second is an attribution tag.
  ///
  /// See info about attribution tags https://developer.android.com/guide/topics/data/audit-access.
  final Pair<String, String> callingPackage;

  factory CallingIdentity._fromMap(BundleMap map) => CallingIdentity(
        binderToken: map['binderToken'] as int,
        callingPackage: Pair._fromList(map['callingPackage'] as List),
      );
  BundleMap _toMap() => <String, dynamic>{
        'binderToken': binderToken,
        'callingPackage': callingPackage._toList(),
      };
}

/// Description of permissions needed to access a particular path in a content provider
/// https://developer.android.com/reference/kotlin/android/content/pm/PathPermission
///
/// See also https://developer.android.com/guide/topics/manifest/path-permission-element
/// on how to declare these paths.
class PathPermission {
  /// Creates a [PathPermission].
  PathPermission({
    required this.readPermission,
    required this.writePermission,
  });

  /// Read permission.
  /// For example "com.example.permission.READ".
  final String readPermission;

  /// Write permission.
  /// For example "com.example.permission.WRITE".
  final String writePermission;

  factory PathPermission._fromMap(BundleMap map) => PathPermission(
        readPermission: map['readPermission'] as String,
        writePermission: map['writePermission'] as String,
      );
  BundleMap _toMap() => <String, dynamic>{
        'readPermission': readPermission,
        'writePermission': writePermission,
      };
}

/// This class is used to store a set of values that the content provider/resolver can process
/// https://developer.android.com/reference/android/content/ContentValues
class ContentValues {
  /// Creates [ContentValues].
  ContentValues() : values = <String, dynamic>{};

  /// Copies values from other [ContentValues] instances.
  ContentValues.copyFrom(ContentValues other) : values = other.values;

  /// Content values map.
  final BundleMap values;



  /// Removes all values.
  void clear() {
    Uint8List;
    values.clear();
  }

  /// Returns true if this object has a value by given [key].
  bool containsKey(String key) {
    return values.containsKey(key);
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
    return CallingIdentity._fromMap(result!);
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
