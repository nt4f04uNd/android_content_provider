part of android_content_provider;


/// Receives call backs for changes to content
/// https://developer.android.com/reference/android/database/ContentObserver
abstract class ContentObserver extends Interoperable {
  /// Creates content observer.
  ContentObserver() : this._(_uuid.v4());
  ContentObserver._(this._id)
      : _methodChannel = MethodChannel(
          '$_channelPrefix/ContentObserver/$_id',
          _pluginMethodCodec,
        ) {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  String get id => _id;
  final String _id;

  final MethodChannel _methodChannel;

  Future<dynamic> _handleMethodCall(MethodCall methodCall) async {
    final BundleMap? args = _asMap<String, Object?>(methodCall.arguments);
    // Catch and report the exceptions, because the calls are made by the system which
    // otherwise swallows them.
    switch (methodCall.method) {
      case 'onChange':
        try {
          final uri = args!['uri'] as String?;
          return onChange(
            args['selfChange'] as bool,
            uri,
            args['flags'] as int?,
          );
        } catch (error, stack) {
          _reportFlutterError(error, stack);
          return null;
        }
      case 'onChangeUris':
        try {
          final uris = _asList<String>(args!['uris'])!;
          return onChangeUris(
            args['selfChange'] as bool,
            uris,
            args['flags'] as int?,
          );
        } catch (error, stack) {
          _reportFlutterError(error, stack);
          return null;
        }
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

  /// Disposes the content observer, so it no longer receives updates.
  @mustCallSuper
  void dispose() {
    _methodChannel.setMethodCallHandler(null);
  }

  // Dispatch methods are not exposed. They can only be useful to dispatch
  // messages on a different supplied handler. Dart doesn't have a way to allow
  // this, thus dispatching can only be overriden natively.
  //
  // If you were just looking for a way to dispatch a notification - just call [onChange] or
  // [onChangeUris] directly. This is what native [dispatch] does anyways, when there's no
  // handler supplied.
}
