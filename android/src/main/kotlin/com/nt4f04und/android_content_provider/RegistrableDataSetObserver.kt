package com.nt4f04und.android_content_provider

import android.database.DataSetObserver
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMethodCodec
import java.util.*

class RegistrableDataSetObserver private constructor(
        binaryMessenger: BinaryMessenger,
        id: String = UUID.randomUUID().toString())
    : Registrable<Interoperable.InteroperableMethodChannel>(
        id,
        InteroperableMethodChannel(
                messenger = binaryMessenger,
                classId = "${AndroidContentProviderPlugin.channelPrefix}/DataSetObserver",
                id = id,
                codec = StandardMethodCodec.INSTANCE)) {

    companion object : RegistrableCompanion<RegistrableDataSetObserver> {
        private val staticRegistry = Registry<RegistrableDataSetObserver>()

        override fun get(id: String): RegistrableDataSetObserver? {
            return staticRegistry[id]
        }

        @Synchronized
        override fun register(binaryMessenger: BinaryMessenger, id: String): RegistrableDataSetObserver {
            return staticRegistry.register(id) { RegistrableDataSetObserver(binaryMessenger, id) }
        }

        @Synchronized
        override fun unregister(id: String): RegistrableDataSetObserver? {
            return staticRegistry.unregister(id)
        }
    }

    var observer: Observer? = null
    override val registry: Registry<RegistrableDataSetObserver>
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

    class Observer(private val registryObserver: RegistrableDataSetObserver) : DataSetObserver() {
        private val handler = Handler(Looper.getMainLooper())

        override fun onChanged() {
            handler.post {
                registryObserver.methodChannel?.invokeMethod("onChanged", null)
            }
        }

        override fun onInvalidated() {
            handler.post {
                registryObserver.methodChannel?.invokeMethod("onInvalidated", null)
            }
        }
    }
}