package com.nt4f04und.android_content_provider_example

import android.net.Uri
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.internal.runner.junit4.statement.UiThreadStatement
import androidx.test.rule.provider.ProviderTestRule
import org.junit.Assert
import org.junit.Test
import org.junit.runner.RunWith

@LargeTest
@RunWith(AndroidJUnit4::class)
class AndroidContentProviderTest {
    val providerRule: ProviderTestRule = ProviderTestRule.Builder(
            ExampleAndroidContentProvider::class.java,
            ExampleAndroidContentProvider.AUTHORITY
    ).build()

    @Test
    fun create_test() {
        val type = providerRule.resolver.getType(Uri.parse("https://www.google.com/"));
        Assert.assertEquals(type, "test")

//        val provider = ExampleAndroidContentProvider()
    }
}
