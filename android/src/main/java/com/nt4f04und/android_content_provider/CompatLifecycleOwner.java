package com.nt4f04und.android_content_provider;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.LifecycleRegistry;

/**
 * This class provides backwards compatibility with pre `2.6.0` versions `androidx.lifecycle:lifecycle-common`.
 * </br>
 * In `2.6.0` the LifecycleOwner interface was re-written in Kotlin:
 * <a href="https://android-review.googlesource.com/c/platform/frameworks/support/+/2288556">Commit</a>,
 * <a href="https://developer.android.com/jetpack/androidx/releases/lifecycle#2.6.0-beta01">Changelog</a>
 */
class CompatLifecycleOwner implements LifecycleOwner {
    @Nullable
    private LifecycleRegistry lifecycleRegistry;

    @NonNull
    public LifecycleRegistry getLifecycleRegistry() {
        if (lifecycleRegistry == null) {
            lifecycleRegistry = new LifecycleRegistry(this);
        }
        return lifecycleRegistry;
    }

    @NonNull
    @Override
    public Lifecycle getLifecycle() {
        return getLifecycleRegistry();
    }
}
