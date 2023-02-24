package com.nt4f04und.android_content_provider

import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import java.util.*

class RegistrableContentObserver private constructor(
        messenger: BinaryMessenger,
        id: String = UUID.randomUUID().toString())
    : Registrable<Interoperable.InteroperableMethodChannel>(
        messenger,
        id,
        AndroidContentProviderPlugin.TrackingMapKeys.CONTENT_OBSERVER.value,
        InteroperableMethodChannel(
                messenger = messenger,
                classId = "${AndroidContentProviderPlugin.channelPrefix}/ContentObserver",
                id = id,
                codec = AndroidContentProviderPlugin.pluginMethodCodec)) {

    companion object : RegistrableCompanion<RegistrableContentObserver> {
        private fun getRegistry(messenger: BinaryMessenger): Registry<RegistrableContentObserver> {
            return Registry(
                    messenger,
                    AndroidContentProviderPlugin.TrackingMapKeys.CONTENT_OBSERVER.value)
        }

        override fun get(messenger: BinaryMessenger, id: String): RegistrableContentObserver? {
            return getRegistry(messenger)[id]
        }

        @Synchronized
        override fun register(messenger: BinaryMessenger, id: String): RegistrableContentObserver {
            return getRegistry(messenger).register(id) { RegistrableContentObserver(messenger, id) }
        }

        @Synchronized
        override fun unregister(messenger: BinaryMessenger, id: String): RegistrableContentObserver? {
            return getRegistry(messenger).unregister(id)
        }
    }

    val observer: Observer = Observer(this)
    override val registry get() = getRegistry(messenger)
    private val methodChannel get() = channel?.channel

    class Observer(
            private val registryObserver: RegistrableContentObserver)
        : ContentObserver(Handler(Looper.getMainLooper())) {

        override fun deliverSelfNotifications(): Boolean {
            return true
        }

        override fun onChange(selfChange: Boolean) {
            registryObserver.methodChannel?.invokeMethod("onChange", mapOf(
                    "selfChange" to selfChange
            ))
        }

        override fun onChange(selfChange: Boolean, uri: Uri?) {
            registryObserver.methodChannel?.invokeMethod("onChange", mapOf(
                    "selfChange" to selfChange,
                    "uri" to uri
            ))
        }

        override fun onChange(selfChange: Boolean, uri: Uri?, flags: Int) {
            registryObserver.methodChannel?.invokeMethod("onChange", mapOf(
                    "selfChange" to selfChange,
                    "uri" to uri,
                    "flags" to flags
            ))
        }

        override fun onChange(selfChange: Boolean, uris: Collection<Uri?>, flags: Int) {
            registryObserver.methodChannel?.invokeMethod("onChangeUris", mapOf(
                    "selfChange" to selfChange,
                    "uris" to uris,
                    "flags" to flags
            ))
        }
    }
}