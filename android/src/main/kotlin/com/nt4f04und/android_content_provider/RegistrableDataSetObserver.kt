package com.nt4f04und.android_content_provider

import android.database.DataSetObserver
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMethodCodec
import java.util.*

class RegistrableDataSetObserver(
        binaryMessenger: BinaryMessenger,
        id: String = UUID.randomUUID().toString())
    : Registrable<Interoperable.InteroperableEventChannel>(
        id,
        InteroperableEventChannel(
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
    private val eventChannel
        get() = channel

    init {
        observer = Observer(this)
    }

    override fun destroy() {
        super.destroy()
        observer = null
    }

    class Observer(private val registryObserver: RegistrableDataSetObserver) : DataSetObserver() {
        override fun onChanged() {
            registryObserver.eventChannel!!.sink!!.success("onChanged")
        }

        override fun onInvalidated() {
            registryObserver.eventChannel!!.sink!!.success("onInvalidated")
        }
    }
}