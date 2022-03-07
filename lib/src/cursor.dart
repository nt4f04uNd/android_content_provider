part of android_content_provider;

/// The cursor that calls into platform Cursor
/// https://developer.android.com/reference/android/database/Cursor
///
/// After you are done with using the cursor, you should call [close] on it.
/// This means that all operations on cursor should be wrapped in try-finally block:
///
/// ```
/// final NativeCursor? cursor = ...;
/// try {
///   // do something with cursor
/// } finally {
///   cursor?.close();
/// }
/// ```
///
/// In case you forget to do that, the plugin will do this for you when
/// the Flutter app closes, but it better to not forget it.
///
/// The operations are packed into [NativeCursorGetBatch] to achieve the best performance
/// by reducing Flutter channel bottle-necking. Cursor operations can often be
/// represented as batches, such as reading all values from each row.
///
/// Returned from [AndroidContentResolver.query].
///
/// This class has no native counterpart, i.e. only Dart can call in such a manner
/// to platform, but not otherwise. That's because other apps' abstract cursors
/// can't be forced to use the batching. Instead of this [CursorData] is used to transfer data
/// once to platform, which leads to certain limitations in this API, but will work for the most use cases.
///
/// See also:
///  * [CursorData], which is a class, returned from [AndroidContentProvider.query].
class NativeCursor extends Interoperable {
  /// Creates native cursor from an existing ID.
  @visibleForTesting
  NativeCursor.fromId(String id)
      : _methodChannel = MethodChannel(
          '$_channelPrefix/Cursor/$id',
          _pluginMethodCodec,
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
  static const supportedFieldTypes = <Type>[
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

  bool _closed = false;

  /// Closes the cursor, releasing all of its resources and making it completely invalid
  /// https://developer.android.com/reference/android/database/Cursor#close()
  Future<void> close() async {
    if (!_closed) {
      _closed = true;
      return _methodChannel.invokeMethod<void>('close');
    }
  }

  /// https://developer.android.com/reference/android/database/Cursor#move(int)
  Future<bool> move(int offset) async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('move', {
      'offset': offset,
    });
    return result!;
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#movetoposition
  Future<bool> moveToPosition(int position) async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('moveToPosition', {
      'position': position,
    });
    return result!;
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#movetofirst
  Future<bool> moveToFirst() async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('moveToFirst');
    return result!;
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#movetolast
  Future<bool> moveToLast() async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('moveToLast');
    return result!;
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#movetonext
  Future<bool> moveToNext() async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('moveToNext');
    return result!;
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#movetoprevious
  Future<bool> moveToPrevious() async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('moveToPrevious');
    return result!;
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#registercontentobserver
  Future<void> registerContentObserver(ContentObserver observer) {
    assert(!_closed);
    return _methodChannel.invokeMethod<bool>('registerContentObserver', {
      'observer': observer.id,
    });
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#unregistercontentobserver
  Future<void> unregisterContentObserver(ContentObserver observer) {
    assert(!_closed);
    return _methodChannel.invokeMethod<bool>('unregisterContentObserver', {
      'observer': observer.id,
    });
  }

  // fun registerDataSetObserver(observer: DataSetObserver!): Unit
  // https://developer.android.com/reference/kotlin/android/database/AbstractCursor#registerdatasetobserver
  //
  // fun unregisterDataSetObserver(observer: DataSetObserver!): Unit
  // https://developer.android.com/reference/kotlin/android/database/AbstractCursor#unregisterdatasetobserver
  //
  // Since the NativeCursor can only be used to call to platform, these methods are useless,
  // since the only place that can be used to register DataSetObservers is the one that is also
  // in charge of closing the cursor.
  // This could be useful to use in ContentProvider if NativeCursor was used there, but instead
  // CursorData is used, see the NativeCursor doc comments as to why.
  //

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#setnotificationuri
  Future<void> setNotificationUri(String uri) {
    assert(!_closed);
    return _methodChannel.invokeMethod<bool>('setNotificationUri', {
      'uri': uri,
    });
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#setnotificationuris
  @RequiresApiOrNoop(29)
  Future<void> setNotificationUris(List<String> uris) {
    assert(!_closed);
    return _methodChannel.invokeMethod<bool>('setNotificationUris', {
      'uris': uris,
    });
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getnotificationuri
  @RequiresApiOrNoop(19)
  Future<String?> getNotificationUri() {
    assert(!_closed);
    return _methodChannel.invokeMethod<String>('getNotificationUri');
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getnotificationuris
  @RequiresApiOrNoop(29)
  Future<List<String>?> getNotificationUris() {
    assert(!_closed);
    return _methodChannel.invokeListMethod<String>('getNotificationUris');
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#setextras
  @RequiresApiOrNoop(23)
  Future<void> setExtras(BundleMap extras) {
    assert(!_closed);
    return _methodChannel.invokeMethod<void>('setExtras', {
      'extras': extras,
    });
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getextras
  Future<BundleMap> getExtras() async {
    assert(!_closed);
    final result =
        await _methodChannel.invokeMapMethod<String, Object?>('getExtras');
    return result!;
  }

  /// https://developer.android.com/reference/kotlin/android/database/Cursor#respond
  Future<BundleMap> respond(BundleMap extras) async {
    assert(!_closed);
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
  //    Also, it doesn't seem to be useful in Dart

  /// Creates a batch operation of getting data from cursor.
  NativeCursorGetBatch batchedGet() {
    assert(!_closed);
    return NativeCursorGetBatch._(this);
  }
}

/// Represents a batched get operation returned from [NativeCursor.batchedGet].
///
/// Cursor get operations can often be represented as batches, such as
/// reading all values from each row. This representation allows
/// to reduce Flutter channel bottle-necking.
///
/// This class uses a builder pattern so methods can be called one after another.
///
/// To commit the batch and get the data, call [commit].
class NativeCursorGetBatch {
  NativeCursorGetBatch._(this._cursor);

  final NativeCursor _cursor;

  final List<List<Object?>> _operations = [];

  /// A list to store indexes of results to cast `List<Object?>` to `List<String>`.
  final List<int> _stringListIndexes = [];

  /// A list to store indexes of [getType] results to convert them to actual types.
  final List<int> _getTypeIndexes = [];

  void _add(String method, [Object? argument]) {
    assert(!_cursor._closed);
    _operations.add([method, argument]);
  }

  void _correctResult(List<Object?> result) {
    for (final index in _stringListIndexes) {
      result[index] = _asList<String>(result[index])!;
    }
    for (final index in _getTypeIndexes) {
      result[index] = NativeCursor.supportedFieldTypes[result[index] as int];
    }
  }

  /// Commits this batch.
  ///
  /// Only one [commit] or [commitRange] operation can run at once, other calls
  /// won't start before the ongoing commit ends.
  Future<List<Object?>> commit() async {
    assert(!_cursor._closed);
    final result = await _cursor._methodChannel
        .invokeListMethod<Object?>('commitGetBatch', {
      'operations': _operations,
    });
    _correctResult(result!);
    return result;
  }

  /// Commits this batch and applies it for a range of cursor rows.
  ///
  /// Valid range is from 0 to the cursor [getCount].
  ///
  /// The [end] is not strict - if [getCount] is than the [end], the returned list
  /// will just be shorter by their difference.
  ///
  /// Only one [commit] or [commitRange] operation can run at once, other calls
  /// won't start before the ongoing commit ends.
  ///
  /// This function does not affect the cursor position.
  Future<List<List<Object?>>> commitRange(int start, int end) async {
    assert(!_cursor._closed);
    assert(start >= 0);
    assert(start <= end);
    if (start == end) {
      return [];
    }
    final result = await _cursor._methodChannel
        .invokeListMethod<List<Object?>>('commitRangeGetBatch', {
      'operations': _operations,
      'start': start,
      'end': end,
    });
    for (int i = 0; i < result!.length; i++) {
      final row = result[i].cast<Object?>();
      result[i] = row;
      _correctResult(row);
    }
    return result.cast<List<Object?>>();
  }

  /// Will return [int].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getcount
  NativeCursorGetBatch getCount() {
    assert(!_cursor._closed);
    _add('getCount');
    return this;
  }

  /// Will return [int].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getposition
  NativeCursorGetBatch getPosition() {
    _add('getPosition');
    return this;
  }

  /// Will return [bool].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#isfirst
  NativeCursorGetBatch isFirst() {
    _add('isFirst');
    return this;
  }

  /// Will return [bool].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#islast
  NativeCursorGetBatch isLast() {
    _add('isLast');
    return this;
  }

  /// Will return [bool].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#isbeforefirst
  NativeCursorGetBatch isBeforeFirst() {
    _add('isBeforeFirst');
    return this;
  }

  /// Will return [bool].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#isafterlast
  NativeCursorGetBatch isAfterLast() {
    _add('isAfterLast');
    return this;
  }

  /// Will return [int].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getcolumnindex
  NativeCursorGetBatch getColumnIndex(String columnName) {
    _add('getColumnIndex', columnName);
    return this;
  }

  /// Will return [int].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getcolumnindexorthrow
  NativeCursorGetBatch getColumnIndexOrThrow(String columnName) {
    _add('getColumnIndexOrThrow', columnName);
    return this;
  }

  /// Will return [String].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getcolumnname
  NativeCursorGetBatch getColumnName(int columnIndex) {
    _add('getColumnName', columnIndex);
    return this;
  }

  /// Will return `List<String>`.
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getcolumnnames
  NativeCursorGetBatch getColumnNames() {
    _stringListIndexes.add(_operations.length);
    _add('getColumnNames');
    return this;
  }

  /// Will return [int].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getcount
  NativeCursorGetBatch getColumnCount() {
    _add('getColumnCount');
    return this;
  }

  /// Will return [Uint8List] or `null`.
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getblob
  NativeCursorGetBatch getBytes(int columnIndex) {
    _add('getBytes', columnIndex);
    return this;
  }

  /// Will return [String] or `null`.
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getstring
  NativeCursorGetBatch getString(int columnIndex) {
    _add('getString', columnIndex);
    return this;
  }

  /// Will return [int] or `0`, when the column value `null`.
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getshort
  NativeCursorGetBatch getShort(int columnIndex) {
    _add('getShort', columnIndex);
    return this;
  }

  /// Will return [int] or `0`, when the column value `null.
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getint
  NativeCursorGetBatch getInt(int columnIndex) {
    _add('getInt', columnIndex);
    return this;
  }

  /// Will return [int] or `0`, when the column value `null.
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getlong
  NativeCursorGetBatch getLong(int columnIndex) {
    _add('getLong', columnIndex);
    return this;
  }

  /// Will return [double] or `0.0`, when the column value `null.
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getfloat
  NativeCursorGetBatch getFloat(int columnIndex) {
    _add('getFloat', columnIndex);
    return this;
  }

  /// Will return [double] or `0.0`, when the column value `null.
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#getdouble
  NativeCursorGetBatch getDouble(int columnIndex) {
    _add('getDouble', columnIndex);
    return this;
  }

  /// Will return a [Type] that is one of the types listed in [NativeCursor.supportedFieldTypes].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#gettype
  NativeCursorGetBatch getType(int columnIndex) {
    _getTypeIndexes.add(_operations.length);
    _add('getType', columnIndex);
    return this;
  }

  /// Will return [Bool].
  /// https://developer.android.com/reference/kotlin/android/database/Cursor#isnull
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
///  * [NativeCursor], which calls into platform Cursor
abstract class CursorData {
  /// Creates cursor data.
  CursorData({required this.notificationUris});

  /// Actual payload data.
  Object? get payload;

  /// A map with extra values.
  @RequiresApiOr(29, "If set on lower API, only the first entry will be used")
  final List<String>? notificationUris;

  /// A map with extra values.
  @RequiresApiOrNoop(23)
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
    _data.setRange(start, start + _columnCount, columnValues);
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
  /// Throws [CursorRangeError] if you try to add too many values.
  MatrixCursorDataRowBuilder add(Object? columnValue) {
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
