package com.nt4f04und.android_content_provider

import android.content.ContentProvider
import android.os.Build
import androidx.annotation.RequiresApi
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@RequiresApi(Build.VERSION_CODES.Q)
abstract class RegistrableCallingIdentity {
    companion object {
        private val map = ConcurrentHashMap<String, ContentProvider.CallingIdentity>()

        fun register(value: ContentProvider.CallingIdentity): String {
            val id = UUID.randomUUID().toString()
            map[id] = value
            return id
        }

        fun unregister(id: String): ContentProvider.CallingIdentity? {
            return map.remove(id)
        }
    }
}
