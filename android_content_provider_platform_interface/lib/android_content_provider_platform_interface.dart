import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'content_provider_messages.dart';
import 'method_channel_android_content_provider.dart';

/// The interface each platform implementation must implement.
abstract class AndroidContentProviderPlatform extends PlatformInterface {
   /// Constructs an AndroidContentProviderPlatform.
  AndroidContentProviderPlatform() : super(token: _token);

  static final Object _token = Object();

  static AndroidContentProviderPlatform _instance = MethodChannelAndroidContentProvider();

  /// The default instance of [AndroidContentProviderPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudioService].
  static AndroidContentProviderPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [AndroidContentProviderPlatform] when they register themselves.
  //
  // TODO: rewrite when https://github.com/flutter/flutter/issues/43368 is resolved.
  static set instance(AndroidContentProviderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  ContentProviderApi? get api;
  set api(ContentProviderApi? value);
}
