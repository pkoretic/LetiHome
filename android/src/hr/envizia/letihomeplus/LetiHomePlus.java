package hr.envizia.letihomeplus;

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

import android.media.tv.TvInputManager;
import android.media.tv.TvInputInfo;
import android.content.Context;
import androidx.tvprovider.media.tv.TvContractCompat;

import java.io.ByteArrayOutputStream;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

import org.qtproject.qt.android.bindings.QtActivity;

public class LetiHomePlus extends QtActivity
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
            icon = packageManager.getApplicationIcon(packageName);
        }
        catch(Exception e)
        {
            // load generic application icon if we were unable to load requested
            Log.w("LetiHomePlus", "exception getApplicationIcon for " + packageName, e);
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

    // get application TV banner as byte array
    public byte[] getApplicationBanner(String packageName)
    {
        Drawable icon = null;

        try
        {
            icon = packageManager.getApplicationBanner(packageName);
        }
        catch(Exception e)
        {
            Log.w("LetiHomePlus", "exception getApplicationIcon for " + packageName, e);
        }

        // convert to byte array
        if (icon != null)
        {
            Bitmap bitmap = Bitmap.createBitmap(icon.getIntrinsicWidth(), icon.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
            final Canvas canvas = new Canvas(bitmap);
            icon.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
            icon.draw(canvas);
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100 /* ignored for PNG */, stream);
            return stream.toByteArray();
        }

        // return empty byte array if no banner available
        return new byte[0];
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

    // open network settings based on connection type
    // isEthernet: true = open ethernet/general settings, false = open wifi settings
    public void openNetworkSettings(boolean isEthernet)
    {
        try {
            if (isEthernet) {
                // No dedicated ethernet settings intent on Android; use general settings
                startActivity(new Intent(android.provider.Settings.ACTION_SETTINGS));
            } else {
                startActivity(new Intent(android.provider.Settings.ACTION_WIFI_SETTINGS));
            }
        } catch (Exception e) {
            Log.w("LetiHomePlus", "Network settings not available, opening general settings", e);
            openSettings();
        }
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
        intent.setData(Uri.parse("https://play.google.com/store/apps/details?id=hr.envizia.letihomeplus"));
        intent.setPackage("com.android.vending");
        startActivity(intent);
    }


    // method to return a list of TV inputs using TVInputManager <InputId, InputLabel>
    public Map<String, String> getTvInputs()
    {
        Map<String, String> inputs = new HashMap<>();
        TvInputManager tvInputManager = (TvInputManager) getSystemService(Context.TV_INPUT_SERVICE);

        if (tvInputManager != null) {
            List<TvInputInfo> inputList = tvInputManager.getTvInputList();

            Log.d("LetiHomePlus", "Found " + inputList.size() + " TV inputs");

            for (TvInputInfo input : inputList) {
                // Only include hardware passthrough inputs (e.g. HDMI, AV, etc)
                if (input.getType() == TvInputInfo.TYPE_HDMI ||
                    input.getType() == TvInputInfo.TYPE_COMPONENT ||
                    input.getType() == TvInputInfo.TYPE_COMPOSITE ||
                    input.getType() == TvInputInfo.TYPE_SVIDEO ||
                    input.getType() == TvInputInfo.TYPE_SCART ||
                    input.getType() == TvInputInfo.TYPE_VGA ||
                    input.getType() == TvInputInfo.TYPE_DISPLAY_PORT) {

                    String id = input.getId();
                    CharSequence label = input.loadLabel(this);
                    Log.d("LetiHomePlus", "Found TV input: id=" + id + ", label=" + label);
                    inputs.put(id, label != null ? label.toString() : id);
                }
            }
        }
        Log.d("LetiHomePlus", "Returning TV inputs: " + inputs.toString());
        return inputs;
    }

    // method to set the chosen TV input using TvContractCompat.buildChannelUriForPassthroughInput
    public void setInput(String inputId)
    {
        Log.d("LetiHomePlus", "Setting TV input: " + inputId);
        if (inputId == null) return;
        Uri uri = TvContractCompat.buildChannelUriForPassthroughInput(inputId);
        Intent intent = new Intent(Intent.ACTION_VIEW, uri);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }
}
