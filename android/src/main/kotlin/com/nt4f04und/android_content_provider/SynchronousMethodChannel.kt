package com.nt4f04und.android_content_provider

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import java.lang.Exception
import java.lang.IllegalStateException

/** Calls [MethodChannel.invokeMethod], blocking the caller thread. */
internal class SynchronousMethodChannel(private val methodChannel: MethodChannel) {
    private val handler = Handler(Looper.getMainLooper())

    fun invokeMethod(method: String, arguments: Any?): Any? {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            throw IllegalStateException(
                    "Calling synchronous invokeMethod the UI thread is not supported " +
                    "as this would lead to a deadlock")
        }
        var completed = false
        var value: Any? = null
        var error: Exception? = null
        val lock = Object()
        handler.postDelayed({
            methodChannel.invokeMethod(method, arguments, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    value = result
                    completed = true
                    synchronized(lock) { lock.notify() }
                }

                override fun error(code: String?, msg: String?, details: Any?) {
                    error = Exception(msg)
                    completed = true
                    synchronized(lock) { lock.notify() }
                }

                override fun notImplemented() {
                    error = Exception("Not implemented")
                    completed = true
                    synchronized(lock) { lock.notify() }
                }
            })
        }, 1000)
        try {
            synchronized(lock) {
                while (!completed) {
                    lock.wait()
                }
            }
        } catch (e: InterruptedException) {
            return null
        }
        if (error != null) {
            throw error!!
        }
        return value
    }
}