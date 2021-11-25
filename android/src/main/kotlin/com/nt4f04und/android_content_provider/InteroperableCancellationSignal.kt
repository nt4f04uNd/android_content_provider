package com.nt4f04und.android_content_provider

import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMethodCodec
import java.util.*

class InteroperableCancellationSignal private constructor(
        binaryMessenger: BinaryMessenger,
        id: String = UUID.randomUUID().toString(),
        private var initialized: Boolean)
    : Interoperable<Interoperable.InteroperableMethodChannel>(
        id,
        InteroperableMethodChannel(
                messenger = binaryMessenger,
                classId = "${AndroidContentProviderPlugin.channelPrefix}/CancellationSignal",
                id = id,
                codec = StandardMethodCodec.INSTANCE)) {

    constructor(binaryMessenger: BinaryMessenger,
                id: String = UUID.randomUUID().toString())
            : this(binaryMessenger, id, false)

    companion object {
        fun fromId(binaryMessenger: BinaryMessenger, id: String): InteroperableCancellationSignal {
            return InteroperableCancellationSignal(binaryMessenger, id, true)
        }
    }

    var signal: CancellationSignal? = CancellationSignal()
    private val methodChannel
        get() = channel?.channel

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