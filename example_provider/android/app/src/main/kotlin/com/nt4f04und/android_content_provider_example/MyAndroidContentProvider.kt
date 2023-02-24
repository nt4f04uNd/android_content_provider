package com.nt4f04und.android_content_provider_example

import com.nt4f04und.android_content_provider.AndroidContentProvider

class MyAndroidContentProvider : AndroidContentProvider() {
   override val authority: String = "com.nt4f04und.android_content_provider_example.MyAndroidContentProvider"
   override val entrypointName = "exampleContentProviderEntrypoint"
}
