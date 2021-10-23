// Autogenerated from Pigeon (v1.0.7), do not edit directly.
// See also: https://pub.dev/packages/pigeon

package com.nt4f04und.android_content_provider;

import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.StandardMessageCodec;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

/** Generated class from Pigeon. */
@SuppressWarnings({"unused", "unchecked", "CodeBlock2Expr", "RedundantSuppression"})
public class ContentResolverMessages {

  /** Generated class from Pigeon that represents data sent in messages. */
  public static class CreateMessage {
    private String authority;
    public String getAuthority() { return authority; }
    public void setAuthority(String setterArg) { this.authority = setterArg; }

    Map<String, Object> toMap() {
      Map<String, Object> toMapResult = new HashMap<>();
      toMapResult.put("authority", authority);
      return toMapResult;
    }
    static CreateMessage fromMap(Map<String, Object> map) {
      CreateMessage fromMapResult = new CreateMessage();
      Object authority = map.get("authority");
      fromMapResult.authority = (String)authority;
      return fromMapResult;
    }
  }

  /** Generated class from Pigeon that represents data sent in messages. */
  public static class GetTypeMessage {
    private String authority;
    public String getAuthority() { return authority; }
    public void setAuthority(String setterArg) { this.authority = setterArg; }

    private String uri;
    public String getUri() { return uri; }
    public void setUri(String setterArg) { this.uri = setterArg; }

    Map<String, Object> toMap() {
      Map<String, Object> toMapResult = new HashMap<>();
      toMapResult.put("authority", authority);
      toMapResult.put("uri", uri);
      return toMapResult;
    }
    static GetTypeMessage fromMap(Map<String, Object> map) {
      GetTypeMessage fromMapResult = new GetTypeMessage();
      Object authority = map.get("authority");
      fromMapResult.authority = (String)authority;
      Object uri = map.get("uri");
      fromMapResult.uri = (String)uri;
      return fromMapResult;
    }
  }
  private static class ContentResolverApiCodec extends StandardMessageCodec {
    public static final ContentResolverApiCodec INSTANCE = new ContentResolverApiCodec();
    private ContentResolverApiCodec() {}
    @Override
    protected Object readValueOfType(byte type, ByteBuffer buffer) {
      switch (type) {
        case (byte)128:         
          return CreateMessage.fromMap((Map<String, Object>) readValue(buffer));
        
        case (byte)129:         
          return GetTypeMessage.fromMap((Map<String, Object>) readValue(buffer));
        
        default:        
          return super.readValueOfType(type, buffer);
        
      }
    }
    @Override
    protected void writeValue(ByteArrayOutputStream stream, Object value)     {
      if (value instanceof CreateMessage) {
        stream.write(128);
        writeValue(stream, ((CreateMessage) value).toMap());
      } else 
      if (value instanceof GetTypeMessage) {
        stream.write(129);
        writeValue(stream, ((GetTypeMessage) value).toMap());
      } else 
{
        super.writeValue(stream, value);
      }
    }
  }

  /** Generated interface from Pigeon that represents a handler of messages from Flutter.*/
  public interface ContentResolverApi {
    void create(CreateMessage message);
    String getType(GetTypeMessage message);

    /** The codec used by ContentResolverApi. */
    static MessageCodec<Object> getCodec() {
      return ContentResolverApiCodec.INSTANCE;
    }

    /** Sets up an instance of `ContentResolverApi` to handle messages through the `binaryMessenger`. */
    static void setup(BinaryMessenger binaryMessenger, ContentResolverApi api) {
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.ContentResolverApi.create", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              CreateMessage messageArg = (CreateMessage)args.get(0);
              if (messageArg == null) {
                throw new NullPointerException("messageArg unexpectedly null.");
              }
              api.create(messageArg);
              wrapped.put("result", null);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.ContentResolverApi.getType", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              GetTypeMessage messageArg = (GetTypeMessage)args.get(0);
              if (messageArg == null) {
                throw new NullPointerException("messageArg unexpectedly null.");
              }
              String output = api.getType(messageArg);
              wrapped.put("result", output);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
    }
  }
  private static Map<String, Object> wrapError(Throwable exception) {
    Map<String, Object> errorMap = new HashMap<>();
    errorMap.put("message", exception.toString());
    errorMap.put("code", exception.getClass().getSimpleName());
    errorMap.put("details", null);
    return errorMap;
  }
}
