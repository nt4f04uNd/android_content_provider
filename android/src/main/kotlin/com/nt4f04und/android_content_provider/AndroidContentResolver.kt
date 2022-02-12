package com.nt4f04und.android_content_provider

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import android.util.Size
import androidx.core.graphics.drawable.toBitmap
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import android.util.TimingLogger
import kotlin.system.measureTimeMillis
import kotlin.time.measureTime


internal class AndroidContentResolver(
        private val context: Context,
        private val messenger: BinaryMessenger)
    : MethodChannel.MethodCallHandler, Utils {

    private val methodChannel: MethodChannel = MethodChannel(
            messenger,
            "${AndroidContentProviderPlugin.channelPrefix}/ContentResolver",
            AndroidContentProviderPlugin.pluginMethodCodec,
            messenger.makeBackgroundTaskQueue(
                BinaryMessenger.TaskQueueOptions().setIsSerial(false)))

    init {
        methodChannel.setMethodCallHandler(this)
    }

    fun destroy() {
        methodChannel.setMethodCallHandler(null)
    }

    private val executor = Executors.newCachedThreadPool()

    private val contentResolver: ContentResolver
        get() = context.applicationContext.contentResolver

    private fun bitmapToBytes(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
        return stream.toByteArray()
    }

    // https://stackoverflow.com/a/28927163/9710294
    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int
    ): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1
        if (height > reqHeight || width > reqWidth) {
            val halfHeight = height / 2
            val halfWidth = width / 2
            while (halfHeight / inSampleSize >= reqHeight
                && halfWidth / inSampleSize >= reqWidth
            ) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        var interoperableSignal: InteroperableCancellationSignal? = null
        try {
            val args = call.arguments as Map<String, Any>?
            when (call.method) {
                "bulkInsert" -> {
                    result.success(contentResolver.bulkInsert(
                            getUri(args!!["uri"]),
                            listAsArray<ContentValues>(args["values"])!!))
                }
                "call" -> {
                    result.success(contentResolver.call(
                            getUri(args!!["uri"]),
                            args["method"] as String,
                            args["arg"] as String?,
                            mapToBundle(asMap(args["extras"]))))
                }
                "callWithAuthority" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        result.success(contentResolver.call(
                                args!!["authority"] as String,
                                args["method"] as String,
                                args["arg"] as String?,
                                mapToBundle(asMap(args["extras"]))))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.Q)
                    }
                }
                "canonicalize" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        result.success(contentResolver.canonicalize(getUri(args!!["url"])))
                    } else {
                        result.success(null)
                    }
                }
                "delete" -> {
                    result.success(contentResolver.delete(
                            getUri(args!!["uri"]),
                            args["selection"] as String?,
                            listAsArray<String?>(args["selectionArgs"])))
                }
                "deleteWithExtras" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(contentResolver.delete(
                                getUri(args!!["uri"]),
                                mapToBundle(asMap(args["extras"]))))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.R)
                    }
                }
                "getStreamTypes" -> {
                    result.success(contentResolver.getStreamTypes(
                            getUri(args!!["uri"]),
                            args["mimeTypeFilter"] as String))
                }
                "getType" -> {
                    result.success(contentResolver.getType(getUri(args!!["uri"])))
                }
                "getTypeInfo" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val info = contentResolver.getTypeInfo(args!!["mimeType"] as String)
                        result.success(mapOf(
                                "label" to info.label,
                                "icon" to bitmapToBytes(info.icon.loadDrawable(context).toBitmap()),
                                "contentDescription" to info.contentDescription))
                    } else {
                        result.success(null)
                    }
                }
                "insert" -> {
                    result.success(contentResolver.insert(
                            getUri(args!!["uri"]),
                            args["values"] as ContentValues?))
                }
                "insertWithExtras" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(contentResolver.insert(
                                getUri(args!!["uri"]),
                                args["values"] as ContentValues?,
                                mapToBundle(asMap(args["extras"]))))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.R)
                    }
                }
                "loadThumbnail" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val cancellationSignalId = args!!["cancellationSignal"] as String?
                        cancellationSignalId?.let { interoperableSignal = InteroperableCancellationSignal.fromId(messenger, it) }
                        result.success(bitmapToBytes(contentResolver.loadThumbnail(
                                getUri(args["uri"]),
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
                    observerId?.let { registrableObserver = RegistrableContentObserver.get(messenger, it) }
                    val flags = args["flags"] as Int?
                    if (flags != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        contentResolver.notifyChange(
                                getUri(args["uri"]),
                                registrableObserver?.observer,
                                flags)

                    } else {
                        contentResolver.notifyChange(
                                getUri(args["uri"]),
                                registrableObserver?.observer)
                    }
                    result.success(null)
                }
                "notifyChangeWithList" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val observerId = args!!["observer"] as String?
                        var registrableObserver: RegistrableContentObserver? = null
                        observerId?.let { registrableObserver = RegistrableContentObserver.get(messenger, it) }
                        contentResolver.notifyChange(
                                getUris(args["uris"])!!,
                                registrableObserver?.observer,
                                args["flags"] as Int)
                        result.success(null)
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.R)
                    }
                }
                "query" -> {
                    val cursor = contentResolver.query(
                            getUri(args!!["uri"]),
                            listAsArray<String?>(args["projection"]),
                            args["selection"] as String?,
                            listAsArray<String?>(args["selectionArgs"]),
                            args["sortOrder"] as String?)
                            ?: return result.success(null)
                    val interoperableCursor = InteroperableCursor(
                            contentResolver,
                            cursor,
                            messenger)
                    result.success(interoperableCursor.id)
                }
                "queryWithSignal" -> {
                    val cancellationSignalId = args!!["cancellationSignal"] as String?
                    cancellationSignalId?.let { interoperableSignal = InteroperableCancellationSignal.fromId(messenger, it) }
                    val cursor = contentResolver.query(
                            getUri(args["uri"]),
                            listAsArray<String?>(args["projection"]),
                            args["selection"] as String?,
                            listAsArray<String?>(args["selectionArgs"]),
                            args["sortOrder"] as String?,
                            interoperableSignal?.signal)
                            ?: return result.success(null)
                    val interoperableCursor = InteroperableCursor(
                            contentResolver,
                            cursor,
                            messenger)
                    result.success(interoperableCursor.id)
                }
                "queryWithExtras" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val cancellationSignalId = args!!["cancellationSignal"] as String?
                        cancellationSignalId?.let { interoperableSignal = InteroperableCancellationSignal.fromId(messenger, it) }
                        val cursor = contentResolver.query(
                                getUri(args["uri"]),
                                listAsArray<String?>(args["projection"]),
                                mapToBundle(asMap(args["queryArgs"])),
                                interoperableSignal?.signal)
                                ?: return result.success(null)
                        val interoperableCursor = InteroperableCursor(
                                contentResolver,
                                cursor,
                                messenger)
                        result.success(interoperableCursor.id)
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.O)
                    }
                }
                "refresh" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val cancellationSignalId = args!!["cancellationSignal"] as String?
                        cancellationSignalId?.let { interoperableSignal = InteroperableCancellationSignal.fromId(messenger, it) }
                        result.success(contentResolver.refresh(
                                getUri(args["uri"]),
                                mapToBundle(asMap(args["extras"])),
                                interoperableSignal?.signal))
                    } else {
                        result.success(false)
                    }
                }
                "registerContentObserver" -> {
                    val observerId = args!!["observer"] as String
                    val registrableObserver = RegistrableContentObserver.register(messenger, observerId)
                    contentResolver.registerContentObserver(
                            getUri(args["uri"]),
                            args["notifyForDescendants"] as Boolean,
                            registrableObserver.observer)
                    result.success(null)
                }
                "uncanonicalize" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        result.success(contentResolver.uncanonicalize(getUri(args!!["url"])))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.KITKAT)
                    }
                }
                "unregisterContentObserver" -> {
                    val observerId = args!!["observer"] as String
                    val observer = RegistrableContentObserver.unregister(messenger, observerId)
                    observer?.observer?.let {
                        contentResolver.unregisterContentObserver(it)
                    }
                    result.success(null)
                }
                "update" -> {
                    result.success(contentResolver.update(
                            getUri(args!!["uri"]),
                            args["values"] as ContentValues?,
                            args["selection"] as String?,
                            listAsArray<String?>(args["selectionArgs"])))
                }
                "updateWithExtras" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(contentResolver.update(
                                getUri(args!!["uri"]),
                                args["values"] as ContentValues?,
                                mapToBundle(asMap(args["extras"]))))
                    } else {
                        throwApiLevelError(Build.VERSION_CODES.R)
                    }
                }
                "compat_loadThumbnail" -> {
                    val cancellationSignalId = args!!["cancellationSignal"] as String?
                    cancellationSignalId?.let {
                        interoperableSignal = InteroperableCancellationSignal.fromId(messenger, it)
                    }
                    val uri = getUri(args["uri"])
                    val width = getLong(args["width"])!!.toInt()
                    val height = getLong(args["height"])!!.toInt()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        result.success(bitmapToBytes(contentResolver.loadThumbnail(
                            uri,
                            Size(width, height),
                            interoperableSignal?.signal)))
                    } else {
                        executor.execute {
                            try {
                                // Fallback to something similar prior Android Q
                                fun isCancelled(): Boolean {
                                    return interoperableSignal?.signal?.isCanceled ?: false
                                }
                                fun print(s: String) {
                                    Log.w("_WHAT", s)
                                }
                                if (isCancelled())
                                    return@execute result.success(null)
                                var start = System.currentTimeMillis()
                                val parcelFileDescriptor =
                                    contentResolver.openFileDescriptor(uri, "r")
                                var time = System.currentTimeMillis() - start
                                print("1 $time")
                                parcelFileDescriptor.use { pfd ->
                                    val fileDescriptor = pfd
                                        ?.fileDescriptor
                                        ?: return@execute result.success(null)
                                    val options = BitmapFactory.Options()
                                    options.inJustDecodeBounds = true
                                    if (isCancelled())
                                        return@execute result.success(null)
                                    start = System.currentTimeMillis()
                                    BitmapFactory.decodeFileDescriptor(
                                        fileDescriptor,
                                        null,
                                        options
                                    )
                                    time = System.currentTimeMillis() - start
                                    print("2 $time")
                                    options.inSampleSize =
                                        calculateInSampleSize(options, width, height)
                                    options.inJustDecodeBounds = false
                                    if (isCancelled())
                                        return@execute result.success(null)
                                    start = System.currentTimeMillis()
                                    val bitmap =
                                        BitmapFactory.decodeFileDescriptor(
                                            fileDescriptor,
                                            null,
                                            options
                                        )
                                    time = System.currentTimeMillis() - start
                                    print("3 $time")
                                    result.success(
                                        if (bitmap != null) bitmapToBytes(bitmap)
                                        else null
                                    )
                                }
                            } catch (e: Exception) {
                                methodCallFail(result, e)
                            } finally {
                                interoperableSignal?.destroy()
                            }
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            methodCallFail(result, e)
        } finally {
            interoperableSignal?.destroy()
        }
    }
}
