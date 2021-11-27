package com.nt4f04und.android_content_provider

import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMethodCodec
import java.lang.Exception
import java.util.*

class InteroperableCancellationSignal private constructor(
        messenger: BinaryMessenger,
        id: String = UUID.randomUUID().toString(),
        private var initialized: Boolean)
    : Utils, Interoperable<Interoperable.InteroperableMethodChannel>(
        messenger,
        id,
        AndroidContentProviderPlugin.TrackingMapKeys.CANCELLATION_SIGNAL.value,
        InteroperableMethodChannel(
                messenger = messenger,
                classId = "${AndroidContentProviderPlugin.channelPrefix}/CancellationSignal",
                id = id,
                codec = StandardMethodCodec.INSTANCE)) {

    constructor(messenger: BinaryMessenger,
                id: String = UUID.randomUUID().toString())
            : this(messenger, id, false)

    companion object {
        fun fromId(messenger: BinaryMessenger, id: String): InteroperableCancellationSignal {
            return InteroperableCancellationSignal(messenger, id, true)
        }
    }

    var signal: CancellationSignal? = CancellationSignal()
    private val methodChannel get() = channel?.channel

    init {
        if (initialized) {
            Handler(Looper.getMainLooper()).post {
                methodChannel?.invokeMethod("init", null)
            }
        }
        var cancelledFromDart = false
        var pendingCancel = false
        fun invokeDartCancel() {
            if (!initialized) {
                pendingCancel = true
            } else {
                pendingCancel = false
                // Dart already know the signal is cancelled, because it was the
                // initiator of the cancel.
                if (!cancelledFromDart) {
                    methodChannel?.setMethodCallHandler(null)
                    Handler(Looper.getMainLooper()).post {
                        try {
                            methodChannel?.invokeMethod("cancel", null)
                        } finally {
                            destroy()
                        }
                    }
                }
            }
        }
        methodChannel!!.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "init" -> {
                        initialized = true
                        if (pendingCancel) {
                            invokeDartCancel()
                        }
                    }
                    "cancel" -> {
                        // Save this to variable instead of nulling out setOnCancelListener,
                        // because signal might receive have some custom listener, which for example
                        // happens in [AndroidContentProvider]
                        cancelledFromDart = true
                        signal?.cancel()
                        destroy()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e : Exception) {
                methodCallFail(result, e)
            }
        }
        signal!!.setOnCancelListener {
            invokeDartCancel()
        }
    }

    public override fun destroy() {
        super.destroy()
        signal?.setOnCancelListener(null)
        signal = null
    }
}