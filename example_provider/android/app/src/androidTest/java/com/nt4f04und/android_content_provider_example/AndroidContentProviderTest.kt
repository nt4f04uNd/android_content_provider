package com.nt4f04und.android_content_provider_example

import android.net.Uri
import android.os.Build
import android.os.ParcelFileDescriptor
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
//    val providerRule: ProviderTestRule = ProviderTestRule.Builder(
//            ExampleAndroidContentProvider::class.java,
//            ExampleAndroidContentProvider.AUTHORITY
//    ).build()

    @Test
    fun create_test() {
//        val type = providerRule.resolver.getType(Uri.parse("https://www.google.com/"));
//        Assert.assertEquals(type, "test")

//        val provider = ExampleAndroidContentProvider()
    }

// TODO add a test for this
//    for (element in listOf("r", "w", "wt", "wa", "rw", "rwt")) {
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
//            println("wow ${translateModeStringToPosix(element)} ${ParcelFileDescriptor.parseMode(element)}")
//        }
//    }
}
