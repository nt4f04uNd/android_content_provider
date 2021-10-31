package com.nt4f04und.android_content_provider

import android.content.ContentProviderOperation
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class AndroidContentProviderPlugin : FlutterPlugin {
    private lateinit var resolverApi : ContentResolverApi
    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        resolverApi = ContentResolverApi()
        ContentResolverMessages.ContentResolverApi.setup(binding.binaryMessenger, resolverApi)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        ContentResolverMessages.ContentResolverApi.setup(null, null)
    }
}

private class ContentResolverApi : ContentResolverMessages.ContentResolverApi {
    override fun create(message: ContentResolverMessages.CreateMessage?) {
        ContentProviderOperation
    }

    override fun getType(message: ContentResolverMessages.GetTypeMessage?): String {

    }
}
