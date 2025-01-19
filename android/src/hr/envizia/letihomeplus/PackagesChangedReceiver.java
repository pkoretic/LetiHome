package hr.envizia.letihomeplus;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
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
        String packageName = intent.getData() != null ? intent.getData().getSchemeSpecificPart() : null;
        String actionToSend, appName = "";

        PackageManager packageManager = context.getPackageManager();
         try
         {
             ApplicationInfo appInfo = packageManager.getApplicationInfo(packageName, 0);
             appName = packageManager.getApplicationLabel(appInfo).toString();
         }
         catch (PackageManager.NameNotFoundException e)
         {
             Log.d(TAG, "Package not found: " + packageName);
         }


        Log.d(TAG, "Received action: " + action + " for package: " + packageName + " " + appName);

        switch (action) {
            case "android.intent.action.PACKAGE_ADDED":
                actionToSend = "PACKAGE_ADDED"; // installed
                break;
            case "android.intent.action.PACKAGE_REMOVED":
                actionToSend = "PACKAGE_REMOVED"; // deleted
                break;
            case "android.intent.action.PACKAGE_CHANGED":
                actionToSend = "PACKAGE_CHANGED"; // enabled/disabled
                break;
            default:
                actionToSend = "UNKNOWN_ACTION"; // cannot happen
                break;
        }

        Log.d(TAG, "action to send: " + actionToSend);
        onPackagesChanged(actionToSend, packageName, appName);
    }

    // notify our Qt app using JNI that packages have changed
    private static native void onPackagesChanged(String action, String packageName, String appName);
}
