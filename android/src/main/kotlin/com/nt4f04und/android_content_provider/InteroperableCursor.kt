package com.nt4f04und.android_content_provider

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import java.lang.IllegalArgumentException
import java.util.*

class InteroperableCursor(
        private val contentResolver: ContentResolver,
        private val cursor: Cursor,
        binaryMessenger: BinaryMessenger,
        id: String = UUID.randomUUID().toString())
    : Utils, Interoperable<Interoperable.InteroperableMethodChannel>(
        id,
        InteroperableMethodChannel(
                messenger = binaryMessenger,
                classId = "${AndroidContentProviderPlugin.channelPrefix}/Cursor",
                id = id,
                codec = AndroidContentProviderPlugin.pluginMethodCodec)) {

    private val methodChannel
        get() = channel?.channel

    init {
        @Suppress("UNCHECKED_CAST")
        methodChannel!!.setMethodCallHandler { call, result ->
            val args = call.arguments as Map<String, Any>?
            when (call.method) {
                "close" -> {
                    cursor.close()
                    destroy()
                    result.success(null)
                }
                "move" -> {
                    result.success(cursor.move(getLong(args!!["offset"])!!.toInt()))
                }
                "moveToPosition" -> {
                    result.success(cursor.moveToPosition(getLong(args!!["position"])!!.toInt()))
                }
                "moveToFirst" -> {
                    result.success(cursor.moveToFirst())
                }
                "moveToLast" -> {
                    result.success(cursor.moveToLast())
                }
                "moveToNext" -> {
                    result.success(cursor.moveToNext())
                }
                "moveToPrevious" -> {
                    result.success(cursor.moveToPrevious())
                }
                "registerContentObserver" -> {
                    val observerId = args!!["observer"] as String
                    val registrableObserver = RegistrableContentObserver.register(binaryMessenger, observerId)
                    cursor.registerContentObserver(registrableObserver.observer)
                    result.success(null)
                }
                "unregisterContentObserver" -> {
                    val observerId = args!!["observer"] as String
                    val registrableObserver = RegistrableContentObserver.unregister(observerId)
                    registrableObserver?.let {
                        cursor.unregisterContentObserver(registrableObserver.observer)
                    }
                    result.success(null)
                }
                "registerDataSetObserver" -> {
                    val observerId = args!!["observer"] as String
                    val registrableObserver = RegistrableDataSetObserver.register(binaryMessenger, observerId)
                    cursor.registerDataSetObserver(registrableObserver.observer)
                    result.success(null)
                }
                "unregisterDataSetObserver" -> {
                    val observerId = args!!["observer"] as String
                    val registrableObserver = RegistrableDataSetObserver.unregister(observerId)
                    registrableObserver?.let {
                        cursor.unregisterDataSetObserver(registrableObserver.observer)
                    }
                    result.success(null)
                }
                "setNotificationUri" -> {
                    cursor.setNotificationUri(contentResolver, args!!["uri"] as Uri)
                    result.success(null)
                }
                "setNotificationUris" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        cursor.setNotificationUris(contentResolver, args!!["uris"] as ArrayList<Uri>)
                        result.success(null)
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.Q)
                    }
                }
                "getNotificationUri" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        result.success(cursor.notificationUri)
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.KITKAT)
                    }
                }
                "setExtras" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        cursor.extras = mapToBundle(args!!["extras"] as Map<String, Any>)
                        result.success(null)
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.M)
                    }
                }
                "getExtras" -> {
                    result.success(cursor.extras)
                }
                "respond" -> {
                    result.success(cursor.respond(mapToBundle(args!!["extras"] as Map<String, Any>)))
                }
                "commitGetBatch" -> {
                    val resultList = mutableListOf<Any>()
                    for (operationTuple in args!!["operations"] as ArrayList<ArrayList<Any>>) {
                        if (operationTuple.isEmpty() || operationTuple.size > 2) {
                            throw IllegalArgumentException(
                                    "Invalid operation format: operation had length ${operationTuple.size}, " +
                                            "but must have 1 or 2")
                        }
                        val argument =
                                if (operationTuple.size > 1) operationTuple[1]
                                else null
                        val resultValue: Any = when (val operation = operationTuple.first() as String) {
                            "getCount" -> cursor.count
                            "getPosition" -> cursor.position
                            "isFirst" -> cursor.isFirst
                            "isLast" -> cursor.isLast
                            "isBeforeFirst" -> cursor.isBeforeFirst
                            "isAfterLast" -> cursor.isAfterLast
                            "getColumnIndex" -> cursor.getColumnIndex(argument as String)
                            "getColumnIndexOrThrow" -> cursor.getColumnIndexOrThrow(argument as String)
                            "getColumnName" -> cursor.getColumnName(getLong(argument)!!.toInt())
                            "getColumnNames" -> cursor.columnNames
                            "getColumnCount" -> cursor.columnCount
                            "getBytes" -> cursor.getBlob(getLong(argument)!!.toInt())
                            "getShort" -> cursor.getShort(getLong(argument)!!.toInt())
                            "getInt" -> cursor.getInt(getLong(argument)!!.toInt())
                            "getLong" -> cursor.getLong(getLong(argument)!!.toInt())
                            "getFloat" -> cursor.getFloat(getLong(argument)!!.toInt())
                            "getDouble" -> cursor.getDouble(getLong(argument)!!.toInt())
                            "getType" -> cursor.getType(getLong(argument)!!.toInt())
                            "isNull" -> cursor.isNull(getLong(argument)!!.toInt())
                            else -> throw IllegalArgumentException("Unsupported operation: $operation")
                        }
                        resultList.add(resultValue)
                    }
                    result.success(resultList)
                }
            }
        }
    }
}