package com.nt4f04und.android_content_provider

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.annotation.CallSuper
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** A [ContentProvider] for [AndroidContentProviderPlugin].
 *
 * ### Lifecycle
 *
 * All [AndroidContentProvider]s must be created in dedicated Flutter engines,
 * which are only supposed to host content providers.
 *
 * That means But it's prohibited to use the engine that was created by some other source.
 * Trying to do that will lead to crash.
 *
 * However, multiple [AndroidContentProvider] are able to share one or multiple engines
 * between each other. To do this, override multiple [AndroidContentProvider]s [flutterEngineCacheId]
 * to have the same value.
 *
 * There reason for this goes as follows:
 *
 *     In Android, [ContentProvider]s can be created by the system on demand from background.
 *     That means that the provider can be created before the app starts and continue running after
 *     other app components are destroyed, if system thinks there's enough RAM, or there's other process
 *     for which this content provider is important.
 *
 *     Thus, if:
 *       - engine starts with UI isolate
 *       - a content provider connects and holds the engine and all the resources of the isolate
 *       - Activity is destroyed and app process goes to background
 *
 *     Then we end up in a situation where we have a lot of unnecessary memory claimed which will
 *     also likely lead to system killing the process.
 *
 */
abstract class AndroidContentProvider : ContentProvider(), LifecycleOwner, Utils {
    private lateinit var lifecycle: LifecycleRegistry
    private lateinit var engine: FlutterEngine
    private lateinit var flutterLoader: FlutterLoader
    private lateinit var handler: Handler
    private var methodChannel: SynchronousMethodChannel? = null
    private val createdEngines: MutableSet<String> = mutableSetOf()

    companion object {
        private const val ENTRYPOINT_NAME = "androidContentProviderEntrypoint"
    }

    /** Should be set to this [ContentProvider]'s authority,
     * should also match the one it's declared with in manifest
     */
    abstract val authority: String

    /** If non-null, will use a [FlutterEngine] with the specified cache ID.
     * Will create it, if it's not created yet.
     *
     * This can be used to make several [AndroidContentProvider]s run on
     * the same engine.
     */
    @SuppressWarnings("WeakerAccess")
    protected val flutterEngineCacheId: String? = null

    /** Provides a [FlutterEngineGroup] to create a [FlutterEngine] this
     * [ContentProvider] will connect to
     *
     * This is a preferred way of setting up an engine, because it drastically
     * [improves performance and memory footprint](https://flutter.dev/docs/development/add-to-app/multiple-flutters).
     *
     * If returns null the content provider will create the engine without group.
     */
    @SuppressWarnings("WeakerAccess")
    protected fun provideFlutterEngineGroup(): FlutterEngineGroup? {
        return null
    }

    override fun getLifecycle(): Lifecycle {
        return lifecycle
    }

    @CallSuper
    override fun onCreate(): Boolean {
        var cachedEngine: FlutterEngine? = null
        flutterEngineCacheId?.let {
            cachedEngine = FlutterEngineCache.getInstance().get(it)
        }
        if (cachedEngine != null) {
            if (!createdEngines.contains(flutterEngineCacheId)) {
                throw IllegalStateException(
                        "The engine by specified 'flutterEngineCacheId' is not owned by AndroidContentProvider. " +
                                "See AndroidContentProvider doc comment for more info.")
            }
            engine = cachedEngine!!
        } else {
            flutterLoader = FlutterLoader()
            flutterLoader.startInitialization(context!!)
            val entrypoint = DartExecutor.DartEntrypoint(flutterLoader.findAppBundlePath(), ENTRYPOINT_NAME)
            val engineGroup = provideFlutterEngineGroup()
            if (engineGroup != null) {
                engine = engineGroup.createAndRunEngine(context!!, entrypoint)
            } else {
                engine = FlutterEngine(context!!)
                engine.dartExecutor.executeDartEntrypoint(entrypoint)
            }
            flutterEngineCacheId?.let {
                createdEngines.add(it)
                FlutterEngineCache.getInstance().put(it, engine)
            }
        }
        lifecycle = LifecycleRegistry(this)
        lifecycle.handleLifecycleEvent(Lifecycle.Event.ON_CREATE)
        engine.contentProviderControlSurface.attachToContentProvider(this, lifecycle)
        handler = Handler(Looper.getMainLooper())
        val plugin = engine.plugins.get(AndroidContentProviderPlugin::class.java) as AndroidContentProviderPlugin
        plugin.methodChannel!!.invokeMethod(
                "createContentProvider",
                mapOf("authority" to authority),
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        ensureMethodChannelInitialized()
                    }

                    override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {}
                    override fun notImplemented() {}
                })

        return true
    }

    private fun ensureMethodChannelInitialized() {
        if (methodChannel == null) {
            methodChannel = SynchronousMethodChannel(MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    "${AndroidContentProviderPlugin.channelPrefix}/ContentProvider/$authority",
                    AndroidContentProviderPlugin.pluginMethodCodec,
                    engine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue(
                            BinaryMessenger.TaskQueueOptions().setIsSerial(false))))
        }
    }

    @SuppressWarnings("WeakerAccess")
    protected fun invokeMethod(method: String, arguments: Any?): Any? {
        ensureMethodChannelInitialized()
        return methodChannel!!.invokeMethod(method, arguments)
    }

    override fun bulkInsert(uri: Uri, values: Array<out ContentValues>): Int {
        val result = invokeMethod("query", mapOf(
                "uri" to uri,
                "values" to values))
        return super.bulkInsert(uri, values)
    }

    @Suppress("UNCHECKED_CAST")
    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? {
        val result = asMap(invokeMethod("query", mapOf(
                "uri" to uri,
                "projection" to projection,
                "selection" to selection,
                "selectionArgs" to selectionArgs,
                "sortOrder" to sortOrder)))
                ?: return null
        val payload = asMap(result["payload"])!!
        val notificationUris = getUris(result["notificationUris"])
        val extras = mapToBundle(asMap(result["extras"]))

        val columnNames = listAsArray<String>(payload["columnNames"])
        val data = listAsArray<Any?>(payload["data"])
        val rowCount = payload["rowCount"] as Int

        val cursor = DataMatrixCursor(columnNames, data, rowCount)
        notificationUris?.let {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                cursor.setNotificationUris(context!!.contentResolver, it)
            } else {
                if (it.isEmpty()) {
                    cursor.setNotificationUri(context!!.contentResolver, null)
                } else {
                    cursor.setNotificationUri(context!!.contentResolver, it.first())
                }
            }
        }
        extras?.let {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                cursor.extras = it
            }
            // else silently no-op
        }
        return cursor
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
