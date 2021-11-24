package com.nt4f04und.android_content_provider

import android.content.ContentValues
import android.net.Uri
import android.os.Bundle
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.charset.Charset

/**
 * The codec utilized to encode data back and forth between
 * the Dart and the native platform.
 *
 * See Dart's `AndroidContentProviderMessageCodec` for more details.
 */
class AndroidContentProviderMessageCodec : StandardMessageCodec() {
    companion object {
        val INSTANCE: AndroidContentProviderMessageCodec = AndroidContentProviderMessageCodec()

        internal const val NULL = 0
        internal const val TRUE = 1
        internal const val FALSE = 2
        internal const val URI = 134
        internal const val BUNDLE = 133
        internal const val CONTENT_VALUES = 132
        internal const val BYTE = 128
        internal const val SHORT = 129
        internal const val INTEGER = 3
        internal const val LONG = 4
        internal const val FLOAT = 131
        internal const val DOUBLE = 6
        internal const val STRING = 7
        internal const val BYTE_ARRAY = 8
    }

    override fun writeValue(stream: ByteArrayOutputStream?, value: Any?) {
        when (value) {
            is Uri -> {
                stream!!.write(URI)
                writeBytes(stream, value.toString().toByteArray())
            }
            is Bundle -> {
                stream!!.write(BUNDLE)
                writeSize(stream, value.size())
                for (key in value.keySet()) {
                    writeValue(stream, key)
                    writeValue(stream, value.get(key))
                }
            }
            is ContentValues -> {
                stream!!.write(CONTENT_VALUES)
                writeSize(stream, value.size())
                @Suppress("UNCHECKED_CAST")
                for (key in value.keySet()) {
                    val contentValuesValue = value.get(key)
                    writeValue(stream, key);
                    when (contentValuesValue) {
                        is String -> {
                            stream.write(STRING)
                            writeBytes(stream, contentValuesValue.toString().toByteArray())
                        }
                        is Byte -> {
                            stream.write(BYTE)
                            writeInt(stream, contentValuesValue.toInt())
                        }
                        is Short -> {
                            stream.write(SHORT)
                            writeInt(stream, contentValuesValue.toInt())
                        }
                        is Int -> {
                            stream.write(INTEGER)
                            writeInt(stream, contentValuesValue.toInt())
                        }
                        is Long -> {
                            stream.write(LONG)
                            writeLong(stream, contentValuesValue.toLong())
                        }
                        is Float -> {
                            stream.write(FLOAT)
                            writeAlignment(stream, 8)
                            writeDouble(stream, contentValuesValue.toDouble());
                        }
                        is Double -> {
                            stream.write(DOUBLE)
                            writeAlignment(stream, 8)
                            writeDouble(stream, contentValuesValue.toDouble())
                        }
                        true -> {
                            stream.write(TRUE)
                        }
                        false -> {
                            stream.write(FALSE)
                        }
                        is ByteArray -> {
                            stream.write(BYTE_ARRAY)
                            writeBytes(stream, contentValuesValue)
                        }
                        null -> {
                            stream.write(NULL)
                        }
                        else -> {
                            throw IllegalArgumentException("Wrong value in ContentValues")
                        }
                    }
                }
            }
            else -> {
                try {
                    // allow write standard writeValue to do its work,
                    // including the conversion of int[], long[], etc.
                    super.writeValue(stream, value)
                } catch (e: IllegalArgumentException) {
                    when (value) {
                        // convert array unsupported in standard writeValue to list
                        is Array<*> -> writeValue(stream, value.toList())
                        // otherwise rethrow
                        else -> throw e
                    }
                }
            }
        }
    }

    override fun readValueOfType(type: Byte, buffer: ByteBuffer?): Any? {
        when (type) {
            URI.toByte() -> {
                throw IllegalArgumentException("Uri byte should not be sent to native, use regular String instead")
            }
            BUNDLE.toByte() -> {
                throw IllegalArgumentException("Bundle byte should not be sent to native, use regular map instead")
            }
            CONTENT_VALUES.toByte() -> {
                val size = readSize(buffer)
                val contentValues = ContentValues(size)
                for (i in 0 until size) {
                    val key = readValue(buffer) as String
                    // taken from readValue, but put the value right away
                    require(buffer!!.hasRemaining()) { "Message corrupted" }
                    when (buffer.get()) {
                        STRING.toByte() -> {
                            val bytes = readBytes(buffer)
                            contentValues.put(key, String(bytes, Charset.forName("UTF8")))
                        }
                        BYTE.toByte() -> {
                            contentValues.put(key, buffer.int.toShort().toByte())
                        }
                        SHORT.toByte() -> {
                            contentValues.put(key, buffer.int.toShort())
                        }
                        INTEGER.toByte() -> {
                            contentValues.put(key, buffer.int)
                        }
                        LONG.toByte() -> {
                            contentValues.put(key, buffer.long)
                        }
                        FLOAT.toByte() -> {
                            readAlignment(buffer, 8)
                            contentValues.put(key, buffer.double.toFloat())
                        }
                        DOUBLE.toByte() -> {
                            readAlignment(buffer, 8)
                            contentValues.put(key, buffer.double)
                        }
                        TRUE.toByte() -> {
                            contentValues.put(key, true)
                        }
                        FALSE.toByte() -> {
                            contentValues.put(key, false)
                        }
                        BYTE_ARRAY.toByte() -> {
                            contentValues.put(key, readBytes(buffer))
                        }
                        NULL.toByte() -> {
                            contentValues.putNull(key)
                        }
                        else -> {
                            throw IllegalArgumentException("Wrong value in ContentValues")
                        }
                    }
                }
                return contentValues
            }
            else -> {
                return super.readValueOfType(type, buffer)
            }
        }
    }
}