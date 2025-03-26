package com.nt4f04und.android_content_provider

import android.os.ConditionVariable
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import java.lang.Exception
import java.lang.IllegalStateException

internal class SynchronousMethodChannel(val methodChannel: MethodChannel) {
    private val handler = Handler(Looper.getMainLooper())

    /** Synchronously calls [MethodChannel.invokeMethod], blocking the caller thread. */
    fun invokeMethod(method: String, arguments: Any?): Any? {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            throw IllegalStateException(
                "Calling synchronous invokeMethod on the UI thread is not supported " +
                        "as this would lead to a deadlock")
        }

        val condition = ConditionVariable()
        var value: Any? = null
        var error: Exception? = null

        handler.post {
            try {
                methodChannel.invokeMethod(method, arguments, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        value = result
                        condition.open()
                    }

                    override fun error(code: String, msg: String?, details: Any?) {
                        error = Exception("code: $code, message: $msg, details: $details")
                        condition.open()
                    }

                    override fun notImplemented() {
                        error = Exception("Not implemented")
                        condition.open()
                    }
                })
            } catch (e: Exception) {
                error = e
                condition.open()
            }
        }

        condition.block()

        if (error != null) {
            throw error!!
        }
        return value
    }
}
