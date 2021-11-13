package com.nt4f04und.android_content_provider

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec

class AndroidContentProviderPlugin : FlutterPlugin {
    companion object {
        const val channelPrefix: String = "com.nt4f04und.android_content_provider"
        val pluginMethodCodec = StandardMethodCodec(AndroidContentProviderMessageCodec.INSTANCE)
    }

    internal var methodChannel: MethodChannel? = null
    private var resolver: AndroidContentResolver? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(
                binding.binaryMessenger,
                "$channelPrefix/plugin",
                StandardMethodCodec.INSTANCE,
                binding.binaryMessenger.makeBackgroundTaskQueue(
                        BinaryMessenger.TaskQueueOptions().setIsSerial(false)))
        resolver = AndroidContentResolver(binding.applicationContext, binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.let {
            it.setMethodCallHandler(null)
            methodChannel = null
        }
        resolver?.let {
            it.destroy()
            resolver = null
        }
    }
}
