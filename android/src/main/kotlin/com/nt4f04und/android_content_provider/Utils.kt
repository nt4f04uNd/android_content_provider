package com.nt4f04und.android_content_provider

import android.net.Uri
import android.os.Bundle
import androidx.core.os.bundleOf

interface Utils {
    fun getLong(o: Any?): Long? =
            if (o == null || o is Long) o as Long?
            else (o as Int).toLong()

    fun mapToBundle(map: Map<String, Any?>?): Bundle? =
            if (map == null) null
            else bundleOf(*map.toList().toTypedArray())

    /** Non nullable, in the whole plugin, there are no nullable URI strings */
    fun getUri(value: Any?): Uri {
        return Uri.parse(value as String)
    }

    fun <T> asList(value: Any?): ArrayList<T>? {
        @Suppress("UNCHECKED_CAST")
        return value as ArrayList<T>?
    }

    fun asMap(value: Any?): Map<String, Any?>? {
        @Suppress("UNCHECKED_CAST")
        return value as Map<String, Any?>?
    }

    fun getUris(value: Any?): List<Uri>? {
        return asList<String>(value)?.map { el -> Uri.parse(el) }
    }

    fun throwApiLevelError(level: Int) {
        throw IllegalStateException("Available only from Android API level $level")
    }
}

inline fun <reified T> Utils.listAsArray(value: Any?): Array<T>? {
    @Suppress("UNCHECKED_CAST")
    return (value as ArrayList<T>?)?.toTypedArray()
}