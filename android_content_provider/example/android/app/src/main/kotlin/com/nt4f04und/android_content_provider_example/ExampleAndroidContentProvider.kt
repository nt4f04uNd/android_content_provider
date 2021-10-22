package com.nt4f04und.android_content_provider_example

import com.nt4f04und.android_content_provider.AndroidContentProvider

class ExampleAndroidContentProvider : AndroidContentProvider() {
    companion object {
        const val AUTHORITY : String = "com.nt4f04und.android_content_provider_example.ExampleAndroidContentProvider"
    }

    override fun getAuthority(): String {
        return AUTHORITY
    }
}