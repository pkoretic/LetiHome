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
import android.util.Base64;

import java.io.ByteArrayOutputStream;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

import org.qtproject.qt.android.bindings.QtActivity;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

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
    public String applicationList()
    {
        JSONObject applications = new JSONObject();
        try {
            Intent i = new Intent(Intent.ACTION_MAIN, null);
            i.addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER);
            List<ResolveInfo> availableActivities = packageManager.queryIntentActivities(i, 0);
            for (ResolveInfo ri : availableActivities) {
                String applicationName = ri.loadLabel(packageManager).toString();
                String packageName = ri.activityInfo.packageName;
                String base64Icon = getApplicationIcon(packageName);
                JSONObject appObject = new JSONObject();
                appObject.put("applicationName", applicationName);
                appObject.put("applicationIcon", base64Icon);
                applications.put(packageName, appObject);
            }
            i = new Intent(Intent.ACTION_MAIN, null);
            i.addCategory(Intent.CATEGORY_LAUNCHER);
            availableActivities = packageManager.queryIntentActivities(i, 0);
            for (ResolveInfo ri : availableActivities) {
                String applicationName = ri.loadLabel(packageManager).toString();
                String packageName = ri.activityInfo.packageName;
                String base64Icon = getApplicationIcon(packageName);
                JSONObject appObject = new JSONObject();
                appObject.put("applicationName", applicationName);
                appObject.put("applicationIcon", base64Icon);
                applications.put(packageName, appObject);
            }
        } catch (JSONException e) {
            Log.e("LetiHome", "Error creating JSON", e);
        }
        return applications.toString();
    }

    // Optimized getApplicationIcon to streamline icon retrieval and base64 encoding, using the helper and reducing redundant code
    public String getApplicationIcon(String packageName) {
        Drawable icon = null;
        try {
            // Try to get the banner (TV/Leanback), then the regular icon
            icon = packageManager.getApplicationBanner(packageName);
            if (icon == null) {
                icon = packageManager.getApplicationIcon(packageName);
            }
        } catch (Exception e) {
            Log.w("LetiHome", "Exception in getApplicationIcon for " + packageName, e);
        }
        if (icon == null) {
            icon = getResources().getDrawable(android.R.mipmap.sym_def_app_icon); // generic application icon if none available from app itself
        }
        if (icon == null) {
            Log.e("LetiHome", "Failed to retrieve icon for package: " + packageName);
            return "";
        }
        try {
            String base64Icon = encodeImageToBase64(icon);
            return base64Icon;
        } catch (Exception e) {
            Log.e("LetiHome", "Failed to convert icon to Base64 for package: " + packageName, e);
            return "";
        }
    }

    // encode Drawable to Base64 Image string that can be used in QML Image source
    private String encodeImageToBase64(Drawable drawable) {
        if (drawable == null) return "";
        Bitmap bitmap = Bitmap.createBitmap(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        drawable.draw(canvas);
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100 /*Ignored for PNG */, stream);
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP);
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

    // open playstore for letihome
    public void openLetiHomePage()
    {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse("https://play.google.com/store/apps/details?id=hr.envizia.letihome"));
        intent.setPackage("com.android.vending");
        startActivity(intent);
    }

    // open playstore for letihomeplus
    public void openLetiHomePlusPage()
    {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse("https://play.google.com/store/apps/details?id=hr.envizia.letihomeplus"));
        intent.setPackage("com.android.vending");
        startActivity(intent);
    }
}
