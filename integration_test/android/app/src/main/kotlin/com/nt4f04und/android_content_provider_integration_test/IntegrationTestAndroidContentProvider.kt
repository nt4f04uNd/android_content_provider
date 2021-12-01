package com.nt4f04und.android_content_provider_integration_test

import com.nt4f04und.android_content_provider.AndroidContentProvider

class IntegrationTestAndroidContentProvider : AndroidContentProvider() {
    override val authority: String = "com.nt4f04und.android_content_provider_integration_test.IntegrationTestAndroidContentProvider"
    override val entrypointName = "integrationTestContentProviderEntrypoint"
}