part of android_content_provider;

bool _inCloseScope = false;
List<Closeable> _autoCloseList = [];

/// A scope that automatically closes [Closeable] objects that registered themselves in it.
///
/// Do not try to [Closeable] instances and get the data you need within the scope callback.
FutureOr<T> autoCloseScope<T>(FutureOr<T> Function() callback) async {
  assert(!_inCloseScope);
  assert(_autoCloseList.isEmpty);
  _inCloseScope = true;
  try {
    return await callback();
  } finally {
    try {
      for (final closeable in _autoCloseList) {
        try {
          closeable.close();
        } catch (error, stack) {
          _reportFlutterError(error, stack);
        }
      }
    } finally {
      _autoCloseList.clear();
      _inCloseScope = false;
    }
  }
}

/// Represents an object that can be closed.
///
/// Known subclasses:
///  * [NativeCursor]
abstract class Closeable {
  /// Creates [Closeable].
  const Closeable();

  /// Creates [Closeable] and calls [autoClose].
  Closeable.auto({String? errorMessage}) {
    autoClose(this, errorMessage: errorMessage);
  }

  /// Registers [Closeable] within [autoCloseScope], must be called inside it.
  static void autoClose(Closeable closeable, {String? errorMessage}) {
    assert(() {
      if (!_inCloseScope) {
        try {
          closeable.close();
        } finally {
          throw StateError(errorMessage ??
              "${closeable.runtimeType} must be created inside `autoCloseScope`");
        }
      }
      return true;
    }());
    if (_inCloseScope) {
      _autoCloseList.add(closeable);
    }
  }

  /// Closes this object.
  void close();
}

/// An object that can be associated with some native counterpart instance.
///
/// Typically has a [MethodChannel], but that's not necessary.
///
/// Known interoperables:
///  * [CallingIdentity]
///  * [NativeCursor]
///  * [ReceivedCancellationSignal] and [CancellationSignal]
///  * [ContentObserver]
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
  /// Marked as [visibleForTesting] because it's generally not what an API user should use.
  /// However, it could be useful for custom implementations of [NativeCursor]
  /// or [AndroidContentProvider] (i.e. those using `implements`).
  @visibleForTesting
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
