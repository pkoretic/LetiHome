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

import java.io.ByteArrayOutputStream;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

public class LetiHome extends org.qtproject.qt5.android.bindings.QtActivity
{
    private PackageManager manager;

    // get applications as Map<packageName, applicationName>
    public Map<String, String> applicationList()
    {
        Map<String, String> applications = new HashMap<String, String>();
        manager = getPackageManager();

        Intent i = new Intent(Intent.ACTION_MAIN, null);
        i.addCategory(Intent.CATEGORY_LAUNCHER);

        List<ResolveInfo> availableActivities = manager.queryIntentActivities(i, 0);
        for(ResolveInfo ri:availableActivities)
        {
            String applicationName = ri.loadLabel(manager).toString();
            String packageName = ri.activityInfo.packageName;

            applications.put(packageName, applicationName);
        }

        return applications;
    }

    // get application icon as byte array
    public byte[] getApplicationIcon(String packageName)
    {
        Drawable icon;

        try
        {
            icon = manager.getApplicationIcon(packageName);
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
        icon.draw(canvas);        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100 /* ignored for PNG */, stream);
        byte[] iconData = stream.toByteArray();

        return iconData;
    }

    // get generic application icon
    public Drawable getDefaultApplicationIcon()
    {
        return getResources().getDrawable(android.R.mipmap.sym_def_app_icon);
    }

    // launch application
    public void launchApplication(String packageName)
    {
        Intent intent = manager.getLaunchIntentForPackage(packageName);
        startActivity(intent);
    }

    // open wallpaper picker
    public void pickWallpaper()
    {
        Intent intent = new Intent(Intent.ACTION_SET_WALLPAPER);
        startActivity(Intent.createChooser(intent, "Select Wallpaper"));
    }

    // return if system clock is in 24 hour format
    public boolean is24HourFormat()
    {
        return DateFormat.is24HourFormat(this);
    }
}
