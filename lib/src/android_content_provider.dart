part of android_content_provider;

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
/// But also, vice versa, some methods that are marked with [native] annotation are meant
/// to be called from dart to native. These methods will never be called from native to dart.
abstract class AndroidContentProvider {
  /// Creates a communication interface with native Android ContentProvider.
  AndroidContentProvider(this.authority)
      : _methodChannel = MethodChannel(
          '$_channelPrefix/ContentProvider/$authority',
          _pluginMethodCodec,
        ) {
    assert(() {
      if (_debugSetUp) {
        throw StateError(
            "AndroidContentProvider has already been created in this isolate. "
            "Each AndroidContentProvider must have a unique entrypoint and be created only once in it. "
            "Make sure you followed the installation intructions from README.");
      }
      return _debugSetUp = true;
    }());
    WidgetsFlutterBinding.ensureInitialized();
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  bool _debugSetUp = false;

  /// ContentProvider's authority, matching the one, declared in `AndroidManifest.xml`.
  final String authority;

  final MethodChannel _methodChannel;

  Future<dynamic> _handleMethodCall(MethodCall methodCall) async {
    final BundleMap? args = _asMap<String, Object?>(methodCall.arguments);
    switch (methodCall.method) {
      case 'bulkInsert':
        return bulkInsert(
          args!['uri'] as String,
          _asList(args['values'])!,
        );
      case 'call':
        return call(
          args!['method'] as String,
          args['arg'] as String?,
          args['extras'] as BundleMap?,
        );
      case 'callWithAuthority':
        return callWithAuthority(
          args!['authority'] as String,
          args['method'] as String,
          args['arg'] as String?,
          args['extras'] as BundleMap?,
        );
      case 'canonicalize':
        return canonicalize(args!['url'] as String);
      case 'delete':
        return delete(
          args!['uri'] as String,
          args['selection'] as String?,
          _asList(args['selectionArgs']),
        );
      case 'deleteWithExtras':
        return deleteWithExtras(
          args!['uri'] as String,
          args['extras'] as BundleMap?,
        );
      case 'getStreamTypes':
        return getStreamTypes(
          args!['uri'] as String,
          args['mimeTypeFilter'] as String,
        );
      case 'getType':
        return getType(args!['uri'] as String);
      case 'insert':
        return insert(
          args!['uri'] as String,
          args['values'] as ContentValues?,
        );
      case 'insertWithExtras':
        return insertWithExtras(
          args!['uri'] as String,
          args['values'] as ContentValues?,
          args['extras'] as BundleMap?,
        );
      case 'onCallingPackageChanged':
        return onCallingPackageChanged();
      case 'onLowMemory':
        return onLowMemory();
      case 'onTrimMemory':
        return onTrimMemory(args!['level'] as int);
      case 'openFile':
        return openFile(
          args!['uri'] as String,
          args['mode'] as String,
        );
      case 'openFileWithSignal':
        final signalId = args!['cancellationSignal'] as String?;
        final signal = signalId == null
            ? null
            : ReceivedCancellationSignal.fromId(signalId);
        try {
          return openFileWithSignal(
            args['uri'] as String,
            args['mode'] as String,
            signal,
          );
        } finally {
          signal?.dispose();
        }
      case 'query':
        final result = await query(
          args!['uri'] as String,
          _asList(args['projection']),
          args['selection'] as String?,
          _asList(args['selectionArgs']),
          args['sortOrder'] as String?,
        );
        return result?.toMap();
      case 'queryWithSignal':
        final signalId = args!['cancellationSignal'] as String?;
        final signal = signalId == null
            ? null
            : ReceivedCancellationSignal.fromId(signalId);
        try {
          final result = await queryWithSignal(
            args['uri'] as String,
            _asList(args['projection']),
            args['selection'] as String?,
            _asList(args['selectionArgs']),
            args['sortOrder'] as String?,
            signal,
          );
          return result?.toMap();
        } finally {
          signal?.dispose();
        }
      case 'queryWithExtras':
        final signalId = args!['cancellationSignal'] as String?;
        final signal = signalId == null
            ? null
            : ReceivedCancellationSignal.fromId(signalId);
        try {
          final result = await queryWithExtras(
            args['uri'] as String,
            _asList(args['projection']),
            _asMap(args['queryArgs']),
            signal,
          );
          return result?.toMap();
        } finally {
          signal?.dispose();
        }
      case 'refresh':
        final signalId = args!['cancellationSignal'] as String?;
        final signal = signalId == null
            ? null
            : ReceivedCancellationSignal.fromId(signalId);
        try {
          final result = await refresh(
            args['uri'] as String,
            _asMap(args['extras']),
            signal,
          );
          return result;
        } finally {
          signal?.dispose();
        }
      case 'uncanonicalize':
        return uncanonicalize(args!['url'] as String);
      case 'update':
        return update(
          args!['uri'] as String,
          args['values'] as ContentValues?,
          args['selection'] as String?,
          _asList(args['selectionArgs']),
        );
      case 'updateWithExtras':
        return updateWithExtras(
          args!['uri'] as String,
          args['values'] as ContentValues?,
          _asMap(args['extras']),
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

  /// https://developer.android.com/reference/kotlin/android/content/ComponentCallbacks2#trim_memory_complete
  static const int TRIM_MEMORY_COMPLETE = 80;

  /// https://developer.android.com/reference/kotlin/android/content/ComponentCallbacks2#trim_memory_moderate
  static const int TRIM_MEMORY_MODERATE = 60;

  /// https://developer.android.com/reference/kotlin/android/content/ComponentCallbacks2#trim_memory_background
  static const int TRIM_MEMORY_BACKGROUND = 40;

  /// https://developer.android.com/reference/kotlin/android/content/ComponentCallbacks2#trim_memory_ui_hidden
  static const int TRIM_MEMORY_UI_HIDDEN = 20;

  /// https://developer.android.com/reference/kotlin/android/content/ComponentCallbacks2#trim_memory_running_critical
  static const int TRIM_MEMORY_RUNNING_CRITICAL = 15;

  /// https://developer.android.com/reference/kotlin/android/content/ComponentCallbacks2#trim_memory_running_low
  static const int TRIM_MEMORY_RUNNING_LOW = 10;

  /// https://developer.android.com/reference/kotlin/android/content/ComponentCallbacks2#trim_memory_running_moderate
  static const int TRIM_MEMORY_RUNNING_MODERATE = 5;

  // applyBatch(authority: String, operations: ArrayList<ContentProviderOperation!>): Array<ContentProviderResult!>
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#applybatch
  //
  // applyBatch(operations: ArrayList<ContentProviderOperation!>): Array<ContentProviderResult!>
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#applybatch_1
  //
  // TODO: Batch operations are not implemented yet
  //
  //

  /// bulkInsert(uri: Uri, values: Array<ContentValues!>): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#bulkinsert
  Future<int> bulkInsert(String uri, List<ContentValues> values) async {
    for (final value in values) {
      await insert(uri, value);
    }
    return values.length;
  }

  /// call(method: String, arg: String?, extras: Bundle?): Bundle?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#call_1
  Future<BundleMap?> call(String method, String? arg, BundleMap? extras) async {
    return null;
  }

  /// call(authority: String, method: String, arg: String?, extras: Bundle?): Bundle?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#call
  Future<BundleMap?> callWithAuthority(
    String authority,
    String method,
    String? arg,
    BundleMap? extras,
  ) async {
    return call(method, arg, extras);
  }

  /// canonicalize(url: Uri): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#call(kotlin.String,%20kotlin.String,%20kotlin.String,%20android.os.Bundle)
  Future<String?> canonicalize(String url) async {
    return null;
  }

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
  /// Supported starting from Android Q, returns `null` on lower versions.
  ///
  /// --- References ---
  ///
  /// clearCallingIdentity(): ContentProvider.CallingIdentity
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#clearcallingidentity
  @native
  @RequiresApiOrNoop(29)
  Future<CallingIdentity?> clearCallingIdentity() async {
    final result =
        await _methodChannel.invokeMethod<String>('clearCallingIdentity');
    return result == null ? null : CallingIdentity.fromId(result);
  }

  /// delete(uri: Uri, selection: String?, selectionArgs: Array<String!>?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#delete
  Future<int> delete(
    String uri,
    String? selection,
    List<String>? selectionArgs,
  );

  /// delete(uri: Uri, extras: Bundle?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#delete_1
  Future<int> deleteWithExtras(String uri, BundleMap? extras) async {
    if (extras == null) {
      return delete(uri, null, null);
    }
    return delete(
      uri,
      extras[AndroidContentResolver.QUERY_ARG_SQL_SELECTION] as String?,
      _asList(extras[AndroidContentResolver.QUERY_ARG_SQL_SELECTION_ARGS]),
    );
  }

  // dump(fd: FileDescriptor!, writer: PrintWriter!, args: Array<String!>!): Unit
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#dump
  //
  // Cannot be supported, since called from the UI thread and must return synchronously,
  // which is not possible, since method calls happen on UI thread.
  //
  //

  // getCallingAttributionSource(): AttributionSource?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#getcallingattributionsource
  //
  // Not exposed - it's not easy.
  //
  //

  /// Supported starting from Android Q, returns `null` on lower versions.
  ///
  /// getCallingAttributionTag(): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getcallingattributiontag
  @native
  @RequiresApiOrNoop(30)
  Future<String?> getCallingAttributionTag() async {
    return _methodChannel.invokeMethod<String>('getCallingAttributionTag');
  }

  /// getCallingPackage(): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getcallingpackage
  @native
  @RequiresApiOrNoop(19)
  Future<String?> getCallingPackage() async {
    return _methodChannel.invokeMethod<String>('getCallingPackage');
  }

  /// getCallingPackageUnchecked(): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getcallingpackageunchecked
  @native
  @RequiresApiOrNoop(30)
  Future<String?> getCallingPackageUnchecked() async {
    return _methodChannel.invokeMethod<String>('getCallingPackageUnchecked');
  }

  // getPathPermissions(): Array<PathPermission!>?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#getpathpermissions
  //
  // setPathPermissions(permissions: Array<PathPermission!>?): Unit
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#setpathpermissions
  //
  // getReadPermission(): String?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#getreadpermission
  //
  // getWritePermission(): String?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#getwritepermission
  //
  // setReadPermission(permission: String?): Unit
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#setreadpermission
  //
  // setWritePermission(permission: String?): Unit
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#setwritepermission
  //
  // Not exposed.
  // It's not clear what is the use case for them.
  //
  //

  /// getStreamTypes(uri: Uri, mimeTypeFilter: String): Array<String!>?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#getstreamtypes
  Future<List<String>?> getStreamTypes(
    String uri,
    String mimeTypeFilter,
  ) async {
    return null;
  }

  /// getType(uri: Uri): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#gettype
  Future<String?> getType(String uri);

  /// insert(uri: Uri, values: ContentValues?): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#insert
  Future<String?> insert(String uri, ContentValues? values);

  /// insert(uri: Uri, values: ContentValues?, extras: Bundle?): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#insert_1
  Future<String?> insertWithExtras(
    String uri,
    ContentValues? values,
    BundleMap? extras,
  ) {
    return insert(uri, values);
  }

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
  // Use the constructor instead.
  //
  // The native onCreate is likely (but not necessarily) will be called only once during the
  // whole app process. This means your ContentProvider may end up not properly initialized
  // after the Flutter app is hot restarted, because the ContentProvider instance is entirely
  // recreated, but onCreate is not called again.
  //
  //

  /// onLowMemory(): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#onlowmemory
  void onLowMemory() {}

  /// onTrimMemory(level: Int): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#onlowmemory
  void onTrimMemory(int level) {}

  // openAssetFile(uri: Uri, mode: String): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#openassetfile
  //
  // openAssetFile(uri: Uri, mode: String, signal: CancellationSignal?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#openassetfile_1
  //
  // TODO: consider implementing
  //
  //

  /// openFile(uri: Uri, mode: String): ParcelFileDescriptor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#openfile
  Future<String?> openFile(String uri, String mode) async {
    return null;
  }

  /// openFile(uri: Uri, mode: String, signal: CancellationSignal?): ParcelFileDescriptor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#openfile_1
  Future<String?> openFileWithSignal(
    String uri,
    String mode,
    ReceivedCancellationSignal? cancellationSignal,
  ) async {
    return openFile(uri, mode);
  }

  // openPipeHelper(uri: Uri, mimeType: String, opts: Bundle?, args: T?, func: ContentProvider.PipeDataWriter<T>): ParcelFileDescriptor
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#openpipehelper
  //
  // openTypedAssetFile(uri: Uri, mimeTypeFilter: String, opts: Bundle?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#opentypedassetfile
  //
  // openTypedAssetFile(uri: Uri, mimeTypeFilter: String, opts: Bundle?, signal: CancellationSignal?): AssetFileDescriptor?
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#opentypedassetfile_1
  //
  // TODO: consider implementing writeDataToPipe to support writing as stream from dart
  // For example see https://android.googlesource.com/platform/development/+/4779ab6f9aa4d6b691f051e069ffac31475f850a/samples/NotePad/src/com/example/android/notepad/NotePadProvider.java
  //

  /// query(uri: Uri, projection: Array<String!>?, selection: String?, selectionArgs: Array<String!>?, sortOrder: String?): Cursor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#query
  Future<CursorData?> query(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
  );

  /// query(uri: Uri, projection: Array<String!>?, selection: String?, selectionArgs: Array<String!>?, sortOrder: String?, cancellationSignal: CancellationSignal?): Cursor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#query_1
  Future<CursorData?> queryWithSignal(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
    ReceivedCancellationSignal? cancellationSignal,
  ) async {
    return query(uri, projection, selection, selectionArgs, sortOrder);
  }

  /// query(uri: Uri, projection: Array<String!>?, queryArgs: Bundle?, cancellationSignal: CancellationSignal?): Cursor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#query_2
  Future<CursorData?> queryWithExtras(
    String uri,
    List<String>? projection,
    BundleMap? queryArgs,
    ReceivedCancellationSignal? cancellationSignal,
  ) async {
    if (queryArgs == null) {
      return queryWithSignal(
        uri,
        projection,
        null,
        null,
        null,
        cancellationSignal,
      );
    }

    // if client doesn't supply an SQL sort order argument, attempt to build one from
    // QUERY_ARG_SORT* arguments.
    var sortClause =
        queryArgs[AndroidContentResolver.QUERY_ARG_SQL_SORT_ORDER] as String?;
    if (sortClause == null &&
        queryArgs.containsKey(AndroidContentResolver.QUERY_ARG_SORT_COLUMNS)) {
      sortClause = AndroidContentResolver.createSqlSortClause(queryArgs);
    }

    return queryWithSignal(
      uri,
      projection,
      queryArgs[AndroidContentResolver.QUERY_ARG_SQL_SELECTION] as String?,
      _asList(queryArgs[AndroidContentResolver.QUERY_ARG_SQL_SELECTION_ARGS]),
      sortClause,
      cancellationSignal,
    );
  }

  /// refresh(uri: Uri!, extras: Bundle?, cancellationSignal: CancellationSignal?): Boolean
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#refresh
  Future<bool> refresh(
    String uri,
    BundleMap? extras,
    ReceivedCancellationSignal? cancellationSignal,
  ) async {
    return false;
  }

  /// restoreCallingIdentity(identity: ContentProvider.CallingIdentity): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#restorecallingidentity
  @native
  @RequiresApiOrNoop(29)
  Future<void> restoreCallingIdentity(CallingIdentity identity) {
    return _methodChannel.invokeMethod<String>('restoreCallingIdentity', {
      'identity': identity.id,
    });
  }

  // shutdown(): Unit
  // https://developer.android.com/reference/kotlin/android/content/ContentProvider#shutdown
  //
  // Android docs say "Implement this to shut down the ContentProvider instance. You can then
  // invoke this method in unit tests.".
  // Seems pointless to be a part of the interface therefore.
  //
  //

  /// uncanonicalize(url: Uri): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentProvider#uncanonicalize
  Future<String?> uncanonicalize(String url) async {
    return url;
  }

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
    String uri,
    ContentValues? values,
    BundleMap? extras,
  ) async {
    if (extras == null) {
      return update(uri, values, null, null);
    }
    return update(
      uri,
      values,
      extras[AndroidContentResolver.QUERY_ARG_SQL_SELECTION] as String?,
      _asList(extras[AndroidContentResolver.QUERY_ARG_SQL_SELECTION_ARGS]),
    );
  }
}
