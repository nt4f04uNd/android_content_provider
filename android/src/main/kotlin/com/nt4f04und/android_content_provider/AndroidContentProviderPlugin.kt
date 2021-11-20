package com.nt4f04und.android_content_provider

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.StandardMethodCodec

class AndroidContentProviderPlugin : FlutterPlugin {
    companion object {
        const val channelPrefix: String = "com.nt4f04und.android_content_provider"
        val pluginMethodCodec = StandardMethodCodec(AndroidContentProviderMessageCodec.INSTANCE)
    }

    private var resolver: AndroidContentResolver? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        resolver = AndroidContentResolver(binding.applicationContext, binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        resolver?.let {
            it.destroy()
            resolver = null
        }
    }
}
