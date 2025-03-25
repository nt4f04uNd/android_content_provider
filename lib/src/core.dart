part of '../android_content_provider.dart';

const _uuid = Uuid();
const _channelPrefix = 'com.nt4f04und.android_content_provider';
const _pluginMethodCodec =
    StandardMethodCodec(AndroidContentProviderMessageCodec());

void _reportFlutterError(Object error, StackTrace stack) {
  FlutterError.reportError(FlutterErrorDetails(
    exception: error,
    stack: stack,
    library: 'android_content_provider',
  ));
}

/// Map type alias that is used in place of Android Bundle
/// https://developer.android.com/reference/android/os/Bundle.
///
/// Decoded values inside a [BundleMap] that is received from native
/// will use `List<Object?>` and `Map<Object?, Object?>`
/// irresponsive of content.
typedef BundleMap = Map<String, Object?>;
