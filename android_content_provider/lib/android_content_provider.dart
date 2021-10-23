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

  // applyBatch(String authority, ArrayList<ContentProviderOperation> operations)
  // applyBatch(ArrayList<ContentProviderOperation> operations)
  // attachInfo(Context context, ProviderInfo info)
  // bulkInsert(Uri uri, ContentValues[] values)
  // call(String authority, String method, String arg, Bundle extras)
  // call(String method, String arg, Bundle extras)
  // canonicalize(Uri url)
  // clearCallingIdentity()
  // delete(Uri uri, String selection, String[] selectionArgs)
  // delete(Uri uri, Bundle extras)
  // dump(FileDescriptor fd, PrintWriter writer, String[] args)
  // getCallingAttributionSource()
  // getCallingAttributionTag()
  // getCallingPackage()
  // getCallingPackageUnchecked()
  // getContext()
  // getPathPermissions()
  // getReadPermission()
  // getStreamTypes(Uri uri, String mimeTypeFilter)
  // getType(Uri uri)
  // getWritePermission()
  // insert(Uri uri, ContentValues values, Bundle extras)
  // insert(Uri uri, ContentValues values)
  // onCallingPackageChanged()
  // onConfigurationChanged(Configuration newConfig)
  // onCreate()
  // onLowMemory()
  // onTrimMemory(int level)
  // openAssetFile(Uri uri, String mode, CancellationSignal signal)
  // openAssetFile(Uri uri, String mode)
  // openFile(Uri uri, String mode, CancellationSignal signal)
  // openFile(Uri uri, String mode)
  // openPipeHelper(Uri uri, String mimeType, Bundle opts, T args, PipeDataWriter<T> func)
  // openTypedAssetFile(Uri uri, String mimeTypeFilter, Bundle opts, CancellationSignal signal)
  // openTypedAssetFile(Uri uri, String mimeTypeFilter, Bundle opts)
  // query(Uri uri, String[] projection, Bundle queryArgs, CancellationSignal cancellationSignal)
  // query(Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder, CancellationSignal cancellationSignal)
  // query(Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder)
  // refresh(Uri uri, Bundle extras, CancellationSignal cancellationSignal)
  // requireContext()
  // restoreCallingIdentity(ContentProvider.CallingIdentity identity)
  // shutdown()
  // uncanonicalize(Uri url)
  // update(Uri uri, ContentValues values, Bundle extras)
  // update(Uri uri, ContentValues values, String selection, String[] selectionArgs)
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
