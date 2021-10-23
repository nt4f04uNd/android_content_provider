import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut:
      '../android_content_provider_platform_interface/lib/content_provider_messages.dart',
  // dartTestOut:
  //     '../android_content_provider_platform_interface/test/test_api.dart',
  javaOut:
      'android/src/main/java/com/nt4f04und/android_content_provider/ContentProviderMessages.java',
  javaOptions: JavaOptions(
    package: 'com.nt4f04und.android_content_provider',
  ),
))
@FlutterApi()
abstract class ContentProviderApi {
  void create(CreateMessage message);
  String getType(GetTypeMessage message);
}

class CreateMessage {
  String? authority;
}

class GetTypeMessage {
  String? authority;
  String? uri;
}
