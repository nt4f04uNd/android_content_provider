package com.nt4f04und.android_content_provider

import android.os.CancellationSignal
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMethodCodec
import java.lang.Exception
import java.util.*

class InteroperableCancellationSignal(
        binaryMessenger: BinaryMessenger,
        id: String = UUID.randomUUID().toString())
    : Interoperable<Interoperable.InteroperableMethodChannel>(
        id,
        InteroperableMethodChannel(
                messenger = binaryMessenger,
                classId = "${AndroidContentProviderPlugin.channelPrefix}/CancellationSignal",
                id = id,
                codec = StandardMethodCodec.INSTANCE)) {

    companion object {
        fun fromId(binaryMessenger: BinaryMessenger, id: String): InteroperableCancellationSignal {
            return InteroperableCancellationSignal(binaryMessenger, id)
        }
    }

    var signal: CancellationSignal? = CancellationSignal()
    private val methodChannel
        get() = channel?.channel

    init {
        methodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "cancel" -> {
                    signal?.setOnCancelListener(null)
                    signal?.cancel()
                    destroy()
                }
                else -> result.notImplemented()
            }
        }
        signal!!.setOnCancelListener {
            methodChannel?.setMethodCallHandler(null)
            try {
                methodChannel?.invokeMethod("cancel", null)
            } catch (ex: Exception) {
                // Swallow exceptions in case the channel has not been initialized yet.
            } finally {
                destroy()
            }
        }
    }

    public override fun destroy() {
        super.destroy()
        signal?.setOnCancelListener(null)
        signal = null
    }
}