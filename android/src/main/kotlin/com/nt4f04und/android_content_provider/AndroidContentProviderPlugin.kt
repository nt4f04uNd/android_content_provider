package com.nt4f04und.android_content_provider

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.StandardMethodCodec
import java.util.concurrent.ConcurrentHashMap

class AndroidContentProviderPlugin : FlutterPlugin {
    companion object {
        const val channelPrefix: String = "com.nt4f04und.android_content_provider"
        val pluginMethodCodec = StandardMethodCodec(AndroidContentProviderMessageCodec.INSTANCE)
    }

    enum class TrackingMapKeys(val value: String) {
        BACKGROUND_TASK_QUEUES("BACKGROUND_TASK_QUEUES"),
        CURSOR("CURSOR"),
        CANCELLATION_SIGNAL("CANCELLATION_SIGNAL"),
        CALLING_IDENTITY("CALLING_IDENTITY"),
        CONTENT_OBSERVER("CONTENT_OBSERVER"),
    }

    private var trackingMapFactory: TrackingMapFactory? = null
    private var resolver: AndroidContentResolver? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        resolver = AndroidContentResolver(binding.applicationContext, binding.binaryMessenger)
        trackingMapFactory = TrackingMapFactory(binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        trackingMapFactory?.let {
            it.destroy(mapOf(
                    TrackingMapKeys.BACKGROUND_TASK_QUEUES.value to { map -> map.clear() },
                    TrackingMapKeys.CALLING_IDENTITY.value to { map -> map.clear() },
                    TrackingMapKeys.CURSOR.value to { map ->
                        @Suppress("UNCHECKED_CAST")
                        for (interoperable in (map as ConcurrentHashMap<String, Interoperable<*>>).values) {
                            interoperable.destroy()
                        }
                    },
                    TrackingMapKeys.CANCELLATION_SIGNAL.value to { map ->
                        @Suppress("UNCHECKED_CAST")
                        for (interoperable in (map as ConcurrentHashMap<String, Interoperable<*>>).values) {
                            interoperable.destroy()
                        }
                    },
                    TrackingMapKeys.CONTENT_OBSERVER.value to { map ->
                        @Suppress("UNCHECKED_CAST")
                        for (interoperable in (map as ConcurrentHashMap<String, Interoperable<*>>).values) {
                            val registrableContentObserver = interoperable as RegistrableContentObserver
                            RegistrableContentObserver.unregister(binding.binaryMessenger, registrableContentObserver.id)
                            val observer = registrableContentObserver.observer
                            binding.applicationContext.contentResolver.unregisterContentObserver(observer)
                        }
                    },
            ))
            trackingMapFactory = null
        }
        resolver?.let {
            it.destroy()
            resolver = null
        }
    }
}
