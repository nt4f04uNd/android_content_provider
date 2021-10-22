import 'android_content_provider_platform_interface.dart';
import 'content_provider_messages.dart';

class MethodChannelAndroidContentProvider
    extends AndroidContentProviderPlatform {
  late ContentProviderApi? _api;

  @override
  ContentProviderApi? get api => _api;

  @override
  set api(ContentProviderApi? value) {
    _api = value;
    ContentProviderApi.setup(value);
  }
}
