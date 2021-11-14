package com.nt4f04und.android_content_provider

import android.net.Uri
import android.os.Bundle
import androidx.core.os.bundleOf

internal interface Utils {
    fun getLong(o: Any?): Long? =
            if (o == null || o is Long) o as Long?
            else (o as Int).toLong()

    fun mapToBundle(map: Map<String, Any>?): Bundle? =
            if (map == null) null
            else bundleOf(*map.toList().toTypedArray())

    fun getUri(value: Any?): Uri {
        return Uri.parse(value as String)
    }

    fun getUris(value: Any?): List<Uri> {
        @Suppress("UNCHECKED_CAST")
        return (value as ArrayList<String>).map { el -> Uri.parse(el) }
    }

    fun throwApiLevelError(level: Int) {
        throw IllegalStateException("Available only from Android API level $level")
    }
}