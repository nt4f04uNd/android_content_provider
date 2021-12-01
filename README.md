# android_content_provider

android_content_provider exposes ContentProvider and related ContentResolver APIs on Android

## Configuring `AndroidContentProvider`

You may ignore these steps if you only want to use `AndroidContentResolver`.

1. Use the `FlutterEngineGroup`, provided by the plugin, in your `MainActivity`
   to improve performance and reduce memory footprint from engine creation.

   This step is optional, but is strongly recommended.

* Kotlin

```kotlin
import android.content.Context
import com.nt4f04und.android_content_provider.AndroidContentProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AndroidContentProvider.getFlutterEngineGroup(this)
                .createAndRunDefaultEngine(this)
    }
}
```

* Java

```java
import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.nt4f04und.android_content_provider.AndroidContentProvider;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
    @Nullable
    @Override
    public FlutterEngine provideFlutterEngine(@NonNull Context context) {
        return AndroidContentProvider.Companion.getFlutterEngineGroup(this)
                .createAndRunDefaultEngine(this);
    }
}
```

2. Subclass `AndroidContentProvider` in native code, setting the authority you want to use

* Kotlin

```kotlin
import com.nt4f04und.android_content_provider.AndroidContentProvider

class MyAndroidContentProvider : AndroidContentProvider() {
   override val authority: String = "com.example.myapp.MyAndroidContentProvider"
   override val entrypointName = "exampleContentProviderEntrypoint"
}
```

* Java

```java
import com.nt4f04und.android_content_provider.AndroidContentProvider;

import org.jetbrains.annotations.NotNull;

public class MyAndroidContentProvider extends AndroidContentProvider {
    @NotNull
    @Override
    public String getAuthority() {
        return "com.example.myapp.MyAndroidContentProvider";
    }

    @NotNull
    @Override
    public String getEntrypointName() {
        return "exampleContentProviderEntrypoint";
    }
}
```

3. Declare your ContentProvider in the `AndroidManifest.xml`.

* If you want to allow other apps to access the provider unconditionally

```xml
<provider
   android:name=".MyAndroidContentProvider"
   android:authorities="com.example.myapp.MyAndroidContentProvider"
   android:exported="true" />
```

* If you want to make other apps declare `<uses-permission>`

```xml
<provider
   android:name=".MyAndroidContentProvider"
   android:authorities="com.example.myapp.MyAndroidContentProvider"
   android:exported="false"
   android:readPermission="com.example.myapp.permission.READ"
   android:writePermission="com.example.myapp.permission.WRITE" />
```

4. Sublcass `AndroidContentProvider` in Dart code and override needed methods

```dart
import 'package:android_content_provider/android_content_provider.dart';

class MyAndroidContentProvider extends AndroidContentProvider {
  MyAndroidContentProvider() : super('com.example.myapp.MyAndroidContentProvider');

  @override
  Future<int> delete(
    String uri,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    return 0;
  }

  @override
  Future<String?> getType(String uri) async {
    return null;
  }

  @override
  Future<String?> insert(String uri, ContentValues? values) async {
    return null;
  }

  @override
  Future<CursorData?> query(
    String uri,
    List<String>? projection,
    String? selection,
    List<String>? selectionArgs,
    String? sortOrder,
  ) async {
    return null;
  }

  @override
  Future<int> update(
    String uri,
    ContentValues? values,
    String? selection,
    List<String>? selectionArgs,
  ) async {
    return 0;
  }
}
```

5. Create the Dart entrypoint

```dart
@pragma('vm:entry-point')
void exampleContentProviderEntrypoint() async {
   MyAndroidContentProvider('com.example.myapp.MyAndroidContentProvider');
}
```