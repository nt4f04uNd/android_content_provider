package com.nt4f04und.android_content_provider

import io.flutter.plugin.common.BinaryMessenger
import java.lang.IllegalArgumentException
import java.util.concurrent.ConcurrentHashMap

/** Allows to create and track [ConcurrentHashMap]s. */
class TrackingMapFactory(private val messenger: BinaryMessenger) {
    init {
        if (factories[messenger] != null) {
            throw IllegalStateException("The factory was already created for the given messenger.")
        }
        factories[messenger] = this
    }

    /**
     * Destroys the factory.
     *
     * For each registered map, there must be an entry in [clearingOperations], which will
     * clean the map with the matching ID, disposing claimed resources, if necessary.
     */
    fun destroy(clearingOperations: Map<String, ((ConcurrentHashMap<*, *>) -> Unit)?>) {
        for (entry in mapPool.entries) {
            val clearingOperation = clearingOperations[entry.key]
            clearingOperation?.invoke(entry.value)
        }
        for (entry in mapPool.entries) {
            if (entry.value.isNotEmpty()) {
                val clearingOperation = clearingOperations[entry.key]
                throw IllegalArgumentException(
                        "All created maps must be cleared out, disposing claimed resources, if necessary." +
                                if (clearingOperation == null) " Did you forget to add a clearing operation?"
                                else "")
            }
        }
        untrackedMapPool.clear()
        factories.remove(messenger)
    }

    companion object {
        private val factories = ConcurrentHashMap<BinaryMessenger, TrackingMapFactory>()

        /**
         * Obtains an existing [TrackingMapFactory] for the given [messenger].
         * Throws, if not found.
         */
        fun get(messenger: BinaryMessenger): TrackingMapFactory {
            return factories[messenger]
                    ?: throw IllegalStateException("The factory was not found for the given messenger.")
        }
    }

    private val mapPool = ConcurrentHashMap<String, ConcurrentHashMap<Any?, Any?>>()
    private val untrackedMapPool = ConcurrentHashMap<String, ConcurrentHashMap<Any?, Any?>>()

    /**
     * Obtains a typed map for the given ID from the the map pool,
     * or creates one, if necessary, and puts it into the map pool.
     */
    @Synchronized
    fun <K, V> getMap(id: String): ConcurrentHashMap<K, V> {
        @Suppress("UNCHECKED_CAST")
        var map: ConcurrentHashMap<K, V>? = mapPool[id] as ConcurrentHashMap<K, V>?
        if (map != null) {
            return map
        }
        map = ConcurrentHashMap<K, V>()
        @Suppress("UNCHECKED_CAST")
        mapPool[id] = map as ConcurrentHashMap<Any?, Any?>
        return map
    }

    /**
     * Obtains an untracked typed map for the given ID from the the map pool,
     * or creates one, if necessary, and puts it into the map pool.
     */
    @Synchronized
    fun <K, V> getUntrackedMap(id: String): ConcurrentHashMap<K, V> {
        @Suppress("UNCHECKED_CAST")
        var map: ConcurrentHashMap<K, V>? = untrackedMapPool[id] as ConcurrentHashMap<K, V>?
        if (map != null) {
            return map
        }
        map = ConcurrentHashMap<K, V>()
        @Suppress("UNCHECKED_CAST")
        untrackedMapPool[id] = map as ConcurrentHashMap<Any?, Any?>
        return map
    }
}
