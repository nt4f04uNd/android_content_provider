package com.nt4f04und.android_content_provider

import android.content.ContentProvider
import java.util.concurrent.ConcurrentHashMap

abstract class RegistrableCallingIdentity {
    companion object {
        private val map = ConcurrentHashMap<String, ContentProvider.CallingIdentity>()
        fun register(id: String, value: ContentProvider.CallingIdentity) {
            // For som reason writing it like so asks to wrap it into OS version check:
            // map[id] = value
            @Suppress("ReplacePutWithAssignment")
            map.put(id, value)
        }
        fun unregister(id: String) : ContentProvider.CallingIdentity? {
            return map.remove(id)
        }
    }
}
