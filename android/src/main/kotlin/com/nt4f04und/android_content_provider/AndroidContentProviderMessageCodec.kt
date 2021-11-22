package com.nt4f04und.android_content_provider

import android.content.ContentValues
import android.net.Uri
import android.os.Bundle
import io.flutter.plugin.common.StandardMessageCodec
import java.io.ByteArrayOutputStream
import java.lang.reflect.Field
import java.nio.ByteBuffer
import java.util.*

/**
 * The codec utilized to encode data back and forth between
 * the Dart and the native platform.
 *
 * See Dart's `AndroidContentProviderMessageCodec` for more details.
 */
class AndroidContentProviderMessageCodec : StandardMessageCodec() {
    companion object {
        val INSTANCE: AndroidContentProviderMessageCodec = AndroidContentProviderMessageCodec()

        internal const val URI = 134
        internal const val BUNDLE = 133
        internal const val CONTENT_VALUES = 132
        internal const val BYTE = 128
        internal const val SHORT = 129
        internal const val INTEGER = 3
        internal const val LONG = 4
        internal const val FLOAT = 131
        internal const val DOUBLE = 6
    }

    private fun getContentValuesMapField(values: ContentValues): Field {
        val mapField = try {
            values::class.java.getDeclaredField("mMap")
        } catch (ex: NoSuchFieldException) {
            values::class.java.getDeclaredField("mValues")
        }
        mapField.isAccessible = true
        return mapField
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
                val map = getContentValuesMapField(value).get(value) as Map<String, Any?>
                map.forEach { (key, value) ->
                    writeValue(stream, key);
                    when (value) {
                        is Byte -> {
                            stream.write(BYTE)
                            writeInt(stream, value.toInt())
                        }
                        is Short -> {
                            stream.write(SHORT)
                            writeInt(stream, value.toInt())
                        }
                        is Int -> {
                            stream.write(INTEGER)
                            writeInt(stream, value.toInt())
                        }
                        is Long -> {
                            stream.write(LONG)
                            writeLong(stream, value.toLong())
                        }
                        is Float -> {
                            stream.write(FLOAT);
                            writeAlignment(stream, 8);
                            writeDouble(stream, value.toDouble());
                        }
                        is Double -> {
                            stream.write(DOUBLE);
                            writeAlignment(stream, 8);
                            writeDouble(stream, value.toDouble());
                        }
                        else -> {
                            writeValue(stream, value)
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
                val map: MutableMap<Any, Any> = HashMap()
                for (i in 0 until size) {
                    map[readValue(buffer)] = readValue(buffer)
                }
                val values = ContentValues::class.java.newInstance()
                getContentValuesMapField(values).set(values, map)
                return values
            }
            BYTE.toByte() -> {
                return buffer!!.int.toShort().toByte()
            }
            SHORT.toByte()  -> {
                return buffer!!.int.toShort()
            }
            INTEGER.toByte() -> {
                return buffer!!.int
            }
            LONG.toByte() -> {
                return buffer!!.long
            }
            FLOAT.toByte()  -> {
                readAlignment(buffer, 8)
                return buffer!!.double.toFloat()
            }
            DOUBLE.toByte() -> {
                readAlignment(buffer, 8)
                return buffer!!.double
            }
            else -> {
                return super.readValueOfType(type, buffer)
            }
        }
    }
}