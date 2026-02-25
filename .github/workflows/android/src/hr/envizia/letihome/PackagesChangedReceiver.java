package hr.envizia.letihome;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

public class PackagesChangedReceiver extends BroadcastReceiver
{
    private static final String TAG = "PackagesChangedReceiver";

    // Method to register the receiver
    public static void register(Context context) {

        PackagesChangedReceiver receiver = new PackagesChangedReceiver();
        IntentFilter filter = new IntentFilter();
        filter.addAction(Intent.ACTION_PACKAGE_ADDED);
        filter.addAction(Intent.ACTION_PACKAGE_REMOVED);
        filter.addAction(Intent.ACTION_PACKAGE_CHANGED); // in case app is disabled/enabled
        filter.addDataScheme("package"); // Essential to listen to package changes
        context.registerReceiver(receiver, filter);

        Log.d(TAG, "PackagesChangedReceiver registered");
    }

    @Override
    public void onReceive(final Context context, Intent intent) {
        String action = intent.getAction();
        Log.d(TAG, "Received action: " + action);
        onPackagesChanged();
    }

    // notify our Qt app using JNI that packages have changed
    private static native void onPackagesChanged();
}
