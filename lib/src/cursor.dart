part of android_content_provider;


/// The cursor that calls into platform Cursor
/// https://developer.android.com/reference/android/database/Cursor
///
/// Must be created within [autoCloseScope] and will be automatically closed
/// once its callback ends. Therefore, do not try to store cursor instances and get the
/// data you need within the scope callback.
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
class NativeCursor extends Interoperable implements Closeable {
  /// Creates native cursor from an existing ID.
  @visibleForTesting
  NativeCursor.fromId(String id)
      : _methodChannel = MethodChannel(
          '$_channelPrefix/Cursor/$id',
          _pluginMethodCodec,
        ),
        super.fromId(id) {
    Closeable.autoClose(
      this,
      errorMessage:
          "AndroidContentResolver.query methods must be called inside `autoCloseScope`. "
          "The $NativeCursor was instantiated outside the `autoCloseScope`.",
    );
  }

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

  @override
  Future<void> close() async {
    if (!_closed) {
      _closed = true;
      return _methodChannel.invokeMethod<void>('close');
    }
  }

  Future<bool> move(int offset) async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('move', {
      'offset': offset,
    });
    return result!;
  }

  Future<bool> moveToPosition(int position) async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('moveToPosition', {
      'position': position,
    });
    return result!;
  }

  Future<bool> moveToFirst() async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('moveToFirst');
    return result!;
  }

  Future<bool> moveToLast() async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('moveToLast');
    return result!;
  }

  Future<bool> moveToNext() async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('moveToNext');
    return result!;
  }

  Future<bool> moveToPrevious() async {
    assert(!_closed);
    final result = await _methodChannel.invokeMethod<bool>('moveToPrevious');
    return result!;
  }

  Future<void> registerContentObserver(ContentObserver observer) {
    assert(!_closed);
    return _methodChannel.invokeMethod<bool>('registerContentObserver', {
      'observer': observer.id,
    });
  }

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

  Future<void> setNotificationUri(String uri) {
    assert(!_closed);
    return _methodChannel.invokeMethod<bool>('setNotificationUri', {
      'uri': uri,
    });
  }

  @RequiresApiOrNoop(29)
  Future<void> setNotificationUris(List<String> uris) {
    assert(!_closed);
    return _methodChannel.invokeMethod<bool>('setNotificationUris', {
      'uris': uris,
    });
  }

  @RequiresApiOrNoop(19)
  Future<String?> getNotificationUri() {
    assert(!_closed);
    return _methodChannel.invokeMethod<String>('getNotificationUri');
  }

  @RequiresApiOrNoop(29)
  Future<List<String>?> getNotificationUris() {
    assert(!_closed);
    return _methodChannel.invokeListMethod<String>('getNotificationUris');
  }

  @RequiresApiOrNoop(23)
  Future<void> setExtras(BundleMap extras) {
    assert(!_closed);
    return _methodChannel.invokeMethod<bool>('setExtras', {
      'extras': extras,
    });
  }

  Future<BundleMap> getExtras() async {
    assert(!_closed);
    final result =
        await _methodChannel.invokeMapMethod<String, Object?>('getExtras');
    return result!;
  }

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

  /// A list to store indexes of results to cast `List<Object?>` to `List<String>`.
  final List<int> _stringListIndexes = [];

  /// A list to store indexes of [getType] results to convert them to actual types.
  final List<int> _getTypeIndexes = [];

  void _add(String method, [Object? argument]) {
    _operations.add([method, argument]);
  }

  /// Commits a batch
  Future<List<Object>> commit() async {
    final result = await _cursor._methodChannel
        .invokeListMethod<Object>('commitGetBatch', {
      'operations': _operations,
    });
    for (final index in _stringListIndexes) {
      result![index] = _asList<String>(result[index])!;
    }
    for (final index in _getTypeIndexes) {
      result![index] = NativeCursor.supportedFieldTypes[result[index] as int];
    }
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
    _stringListIndexes.add(_operations.length);
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
    _getTypeIndexes.add(_operations.length);
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
  /// Throws [CursorRangeError] if you try to add too many values
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
