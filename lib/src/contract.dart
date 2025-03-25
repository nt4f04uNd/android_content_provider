part of '../android_content_provider.dart';

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
  Interoperable() : this.fromId(_uuid.v4());

  /// Creates an object from an existing ID.
  ///
  /// The opposite of [Interoperable.new].
  /// Used when the platform creats an object and needs a Dart counterpart.
  ///
  /// Marked as [visibleForTesting] because it's generally not what an API user should use.
  /// However, it can be used to create custom interoperables.
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
