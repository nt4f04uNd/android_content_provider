package com.nt4f04und.android_content_provider

import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import java.util.*

class RegistrableContentObserver(
        binaryMessenger: BinaryMessenger,
        id: String = UUID.randomUUID().toString())
    : Registrable<Interoperable.InteroperableMethodChannel>(
        id,
        InteroperableMethodChannel(
                messenger = binaryMessenger,
                classId = "${AndroidContentProviderPlugin.channelPrefix}/ContentObserver",
                id = id,
                codec = AndroidContentProviderPlugin.pluginMethodCodec)) {

    companion object : RegistrableCompanion<RegistrableContentObserver> {
        private val staticRegistry = Registry<RegistrableContentObserver>()

        override fun get(id: String): RegistrableContentObserver? {
            return staticRegistry[id]
        }

        @Synchronized
        override fun register(binaryMessenger: BinaryMessenger, id: String): RegistrableContentObserver {
            return staticRegistry.register(id) { RegistrableContentObserver(binaryMessenger, id) }
        }

        @Synchronized
        override fun unregister(id: String): RegistrableContentObserver? {
            return staticRegistry.unregister(id)
        }
    }

    var observer: Observer? = null
    override val registry: Registry<RegistrableContentObserver>
        get() = staticRegistry
    private val methodChannel
        get() = channel?.channel

    init {
        observer = Observer(this)
    }

    override fun destroy() {
        super.destroy()
        observer = null
    }

    class Observer(
            private val registryObserver: RegistrableContentObserver)
        : ContentObserver(Handler(Looper.myLooper()!!)) {

        override fun deliverSelfNotifications(): Boolean {
            return true
        }

        override fun onChange(selfChange: Boolean) {
            registryObserver.methodChannel!!.invokeMethod("onChange", mapOf(
                    "selfChange" to selfChange
            ))
        }

        override fun onChange(selfChange: Boolean, uri: Uri?) {
            registryObserver.methodChannel!!.invokeMethod("onChange", mapOf(
                    "selfChange" to selfChange,
                    "uri" to uri
            ))
        }

        override fun onChange(selfChange: Boolean, uri: Uri?, flags: Int) {
            registryObserver.methodChannel!!.invokeMethod("onChange", mapOf(
                    "selfChange" to selfChange,
                    "uri" to uri,
                    "flags" to flags
            ))
        }

        override fun onChange(selfChange: Boolean, uris: Collection<Uri>, flags: Int) {
            registryObserver.methodChannel!!.invokeMethod("onChangeUris", mapOf(
                    "selfChange" to selfChange,
                    "uris" to uris,
                    "flags" to flags
            ))
        }
    }
}