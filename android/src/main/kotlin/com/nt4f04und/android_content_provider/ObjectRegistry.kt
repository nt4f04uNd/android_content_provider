package com.nt4f04und.android_content_provider

import androidx.annotation.CallSuper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCodec
import java.lang.IllegalArgumentException
import java.lang.IllegalStateException
import java.util.concurrent.ConcurrentHashMap

/**
 * Creates a class that can have a dart counterpart.
 *
 * May have a [channel], but this is not necessary.
 * To release the object resources call [destroy].
 *
 * Use this class when you have a short living instance,
 * which can be released at the end of the method call from dart.
 * Example - [InteroperableCancellationSignal].
 *
 * Otherwise use [Registrable].
 */
abstract class Interoperable<T : Interoperable.InteroperableChannel>(
        val id: String,
        protected var channel: T?
) {
    /** Releases the object resources. Closes channels by default. */
    @CallSuper
    protected open fun destroy() {
        channel?.let {
            it.destroy()
            channel = null
        }
    }

    /** Abstract channel that represents either [InteroperableMethodChannel] or [InteroperableEventChannel]. */
    abstract class InteroperableChannel(
            private val messenger: BinaryMessenger,
            private val classId: String
    ) {
        abstract fun destroy()

        companion object {
            private val taskQueueMap = ConcurrentHashMap<TaskQueueKey, BinaryMessenger.TaskQueue>()
        }

        private data class TaskQueueKey(
                private val binaryMessenger: BinaryMessenger,
                private val id: String)

        /**
         * Creates a background queue per [classId] and [messenger].
         *
         * For example, all [InteroperableCancellationSignal] will create and share
         * only one [BinaryMessenger.TaskQueue] per single [FlutterEngine].
         */
        fun makeBackgroundTaskQueue(): BinaryMessenger.TaskQueue {
            if (classId.split("/").size != 2) {
                throw IllegalArgumentException("classId had invalid format. It must have the following format 'authority/Class'")
            }
            val key = TaskQueueKey(messenger, classId)
            var taskQueue = taskQueueMap[key]
            if (taskQueue == null) {
                taskQueue = messenger.makeBackgroundTaskQueue(
                        BinaryMessenger.TaskQueueOptions().setIsSerial(false))
                taskQueueMap[key] = taskQueue
            }
            return taskQueue!!
        }
    }

    /** Wraps [MethodChannel]. */
    class InteroperableMethodChannel(
            messenger: BinaryMessenger,
            classId: String,
            id: String,
            codec: MethodCodec
    ) : InteroperableChannel(messenger, classId) {
        var channel: MethodChannel? = null

        init {
            channel = MethodChannel(
                    messenger,
                    "$classId/$id",
                    codec,
                    makeBackgroundTaskQueue())
        }

        @CallSuper
        override fun destroy() {
            channel?.let {
                it.setMethodCallHandler(null)
                channel = null
            }
        }
    }

    /** Wraps [EventChannel]. */
    class InteroperableEventChannel(
            messenger: BinaryMessenger,
            classId: String,
            id: String,
            codec: MethodCodec
    ) : InteroperableChannel(messenger, classId) {
        var channel: EventChannel? = null
        var sink: EventChannel.EventSink? = null

        init {
            channel = EventChannel(
                    messenger,
                    "$classId/$id",
                    codec,
                    makeBackgroundTaskQueue())
            channel!!.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sink = events
                }

                override fun onCancel(arguments: Any?) {
                    sink?.endOfStream()
                    sink = null
                }
            })
        }

        @CallSuper
        override fun destroy() {
            sink?.let {
                it.endOfStream()
                sink = null
            }
            channel?.let {
                it.setStreamHandler(null)
                channel = null
            }
        }
    }
}

/**
 * An [Interoperable] that can be registered within a [registry].
 *
 * See [Registry] for documentation on a lifecycle of a [Registrable].
 *
 * The companion object of a subclass should implement the [RegistrableCompanion] interface.
 *
 * Use this class when you have to keep object instances between method calls,
 * from dart.
 * Example - [RegistrableContentObserver].
 *
 * Otherwise use [Interoperable].
 */
abstract class Registrable<T : Interoperable.InteroperableChannel>(
        id: String,
        channel: T?
) : Interoperable<T>(id, channel) {
    protected abstract val registry: Registry<out Registrable<T>>

    /**
     * Releases the object resources. Closes channels by default.
     * Called when registrable reaches 0 registrations in [Registry].
     */
    override fun destroy() {
        super.destroy()
        if (registry[id] != null) {
            throw IllegalStateException("`destroy` was called while the object was still registered " +
                    "by some code user. All users must call `forget` before this the `destroy` can be called.")
        }
    }

    /** An interface to be implemented by a companion of a [Registrable] subclass. */
    interface RegistrableCompanion<T : Registrable<out InteroperableChannel>> {
        /** Should return an object from [Registrable.registry] */
        fun get(id: String): T?

        /** Should call [Registry.register] */
        fun register(binaryMessenger: BinaryMessenger, id: String): T

        /** Should call [Registry.unregister] */
        fun unregister(id: String): T?
    }

    /**
     * Thread-safe registry for [Registrable] classes of the given [T] type.
     *
     * When [register] is first called with some ID, the object is created from
     * the given factory and saved. On consecutive calls the registry will
     * save the amount of registrations on this instance.
     *
     * When [unregister] is called the registration amount is reduced by 1.
     * When this amount reaches 0, the [Registrable.destroy] is called, and
     * the instance is removed from the registry.
     */
    class Registry<T : Registrable<out InteroperableChannel>> {
        private val registryMap = ConcurrentHashMap<String, ObjectRegistryObjectEntry>()

        private class ObjectRegistryObjectEntry(val value: Registrable<out InteroperableChannel>) {
            var registrationCount: Int = 0
        }

        /** Registers an object and returns it. */
        @Synchronized
        fun register(id: String, factory: () -> T): T {
            var entry = registryMap[id]
            if (entry == null) {
                entry = ObjectRegistryObjectEntry(factory())
                registryMap[id] = entry
            }
            entry.registrationCount += 1
            @Suppress("UNCHECKED_CAST")
            return entry.value as T
        }

        /** Unregisters an object and returns it. */
        @Synchronized
        fun unregister(id: String): T? {
            val entry = registryMap[id]
            entry?.let {
                if (entry.registrationCount == 1) {
                    registryMap.remove(id)?.value?.destroy()
                } else {
                    entry.registrationCount -= 1
                }
            }
            @Suppress("UNCHECKED_CAST")
            return entry?.value as T?
        }

        /** [] get operator */
        operator fun get(id: String): T? {
            @Suppress("UNCHECKED_CAST")
            return registryMap[id]?.value as T?
        }
    }
}
