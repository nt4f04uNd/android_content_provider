### 0.4.3

* Fixed compatibility with all Flutter versions (both below and above 3.24.0) via build script automation. Previous release was incompatible with Flutter versions below 3.24.0.

### 0.4.2

* Fix build issue with Flutter 3.24.0.

### 0.4.1

* Support uuid 4.0.0

### 0.4.0

* Use Gradle 8.x - you need to use Gradle 8.x, as well as Gradle wrapper 8.x and upgrade your kotlin-gradle-plugin to 1.9.10
* Fix a few warnings
* Bump up pubspecs in examples
* Fix formatting

## 0.3.0

* Fixed a signature of `ContentObserver.onChangeUris` to have nullable URIs list, instead of non-nullable, because it might receive such. This happens in cases where notification is received by a ContentObserver registered with `NativeCursor.registerContentObserver`.
* Fix broken compilation, which happened due to nullablity changes in Android SDK in `Icon.loadDrawable`.
* Add an explanatory hint logging for a case when `MatrixCursorData.notificationUris` contain invalid URIs. Added same explanation to docs of the parameter as well.
* Refactor example: separate `example` and `example_provider` to separately show how to work with AndroidContentProvider and AndroidContentResolver.
* Add a better, but simple, example of both provider and resolver - a collection of books.

## 0.2.2

* Exposed AndroidContentResolver.methodChannel for testing
* Made ContentObserver onChange and onChangeUris `flags` parameter non-nullable - it will always receive 0 when there are no flags

## 0.2.1

* Add AndroidContentProvider example and make README setup instructions more clear
* Avoid breaking changes in Android StandardMessageCodec Flutter 2.13.0 by converting AndroidContentProviderMessageCodec from Kotlin to Java

## 0.2.0

* Fixed CancellationSignal sometimes throw MissingPluginException on cancel
* Made method channels non-serial
* Fixed loadThumbnail return type
* Deleted autoCloseScope and Closeable, because it isn't possible to properly implement them in Dart - now you should manually close all cursors

## 0.1.0

* Fixed that NativeCursor "get" methods were throwing with null values

## 0.0.1

* Support ContentProvider and related ContentResolver APIs on Android
