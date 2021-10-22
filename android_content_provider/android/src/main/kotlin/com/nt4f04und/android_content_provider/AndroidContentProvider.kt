package com.nt4f04und.android_content_provider

import android.content.ContentProvider
import android.content.ContentProviderOperation
import android.content.ContentProviderResult
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import java.util.ArrayList

abstract class AndroidContentProvider : ContentProvider(), LifecycleOwner {
    private lateinit var lifecycle: LifecycleRegistry
    private lateinit var api: ContentProviderMessages.ContentProviderApi
    private lateinit var engine: FlutterEngine
    private lateinit var flutterLoader: FlutterLoader

    /** Should return this [ContentProvider]'s authority, which
     * should also match the one it's declared with in manifest
     */
    abstract fun getAuthority(): String

    /** Provides a [FlutterEngineGroup] to create a [FlutterEngine] this
     * [ContentProvider] will connect to
     *
     * This is a preferred way of setting up an engine, because it drastically
     * [improves performance and memory footprint](https://flutter.dev/docs/development/add-to-app/multiple-flutters).
     *
     * If returns null [provideFlutterEngine] will be called.
     */
    fun provideFlutterEngineGroup(): FlutterEngineGroup? {
        return null
    }

    /** Provides a [FlutterEngine] this [ContentProvider] will connect to.
     *
     * This method is called after [provideFlutterEngineGroup], which
     * is a preferred way of setting up an engine, because it drastically
     * [improves performance and memory footprint](https://flutter.dev/docs/development/add-to-app/multiple-flutters).
     *
     * If both this method and [provideFlutterEngineGroup] return null, the content provider
     * will create its own engine.
     */
    fun provideFlutterEngine(): FlutterEngine? {
        return null
    }

    override fun getLifecycle(): Lifecycle {
        return lifecycle
    }

    override fun onCreate(): Boolean {
        val engineGroup = provideFlutterEngineGroup()
        flutterLoader = FlutterLoader()
        flutterLoader.startInitialization(context!!)
        val entrypoint = DartExecutor.DartEntrypoint(
                flutterLoader.findAppBundlePath(),
                "androidContentProviderEntrypoint")
        if (engineGroup != null) {
            engineGroup.createAndRunEngine(context!!, entrypoint)
        } else {
            engine = provideFlutterEngine() ?: FlutterEngine(context!!)
            engine.dartExecutor.executeDartEntrypoint(entrypoint)
        }
        lifecycle = LifecycleRegistry(this)
        lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_CREATE)
        engine.contentProviderControlSurface.attachToContentProvider(this, lifecycle)
        api = ContentProviderMessages.ContentProviderApi(engine.dartExecutor.binaryMessenger)
        val createMessage = ContentProviderMessages.CreateMessage()
        createMessage.authority = getAuthority()
        api.create(createMessage) { }
        return true
    }

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? {
        return null
    }

    override fun getType(uri: Uri): String? {
        return null
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? {
        return null
    }

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int {
        return 0
    }

    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int {
        return 0
    }
}
