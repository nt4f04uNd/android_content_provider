part of android_content_provider;

/// A communication interface with native Android ContentResolver
/// https://developer.android.com/reference/android/content/ContentResolver
///
/// Doesn't expose a subset of methods related to sync API and URI permissions,
/// it seems like they would fit separate packages.
///
/// Some methods are not compatible with older Android versions.
/// They are marked with 1 of these annotations:
///
/// * [RequiresApiOrNoop]
/// * [RequiresApiOrThrows]
/// * [RequiresApiOr]
///
class AndroidContentResolver {
  /// Creates a communication interface with native Android ContentResolver.
  ///
  /// Kept for ability to extent this class, prefer using the [instance].
  /// There's no much sense in creating multiple instances of resolver, because
  /// all of them will ultimately call the same method channel.
  const AndroidContentResolver();

  /// Constant [AndroidContentResovler] instance.
  static const instance = AndroidContentResolver();

  /// Method channel to invoke native ContentResolver methods.
  @visibleForTesting
  static const MethodChannel methodChannel = MethodChannel(
    '$_channelPrefix/ContentResolver',
    _pluginMethodCodec,
  );

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#scheme_android_resource
  static const String SCHEME_ANDROID_RESOURCE = "android.resource";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#scheme_content
  static const String SCHEME_CONTENT = "content";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#scheme_file
  static const String SCHEME_FILE = "file";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#extra_size
  static const String EXTRA_SIZE = "android.content.extra.SIZE";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#extra_refresh_supported
  static const String EXTRA_REFRESH_SUPPORTED =
      "android.content.extra.REFRESH_SUPPORTED";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_sql_selection
  static const String QUERY_ARG_SQL_SELECTION =
      "android:query-arg-sql-selection";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_sql_selection_args
  static const String QUERY_ARG_SQL_SELECTION_ARGS =
      "android:query-arg-sql-selection-args";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_sql_sort_order
  static const String QUERY_ARG_SQL_SORT_ORDER =
      "android:query-arg-sql-sort-order";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_sql_group_by
  static const String QUERY_ARG_SQL_GROUP_BY = "android:query-arg-sql-group-by";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_sql_having
  static const String QUERY_ARG_SQL_HAVING = "android:query-arg-sql-having";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_sql_limit
  static const String QUERY_ARG_SQL_LIMIT = "android:query-arg-sql-limit";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_sort_columns
  static const String QUERY_ARG_SORT_COLUMNS = "android:query-arg-sort-columns";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_sort_direction
  static const String QUERY_ARG_SORT_DIRECTION =
      "android:query-arg-sort-direction";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_sort_collation
  static const String QUERY_ARG_SORT_COLLATION =
      "android:query-arg-sort-collation";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_sort_locale
  static const String QUERY_ARG_SORT_LOCALE = "android:query-arg-sort-locale";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_group_columns
  static const String QUERY_ARG_GROUP_COLUMNS =
      "android:query-arg-group-columns";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#extra_honored_args
  static const String EXTRA_HONORED_ARGS = "android.content.extra.HONORED_ARGS";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_sort_direction_ascending
  static const int QUERY_SORT_DIRECTION_ASCENDING = 0;

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_sort_direction_descending
  static const int QUERY_SORT_DIRECTION_DESCENDING = 1;

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_offset
  static const String QUERY_ARG_OFFSET = "android:query-arg-offset";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_arg_limit
  static const String QUERY_ARG_LIMIT = "android:query-arg-limit";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#extra_total_count
  static const String EXTRA_TOTAL_COUNT = "android.content.extra.TOTAL_COUNT";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#cursor_item_base_type
  static const String CURSOR_ITEM_BASE_TYPE = "vnd.android.cursor.item";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#cursor_dir_base_type
  static const String CURSOR_DIR_BASE_TYPE = "vnd.android.cursor.dir";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#any_cursor_item_type
  static const String ANY_CURSOR_ITEM_TYPE = "vnd.android.cursor.item/*";

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#notify_sync_to_network
  static const int NOTIFY_SYNC_TO_NETWORK = 1 << 0;

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#notify_skip_notify_for_descendants
  static const int NOTIFY_SKIP_NOTIFY_FOR_DESCENDANTS = 1 << 1;

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#notify_insert
  static const int NOTIFY_INSERT = 1 << 2;

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#notify_update
  static const int NOTIFY_UPDATE = 1 << 3;

  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#notify_delete
  static const int NOTIFY_DELETE = 1 << 4;

  /// Returns structured sort args formatted as an SQL sort clause.
  @visibleForTesting
  static String createSqlSortClause(BundleMap queryArgs) {
    final columns = _asList<String>(queryArgs[QUERY_ARG_SORT_COLUMNS]);
    if (columns == null || columns.isEmpty) {
      throw ArgumentError("Can't create sort clause without columns.");
    }

    String query = columns.join(', ');

    const _collatorPrimary = 0;
    const _collatorSecondary = 1;

    // Interpret PRIMARY and SECONDARY collation strength as no-case collation based
    // on their javadoc descriptions.
    final collation = queryArgs[QUERY_ARG_SORT_COLLATION] as int?;
    if (collation == _collatorPrimary || collation == _collatorSecondary) {
      query += " COLLATE NOCASE";
    }

    final sortDir = queryArgs[QUERY_ARG_SORT_DIRECTION] as int?;
    if (sortDir != null) {
      switch (sortDir) {
        case QUERY_SORT_DIRECTION_ASCENDING:
          query += " ASC";
          break;
        case QUERY_SORT_DIRECTION_DESCENDING:
          query += " DESC";
          break;
        default:
          throw ArgumentError(
            "Unsupported sort direction value. "
            "See ContentResolver documentation for details.",
          );
      }
    }
    return query;
  }

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

  // applyBatch(authority: String, operations: ArrayList<ContentProviderOperation!>): Array<ContentProviderResult!>
  // https://developer.android.com/reference/kotlin/android/content/ContentResolver#applybatch
  //
  // TODO: implement batches
  //
  //

  /// bulkInsert(uri: Uri, values: Array<ContentValues!>): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#bulkinsert
  Future<int> bulkInsert({
    required String uri,
    required List<ContentValues> values,
  }) async {
    final result = await methodChannel.invokeMethod<int>('bulkInsert', {
      'uri': uri,
      'values': values,
    });
    return result!;
  }

  /// call(uri: Uri, method: String, arg: String?, extras: Bundle?): Bundle?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#call
  Future<BundleMap?> call({
    required String uri,
    required String method,
    String? arg,
    BundleMap? extras,
  }) {
    return methodChannel.invokeMapMethod<String, Object?>('call', {
      'uri': uri,
      'method': method,
      'arg': arg,
      'extras': extras,
    });
  }

  /// call(authority: String, method: String, arg: String?, extras: Bundle?): Bundle?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#call_1
  @RequiresApiOrThrows(29)
  Future<BundleMap?> callWithAuthority({
    required String authority,
    required String method,
    String? arg,
    BundleMap? extras,
  }) {
    return methodChannel
        .invokeMapMethod<String, Object?>('callWithAuthority', {
      'authority': authority,
      'method': method,
      'arg': arg,
      'extras': extras,
    });
  }

  /// canonicalize(url: Uri): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#canonicalize
  @RequiresApiOrNoop(19)
  Future<String?> canonicalize({required String url}) {
    return methodChannel.invokeMethod<String>('canonicalize', {
      'url': url,
    });
  }

  /// delete(uri: Uri, arg: String?, selectionArgs: Array<String!>?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#delete
  Future<int> delete({
    required String uri,
    String? selection,
    List<String>? selectionArgs,
  }) async {
    final result = await methodChannel.invokeMethod<int>('delete', {
      'uri': uri,
      'selection': selection,
      'selectionArgs': selectionArgs,
    });
    return result!;
  }

  /// delete(uri: Uri, extras: Bundle?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#delete_1
  @RequiresApiOrThrows(30)
  Future<int> deleteWithExtras({
    required String uri,
    BundleMap? extras,
  }) async {
    final result = await methodChannel.invokeMethod<int>('deleteWithExtras', {
      'uri': uri,
      'extras': extras,
    });
    return result!;
  }

  /// getStreamTypes(uri: Uri, mimeTypeFilter: String): Array<String!>?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#getstreamtypes
  Future<List<String>?> getStreamTypes({
    required String uri,
    required String mimeTypeFilter,
  }) {
    return methodChannel.invokeListMethod<String>('getStreamTypes', {
      'uri': uri,
      'mimeTypeFilter': mimeTypeFilter,
    });
  }

  /// getType(uri: Uri): String?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#gettype
  Future<String?> getType({required String uri}) {
    return methodChannel.invokeMethod<String>('getType', {
      'uri': uri,
    });
  }

  /// getTypeInfo(mimeType: String): ContentResolver.MimeTypeInfo
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#gettypeinfo
  @RequiresApiOrNoop(29)
  Future<MimeTypeInfo?> getTypeInfo({required String mimeType}) async {
    final result =
        await methodChannel.invokeMapMethod<String, Object?>('getTypeInfo', {
      'mimeType': mimeType,
    });
    return result == null ? null : MimeTypeInfo.fromMap(result);
  }

  /// insert(uri: Uri, values: ContentValues?): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#insert
  Future<String?> insert({required String uri, ContentValues? values}) {
    return methodChannel.invokeMethod<String>('insert', {
      'uri': uri,
      'values': values,
    });
  }

  /// insert(uri: Uri, values: ContentValues?, extras: Bundle?): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#insert_1
  @RequiresApiOrThrows(30)
  Future<String?> insertWithExtras({
    required String uri,
    ContentValues? values,
    BundleMap? extras,
  }) {
    return methodChannel.invokeMethod<String>('insertWithExtras', {
      'uri': uri,
      'values': values,
      'extras': extras,
    });
  }

  /// loadThumbnail(uri: Uri, size: Size, signal: CancellationSignal?): Bitmap
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#loadthumbnail
  @RequiresApiOrThrows(29)
  Future<Uint8List> loadThumbnail({
    required String uri,
    required int width,
    required int height,
    CancellationSignal? cancellationSignal,
  }) async {
    try {
      final result =
          await methodChannel.invokeMethod<Uint8List>('loadThumbnail', {
        'uri': uri,
        'width': width,
        'height': height,
        'cancellationSignal': cancellationSignal?.id,
      });
      return result!;
    } finally {
      cancellationSignal?.dispose();
    }
  }

  /// notifyChange(uri: Uri, observer: ContentObserver?): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#notifychange
  ///
  /// notifyChange(uri: Uri, observer: ContentObserver?, flags: Int): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#notifychange_2
  Future<void> notifyChange({
    required String uri,
    ContentObserver? observer,
    @RequiresApiOrNoop(24) int? flags,
  }) {
    return methodChannel.invokeMethod<void>('notifyChange', {
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
  @RequiresApiOrThrows(30)
  Future<void> notifyChangeWithList({
    required List<String> uris,
    ContentObserver? observer,
    required int flags,
  }) {
    return methodChannel.invokeMethod<void>('notifyChangeWithList', {
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
  Future<NativeCursor?> query({
    required String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
  }) async {
    final result = await methodChannel.invokeMethod<String>('query', {
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
  Future<NativeCursor?> queryWithSignal({
    required String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
    CancellationSignal? cancellationSignal,
  }) async {
    try {
      final result =
          await methodChannel.invokeMethod<String>('queryWithSignal', {
        'uri': uri,
        'projection': projection,
        'selection': selection,
        'selectionArgs': selectionArgs,
        'sortOrder': sortOrder,
        'cancellationSignal': cancellationSignal?.id,
      });
      return result == null ? null : NativeCursor.fromId(result);
    } finally {
      cancellationSignal?.dispose();
    }
  }

  /// query(uri: Uri, projection: Array<String!>?, queryArgs: Bundle?, cancellationSignal: CancellationSignal?): Cursor?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#query_2
  @RequiresApiOrThrows(26)
  Future<NativeCursor?> queryWithExtras({
    required String uri,
    List<String>? projection,
    BundleMap? queryArgs,
    CancellationSignal? cancellationSignal,
  }) async {
    try {
      final result =
          await methodChannel.invokeMethod<String>('queryWithExtras', {
        'uri': uri,
        'projection': projection,
        'queryArgs': queryArgs,
        'cancellationSignal': cancellationSignal?.id,
      });
      return result == null ? null : NativeCursor.fromId(result);
    } finally {
      cancellationSignal?.dispose();
    }
  }

  /// refresh(uri: Uri, extras: Bundle?, cancellationSignal: CancellationSignal?): Boolean
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#refresh
  @RequiresApiOrNoop(26)
  Future<bool> refresh({
    required String uri,
    BundleMap? extras,
    CancellationSignal? cancellationSignal,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('refresh', {
        'uri': uri,
        'extras': extras,
        'cancellationSignal': cancellationSignal?.id,
      });
      return result!;
    } finally {
      cancellationSignal?.dispose();
    }
  }

  /// registerContentObserver(uri: Uri, notifyForDescendants: Boolean, observer: ContentObserver): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#registercontentobserver
  Future<void> registerContentObserver({
    required String uri,
    required ContentObserver observer,
    bool notifyForDescendants = false,
  }) {
    return methodChannel.invokeMethod<void>('registerContentObserver', {
      'uri': uri,
      'notifyForDescendants': notifyForDescendants,
      'observer': observer.id,
    });
  }

  /// uncanonicalize(url: Uri): Uri?
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#uncanonicalize
  @RequiresApiOrNoop(19)
  Future<String?> uncanonicalize({required String url}) {
    return methodChannel.invokeMethod<String>('uncanonicalize', {
      'url': url,
    });
  }

  /// unregisterContentObserver(observer: ContentObserver): Unit
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#unregistercontentobserver
  Future<void> unregisterContentObserver(ContentObserver observer) {
    return methodChannel.invokeMethod<void>('unregisterContentObserver', {
      'observer': observer.id,
    });
  }

  /// update(uri: Uri, values: ContentValues?, arg: String?, selectionArgs: Array<String!>?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#update
  Future<int> update({
    required String uri,
    ContentValues? values,
    String? selection,
    List<String>? selectionArgs,
  }) async {
    final result = await methodChannel.invokeMethod<int>('update', {
      'uri': uri,
      'values': values,
      'selection': selection,
      'selectionArgs': selectionArgs,
    });
    return result!;
  }

  /// update(uri: Uri, values: ContentValues?, extras: Bundle?): Int
  /// https://developer.android.com/reference/kotlin/android/content/ContentResolver#update_1
  @RequiresApiOrThrows(30)
  Future<int> updateWithExtras({
    required String uri,
    ContentValues? values,
    BundleMap? extras,
  }) async {
    final result = await methodChannel.invokeMethod<int>('updateWithExtras', {
      'uri': uri,
      'values': values,
      'extras': extras,
    });
    return result!;
  }
}
