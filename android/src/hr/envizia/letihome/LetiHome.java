package hr.envizia.letihome;

import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.drawable.Drawable;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.text.format.DateFormat;
import android.util.Log;
import android.os.Bundle;
import android.net.Uri;

import java.io.ByteArrayOutputStream;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

import org.qtproject.qt.android.bindings.QtActivity;

public class LetiHome extends QtActivity
{
    private PackageManager packageManager;

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        packageManager = getPackageManager();

        // Register the intent receiver
        PackagesChangedReceiver.register(this);
    }

    // get applications as Map<packageName, applicationName>
    public Map<String, String> applicationList()
    {
        Map<String, String> applications = new HashMap<String, String>();

        // we could be running on Android TV or non TV OS so for backward compatibility we need to show both
        Intent i = new Intent(Intent.ACTION_MAIN, null);

        i.addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER);

        List<ResolveInfo> availableActivities = packageManager.queryIntentActivities(i, 0);
        for(ResolveInfo ri:availableActivities)
        {
            String applicationName = ri.loadLabel(packageManager).toString();
            String packageName = ri.activityInfo.packageName;

            applications.put(packageName, applicationName);
        }

        i = new Intent(Intent.ACTION_MAIN, null);
        i.addCategory(Intent.CATEGORY_LAUNCHER); // regular non TV OS apps

        availableActivities = packageManager.queryIntentActivities(i, 0);
        for(ResolveInfo ri:availableActivities)
        {
            String applicationName = ri.loadLabel(packageManager).toString();
            String packageName = ri.activityInfo.packageName;

            applications.put(packageName, applicationName);
        }

        return applications;
    }

    // get application icon as byte array
    public byte[] getApplicationIcon(String packageName)
    {
        Drawable icon = null;

        try
        {
            // try leanback/tv version first
            icon = packageManager.getApplicationBanner(packageName);

            if (icon == null)
                icon = packageManager.getApplicationIcon(packageName);
        }
        catch(Exception e)
        {
            // load generic application icon if we were unable to load requested
            Log.w("LetiHome", "exception getApplicationIcon for " + packageName, e);
            icon = getDefaultApplicationIcon();
        }

        // convert to byte array
        Bitmap bitmap = Bitmap.createBitmap(icon.getIntrinsicWidth(), icon.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
        final Canvas canvas = new Canvas(bitmap);
        icon.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        icon.draw(canvas);
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100 /* ignored for PNG */, stream);

        return stream.toByteArray();
    }

    // get generic application icon
    public Drawable getDefaultApplicationIcon()
    {
        return getResources().getDrawable(android.R.mipmap.sym_def_app_icon);
    }

    // open application by packageName | LeanBack = TV optimized app
    public void openApplication(String packageName)
    {
        Intent intent = packageManager.getLeanbackLaunchIntentForPackage(packageName);

        if (intent == null)
            intent = packageManager.getLaunchIntentForPackage(packageName);

        startActivity(intent);
    }

    // return if system clock is in 24 hour format
    public boolean is24HourFormat()
    {
        return DateFormat.is24HourFormat(this);
    }

    // https://developer.android.com/training/tv/get-started/hardware#runtime-check
    public boolean isTelevision()
    {
        return packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK);
    }

    // open system settings
    public void openSettings()
    {
        startActivity(new Intent(android.provider.Settings.ACTION_SETTINGS));
    }

    // open system application info dialog
    public void openAppInfo(String packageName)
    {
        Intent intent = new Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        intent.setData(android.net.Uri.fromParts("package", packageName, null));
        startActivity(intent);
    }

    // open playstore for letiplus
    public void openLetiHomePage()
    {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse("https://play.google.com/store/apps/details?id=hr.envizia.letihome"));
        intent.setPackage("com.android.vending");
        startActivity(intent);
    }

}
