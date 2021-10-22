import 'dart:async';

import 'package:android_content_provider_platform_interface/content_provider_messages.dart';
import 'package:android_content_provider_platform_interface/android_content_provider_platform_interface.dart';
import 'package:flutter/cupertino.dart';

class AndroidContentProviderBinding {
  static bool _initialized = false;
  static late _ContentProviderApi _api;
  static void _ensureInitialized() {
    if (!_initialized) {
      _initialized = true;
      WidgetsFlutterBinding.ensureInitialized();
      _api = _ContentProviderApi();
      AndroidContentProviderPlatform.instance.api = _api;
    }
  }
 
  static Future<String> getAuthority() async {
    _ensureInitialized();
    return _api.authorityCompleter.future;
  }

  static void setupProvider(AndroidContentProvider provider) {
    _ensureInitialized();
    _api.contentProvider = provider;
  }
}

abstract class AndroidContentProvider {
  String? getType(Uri uri);
}

class _ContentProviderApi extends ContentProviderApi {
  late AndroidContentProvider contentProvider;
  final authorityCompleter = Completer<String>();

  @override
  void create(CreateMessage message) {
    authorityCompleter.complete(message.authority!);
  }

  @override
  String getType(GetTypeMessage message) {
    return contentProvider.getType(Uri.parse(message.uri!))!;
  }
}
