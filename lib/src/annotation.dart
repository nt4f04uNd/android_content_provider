part of android_content_provider;

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


/// Used to indicate that some method requires a certain Android API
/// level to work, and that method will do nothing and return `null` (or `false`,
/// if returned value indicates whether the operation was successful),
/// if called on lower API versions.
class RequiresApiOrNoop {
  /// Creates [RequiresApiOrNoop].
  const RequiresApiOrNoop(this.apiLevel);

  /// Required API level.
  final int apiLevel;
}

/// Used to indicate that some method requires a certain Android API
/// level to work, and that method will throw if called on lower API versions.
class RequiresApiOrThrows {
  /// Creates [RequiresApiOrThrows].
  const RequiresApiOrThrows(this.apiLevel);

  /// Required API level.
  final int apiLevel;
}

/// Used to indicate that some method requires a certain Android API
/// level to work, and that method will do something else, specified in the [message],
/// if called on lower API versions.
class RequiresApiOr {
  /// Creates [RequiresApiOr].
  const RequiresApiOr(this.apiLevel, this.message);

  /// Required API level.
  final int apiLevel;

  /// What this method will do on lower API versions.
  final String message;
}
