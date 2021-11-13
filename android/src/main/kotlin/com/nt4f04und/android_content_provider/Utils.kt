package com.nt4f04und.android_content_provider

import android.os.Bundle
import androidx.core.os.bundleOf

internal interface Utils {
    fun getLong(o: Any?): Long? =
            if (o == null || o is Long) o as Long?
            else (o as Int).toLong()

    fun mapToBundle(map: Map<String, Any>?): Bundle? =
            if (map == null) null
            else bundleOf(*map.toList().toTypedArray())

    fun throwApiLevelError(level: Int) {
        throw IllegalStateException("Available only from Android API level $level")
    }
}