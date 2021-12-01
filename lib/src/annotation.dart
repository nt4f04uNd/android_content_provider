part of android_content_provider;

/// Annotation on [AndroidContentProvider] methods.
///
/// Indicates that the method has a default native implmentation and can be called
/// by Dart code to perform some action or receive data.
///
/// In contrast, the platform will never call these callbacks in Dart, so overriding
/// on Dart side affects only Dart side.
const native = _Native();

class _Native {
  const _Native();
}

/// Annotation that indicates that some method requires a certain Android API
/// level to work correctly.
///
/// If API level is lower than required, the annotated API will do nothing and
/// return `null` (or `false`, if returned value indicates whether the operation was successful).
///
/// See also:
///  * [RequiresApiOr]
///  * [RequiresApiOrThrows]
class RequiresApiOrNoop {
  /// Creates [RequiresApiOrNoop].
  const RequiresApiOrNoop(this.apiLevel);

  /// Required API level.
  final int apiLevel;
}

/// Annotation that indicates that some method requires a certain Android API
/// level to work correctly.
///
/// If API level is lower than required, the annotated API will will throw.
///
/// See also:
///  * [RequiresApiOr]
///  * [RequiresApiOrNoop]
class RequiresApiOrThrows {
  /// Creates [RequiresApiOrThrows].
  const RequiresApiOrThrows(this.apiLevel);

  /// Required API level.
  final int apiLevel;
}

/// Annotation that indicates that some method requires a certain Android API
/// level to work correctly.
///
/// If API level is lower than required, the annotated API will do what is
/// specified in the [message].
///
/// See also:
///  * [RequiresApiOrNoop]
///  * [RequiresApiOrThrows]
class RequiresApiOr {
  /// Creates [RequiresApiOr].
  const RequiresApiOr(this.apiLevel, this.message);

  /// Required API level.
  final int apiLevel;

  /// What this method will do on lower API versions.
  final String message;
}
