part of android_content_provider;

/// [AndroidContentResolver] that is compatible with older Android
/// versions.
class AndroidContentResolverCompat {
  /// Creates [AndroidContentResolver] that is compatible with older Android
  /// versions.
  const AndroidContentResolverCompat();

  /// Constant [AndroidContentResolverCompat] instance.
  static const instance = AndroidContentResolverCompat();

  /// Backwards compatible version of [AndroidContentResolver.loadThumbnail].
  Future<Uint8List?> loadThumbnail({
    required String uri,
    required int width,
    required int height,
    CancellationSignal? cancellationSignal,
  }) async {
    try {
      final result = await AndroidContentResolver._methodChannel
          .invokeMethod<Uint8List>('compat_loadThumbnail', {
        'uri': uri,
        'width': width,
        'height': height,
        'cancellationSignal': cancellationSignal?.id,
      });
      return result;
    } finally {
      cancellationSignal?.dispose();
    }
  }
}
