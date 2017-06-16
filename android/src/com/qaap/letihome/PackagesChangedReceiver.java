package com.qaap.letihome;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class PackagesChangedReceiver extends BroadcastReceiver
{
    @Override
    public void onReceive(final Context context, Intent intent) {
        onPackagesChanged();
    }

    // notify our Qt app using JNI that packages have changed
    private static native void onPackagesChanged();
}
