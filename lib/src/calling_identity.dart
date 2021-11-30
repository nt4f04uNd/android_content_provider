part of android_content_provider;

/// Opaque token representing the identity of an incoming IPC.
class CallingIdentity extends Interoperable {
  /// Creates native cursor from an existing ID.
  @visibleForTesting
  CallingIdentity.fromId(String id) : super.fromId(id);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'CallingIdentity')}($id)';
  }
}
