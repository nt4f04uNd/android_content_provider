package com.nt4f04und.android_content_provider;

import android.content.ContentValues;
import android.net.Uri;
import android.os.Bundle;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.StandardMessageCodec;
import kotlin.collections.ArraysKt;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

public final class AndroidContentProviderMessageCodec extends StandardMessageCodec {
    @NotNull
    public static final AndroidContentProviderMessageCodec INSTANCE = new AndroidContentProviderMessageCodec();
    public static final byte NULL = (byte) 0;
    public static final byte TRUE = (byte) 1;
    public static final byte FALSE = (byte) 2;
    public static final byte URI = (byte) 134;
    public static final byte BUNDLE = (byte) 133;
    public static final byte CONTENT_VALUES = (byte) 132;
    public static final byte BYTE = (byte) 128;
    public static final byte SHORT = (byte) 129;
    public static final byte INTEGER = (byte) 3;
    public static final byte LONG = (byte) 4;
    public static final byte FLOAT = (byte) 131;
    public static final byte DOUBLE = (byte) 6;
    public static final byte STRING = (byte) 7;
    public static final byte BYTE_ARRAY = (byte) 8;
    @SuppressWarnings("CharsetObjectCanBeUsed")
    private static final Charset UTF8 = Charset.forName("UTF8");

    @Override
    protected void writeValue(@NotNull ByteArrayOutputStream stream, @Nullable Object value) {
        if (value instanceof Uri) {
            stream.write(URI);
            writeBytes(stream, value.toString().getBytes(UTF8));
        } else if (value instanceof Bundle) {
            stream.write(BUNDLE);
            writeSize(stream, ((Bundle) value).size());
            for (String key : ((Bundle) value).keySet()) {
                writeValue(stream, key);
                writeValue(stream, ((Bundle) value).get(key));
            }
        } else if (value instanceof ContentValues) {
            stream.write(CONTENT_VALUES);
            writeSize(stream, ((ContentValues) value).size());
            for (String key : ((ContentValues) value).keySet()) {
                Object contentValuesValue = ((ContentValues) value).get(key);
                writeValue(stream, key);
                if (contentValuesValue == null) {
                    stream.write(NULL);
                } else if (contentValuesValue instanceof String) {
                    stream.write(STRING);
                    writeBytes(stream, ((String) contentValuesValue).getBytes(UTF8));
                } else if (contentValuesValue instanceof Byte) {
                    stream.write(BYTE);
                    writeInt(stream, ((Byte) contentValuesValue).intValue());
                } else if (contentValuesValue instanceof Short) {
                    stream.write(SHORT);
                    writeInt(stream, ((Short) contentValuesValue).intValue());
                } else if (contentValuesValue instanceof Integer) {
                    stream.write(INTEGER);
                    writeInt(stream, (Integer) contentValuesValue);
                } else if (contentValuesValue instanceof Long) {
                    stream.write(LONG);
                    writeLong(stream, (Long) contentValuesValue);
                } else if (contentValuesValue instanceof Float) {
                    stream.write(FLOAT);
                    writeAlignment(stream, 8);
                    writeDouble(stream, ((Float) contentValuesValue).doubleValue());
                } else if (contentValuesValue instanceof Double) {
                    stream.write(DOUBLE);
                    writeAlignment(stream, 8);
                    writeDouble(stream, (Double) contentValuesValue);
                } else if (contentValuesValue instanceof Boolean) {
                    if ((Boolean) contentValuesValue) {
                        stream.write(TRUE);
                    } else {
                        stream.write(FALSE);
                    }
                } else if (contentValuesValue instanceof byte[]) {
                    stream.write(BYTE_ARRAY);
                    writeBytes(stream, (byte[]) contentValuesValue);
                } else {
                    throw new IllegalArgumentException("Wrong value in ContentValues");
                }
            }
        } else {
            try {
                // allow write standard writeValue to do its work,
                // including the conversion of int[], long[], etc.

                // The annotation is wrong here https://github.com/flutter/flutter/issues/101991
                //noinspection ConstantConditions
                super.writeValue(stream, value);
            } catch (IllegalArgumentException e) {
                if (value instanceof Object[]) {
                    // convert array unsupported in standard writeValue to list
                    writeValue(stream, ArraysKt.toList((Object[]) value));
                } else {
                    // otherwise rethrow
                    throw e;
                }
            }
        }
    }

    @Override
    @Nullable
    protected Object readValueOfType(byte type, @NonNull ByteBuffer buffer) {
        if (type == URI) {
            throw new IllegalArgumentException("Uri byte should not be sent to native, use regular String instead");
        } else if (type == BUNDLE) {
            throw new IllegalArgumentException("Bundle byte should not be sent to native, use regular map instead");
        } else if (type == CONTENT_VALUES) {
            int size = readSize(buffer);
            ContentValues contentValues = new ContentValues(size);
            for (int i = 0; i < size; i++) {
                final String key = (String) readValue(buffer);
                // taken from readValue
                if (!buffer.hasRemaining()) {
                    throw new IllegalArgumentException("Message corrupted");
                }
                byte value = buffer.get();
                if (value == NULL) {
                    contentValues.putNull(key);
                } else if (value == STRING) {
                    byte[] bytes = readBytes(buffer);
                    contentValues.put(key, new String(bytes, UTF8));
                } else if (value == BYTE) {
                    contentValues.put(key, (byte) buffer.getInt());
                } else if (value == SHORT) {
                    contentValues.put(key, (short) buffer.getInt());
                } else if (value == INTEGER) {
                    contentValues.put(key, buffer.getInt());
                } else if (value == LONG) {
                    contentValues.put(key, buffer.getLong());
                } else if (value == FLOAT) {
                    readAlignment(buffer, 8);
                    contentValues.put(key, (float) buffer.getDouble());
                } else if (value == DOUBLE) {
                    readAlignment(buffer, 8);
                    contentValues.put(key, buffer.getDouble());
                } else if (value == TRUE) {
                    contentValues.put(key, true);
                } else if (value == FALSE) {
                    contentValues.put(key, false);
                } else if (value == BYTE_ARRAY) {
                    contentValues.put(key, readBytes(buffer));
                } else {
                    throw new IllegalArgumentException("Wrong value in ContentValues");
                }
            }
            return contentValues;
        } else {
            return super.readValueOfType(type, buffer);
        }
    }
}
