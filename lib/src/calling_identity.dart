part of android_content_provider;

/// Opaque token representing the identity of an incoming IPC
/// https://developer.android.com/reference/android/content/ContentProvider.CallingIdentity
class CallingIdentity extends Interoperable {
  /// Creates calling identity from an existing ID.
  @visibleForTesting
  CallingIdentity.fromId(String id) : super.fromId(id);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'CallingIdentity')}($id)';
  }
}
