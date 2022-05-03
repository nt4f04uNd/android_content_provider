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
