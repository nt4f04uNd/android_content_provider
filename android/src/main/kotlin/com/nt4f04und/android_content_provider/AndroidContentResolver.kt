package com.nt4f04und.android_content_provider

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.util.Size
import androidx.core.graphics.drawable.toBitmap
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream


internal class AndroidContentResolver(
        private val context: Context,
        private val binaryMessenger: BinaryMessenger)
    : MethodChannel.MethodCallHandler, Utils {

    private val methodChannel: MethodChannel = MethodChannel(
            binaryMessenger,
            "${AndroidContentProviderPlugin.channelPrefix}/ContentResolver",
            AndroidContentProviderPlugin.pluginMethodCodec,
            binaryMessenger.makeBackgroundTaskQueue(
                    BinaryMessenger.TaskQueueOptions().setIsSerial(false)))

    init {
        methodChannel.setMethodCallHandler(this)
    }

    fun destroy() {
        methodChannel.setMethodCallHandler(null)
    }

    private val contentResolver: ContentResolver
        get() = context.applicationContext.contentResolver

    private fun bitmapToBytes(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
        return stream.toByteArray()
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as Map<String, Any>?
        var interoperableSignal: InteroperableCancellationSignal? = null
        try {
            when (call.method) {
                "bulkInsert" -> {
                    result.success(contentResolver.bulkInsert(
                            args!!["uri"] as Uri,
                            (args["values"] as ArrayList<out ContentValues>).toTypedArray()))
                }
                "call" -> {
                    result.success(contentResolver.call(
                            args!!["uri"] as Uri,
                            args["method"] as String,
                            args["arg"] as String?,
                            mapToBundle(args["extras"] as Map<String, Any>?)))
                }
                "callWithAuthority" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        result.success(contentResolver.call(
                                args!!["authority"] as String,
                                args["method"] as String,
                                args["arg"] as String?,
                                mapToBundle(args["extras"] as Map<String, Any>?)))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.Q)
                    }
                }
                "canonicalize" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        result.success(contentResolver.canonicalize(args!!["url"] as Uri))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.KITKAT)
                    }
                }
                "delete" -> {
                    result.success(contentResolver.delete(
                            args!!["uri"] as Uri,
                            args["selection"] as String?,
                            (args["selectionArgs"] as ArrayList<String>?)?.toTypedArray()))
                }
                "deleteWithExtras" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(contentResolver.delete(
                                args!!["uri"] as Uri,
                                mapToBundle(args["extras"] as Map<String, Any>?)))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.R)
                    }
                }
                "getStreamTypes" -> {
                    result.success(contentResolver.getStreamTypes(
                            args!!["uri"] as Uri,
                            args["mimeTypeFilter"] as String))
                }
                "getType" -> {
                    result.success(contentResolver.getType(args!!["uri"] as Uri))
                }
                "getTypeInfo" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val info = contentResolver.getTypeInfo(args!!["mimeType"] as String)
                        result.success(mapOf(
                                "label" to info.label,
                                "icon" to bitmapToBytes(info.icon.loadDrawable(context).toBitmap()),
                                "contentDescription" to info.contentDescription))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.Q)
                    }
                }
                "insert" -> {
                    result.success(contentResolver.insert(
                            args!!["uri"] as Uri,
                            args["values"] as ContentValues?))
                }
                "insertWithExtras" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(contentResolver.insert(
                                args!!["uri"] as Uri,
                                args["values"] as ContentValues?,
                                mapToBundle(args["extras"] as Map<String, Any>?)))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.R)
                    }
                }
                "loadThumbnail" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val cancellationSignalId = args!!["cancellationSignal"] as String?
                        cancellationSignalId?.let { interoperableSignal = InteroperableCancellationSignal.fromId(binaryMessenger, it) }
                        result.success(bitmapToBytes(contentResolver.loadThumbnail(
                                args["uri"] as Uri,
                                Size(getLong(args["width"])!!.toInt(),
                                        getLong(args["height"])!!.toInt()),
                                interoperableSignal?.signal)))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.Q)
                    }
                }
                "notifyChange" -> {
                    val observerId = args!!["observer"] as String?
                    var registrableObserver: RegistrableContentObserver? = null
                    observerId?.let { registrableObserver = RegistrableContentObserver.get(it) }
                    val flags = args["flags"] as Int?
                    if (flags != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        contentResolver.notifyChange(
                                args["uri"] as Uri,
                                registrableObserver?.observer,
                                flags)

                    } else {
                        contentResolver.notifyChange(
                                args["uri"] as Uri,
                                registrableObserver?.observer)
                    }
                    result.success(null)
                }
                "notifyChangeWithList" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val observerId = args!!["observer"] as String?
                        var registrableObserver: RegistrableContentObserver? = null
                        observerId?.let { registrableObserver = RegistrableContentObserver.get(it) }
                        contentResolver.notifyChange(
                                args["uri"] as ArrayList<Uri>,
                                registrableObserver?.observer,
                                args["flags"] as Int)
                        result.success(null)
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.R)
                    }
                }
                "query" -> {
                    val cursor = contentResolver.query(
                            args!!["uri"] as Uri,
                            (args["projection"] as ArrayList<String>?)?.toTypedArray(),
                            args["selection"] as String?,
                            (args["selectionArgs"] as ArrayList<String>?)?.toTypedArray(),
                            args["sortOrder"] as String?)
                            ?: return result.success(null)
                    val interoperableCursor = InteroperableCursor(
                            contentResolver,
                            cursor,
                            binaryMessenger)
                    result.success(interoperableCursor.id)
                }
                "queryWithSignal" -> {
                    val cancellationSignalId = args!!["cancellationSignal"] as String?
                    cancellationSignalId?.let { interoperableSignal = InteroperableCancellationSignal.fromId(binaryMessenger, it) }
                    val cursor = contentResolver.query(
                            args["uri"] as Uri,
                            (args["projection"] as ArrayList<String>?)?.toTypedArray(),
                            args["selection"] as String?,
                            (args["selectionArgs"] as ArrayList<String>?)?.toTypedArray(),
                            args["sortOrder"] as String?,
                            interoperableSignal?.signal)
                            ?: return result.success(null)
                    val interoperableCursor = InteroperableCursor(
                            contentResolver,
                            cursor,
                            binaryMessenger)
                    result.success(interoperableCursor.id)
                }
                "queryWithBundle" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val cancellationSignalId = args!!["cancellationSignal"] as String?
                        cancellationSignalId?.let { interoperableSignal = InteroperableCancellationSignal.fromId(binaryMessenger, it) }
                        val cursor = contentResolver.query(
                                args["uri"] as Uri,
                                (args["projection"] as ArrayList<String>?)?.toTypedArray(),
                                mapToBundle(args["queryArgs"] as Map<String, Any>?),
                                interoperableSignal?.signal)
                                ?: return result.success(null)
                        val interoperableCursor = InteroperableCursor(
                                contentResolver,
                                cursor,
                                binaryMessenger)
                        result.success(interoperableCursor.id)
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.O)
                    }
                }
                "refresh" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val cancellationSignalId = args!!["cancellationSignal"] as String?
                        cancellationSignalId?.let { interoperableSignal = InteroperableCancellationSignal.fromId(binaryMessenger, it) }
                        result.success(contentResolver.refresh(
                                args["uri"] as Uri,
                                mapToBundle(args["extras"] as Map<String, Any>?),
                                interoperableSignal?.signal))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.O)
                    }
                }
                "registerContentObserver" -> {
                    val observerId = args!!["observer"] as String
                    val registrableObserver = RegistrableContentObserver.register(binaryMessenger, observerId)
                    contentResolver.registerContentObserver(
                            args["uri"] as Uri,
                            args["notifyForDescendants"] as Boolean,
                            registrableObserver.observer!!)
                    result.success(null)
                }
                "uncanonicalize" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        result.success(contentResolver.uncanonicalize(args!!["url"] as Uri))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.KITKAT)
                    }
                }
                "unregisterContentObserver" -> {
                    val observerId = args!!["observer"] as String
                    val observer = RegistrableContentObserver.unregister(observerId)
                    observer?.observer?.let {
                        contentResolver.unregisterContentObserver(it)
                    }
                    result.success(null)
                }
                "update" -> {
                    result.success(contentResolver.update(
                            args!!["url"] as Uri,
                            args["values"] as ContentValues?,
                            args["selection"] as String?,
                            (args["selectionArgs"] as ArrayList<String>?)?.toTypedArray()))
                }
                "updateWithExtras" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(contentResolver.update(
                                args!!["url"] as Uri,
                                args["values"] as ContentValues?,
                                mapToBundle(args["extras"] as Map<String, Any>?)))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.R)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        } finally {
            interoperableSignal?.destroy()
        }
    }
}
