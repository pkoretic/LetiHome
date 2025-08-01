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
import android.database.Cursor;
import android.util.Base64;

import android.media.tv.TvInputManager;
import android.media.tv.TvInputInfo;
import android.content.Context;
import androidx.tvprovider.media.tv.TvContractCompat;
import androidx.tvprovider.media.tv.TvContractCompat.PreviewPrograms;
import androidx.tvprovider.media.tv.TvContractCompat.WatchNextPrograms;

import java.io.ByteArrayOutputStream;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

import org.qtproject.qt.android.bindings.QtActivity;
import org.json.JSONArray;
import org.json.JSONObject;

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

    private String encodeImageToBase64(Drawable drawable) {
        if (drawable == null) return "";
        Bitmap bitmap = Bitmap.createBitmap(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        drawable.draw(canvas);
        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP);
    }

    // Fetch and return "Watch Next" preview programs as a list of maps for Qt
    public String getNextPrograms() {
        JSONArray result = new JSONArray();
        Cursor watchNextCursor = null;
        try {
            watchNextCursor = getContentResolver().query(
                TvContractCompat.WatchNextPrograms.CONTENT_URI,
                null, null, null, null
            );
            if (watchNextCursor != null) {
                int titleIndex = watchNextCursor.getColumnIndex(TvContractCompat.WatchNextPrograms.COLUMN_TITLE);
                int packageIndex = watchNextCursor.getColumnIndex(TvContractCompat.WatchNextPrograms.COLUMN_PACKAGE_NAME);
                int positionIndex = watchNextCursor.getColumnIndex(TvContractCompat.WatchNextPrograms.COLUMN_LAST_PLAYBACK_POSITION_MILLIS);
                int durationIndex = watchNextCursor.getColumnIndex(TvContractCompat.WatchNextPrograms.COLUMN_DURATION_MILLIS);
                int intentUriIndex = watchNextCursor.getColumnIndex(TvContractCompat.WatchNextPrograms.COLUMN_INTENT_URI);
                int posterIndex = watchNextCursor.getColumnIndex(TvContractCompat.WatchNextPrograms.COLUMN_POSTER_ART_URI);
                int thumbnailIndex = watchNextCursor.getColumnIndex(TvContractCompat.WatchNextPrograms.COLUMN_THUMBNAIL_URI);
                while (watchNextCursor.moveToNext()) {
                    JSONObject entry = new JSONObject();
                    entry.put("title", titleIndex != -1 ? watchNextCursor.getString(titleIndex) : "");
                    entry.put("packageName", packageIndex != -1 ? watchNextCursor.getString(packageIndex) : "");
                    entry.put("position", positionIndex != -1 ? watchNextCursor.getLong(positionIndex) / 1000 : -1);
                    entry.put("duration", durationIndex != -1 ? watchNextCursor.getLong(durationIndex) / 1000 : -1);
                    entry.put("intentUri", intentUriIndex != -1 ? watchNextCursor.getString(intentUriIndex) : "");
                    String posterUri = posterIndex != -1 ? watchNextCursor.getString(posterIndex) : "";
                    Drawable posterDrawable = null;
                    if (!posterUri.isEmpty()) {
                        try {
                            posterDrawable = Drawable.createFromStream(getContentResolver().openInputStream(Uri.parse(posterUri)), null);
                        } catch (Exception e) {
                            Log.w("LetiHomePlus", "Failed to load poster image", e);
                        }
                    }
                    if (posterDrawable == null) {
                        String thumbnailUri = thumbnailIndex != -1 ? watchNextCursor.getString(thumbnailIndex) : "";
                        if (thumbnailUri != null && !thumbnailUri.isEmpty()) {
                            try {
                                posterDrawable = Drawable.createFromStream(getContentResolver().openInputStream(Uri.parse(thumbnailUri)), null);
                            } catch (Exception e) {
                                Log.w("LetiHomePlus", "Failed to load thumbnail image", e);
                            }
                        }
                    }
                    if (posterDrawable == null) {
                        String packageName = packageIndex != -1 ? watchNextCursor.getString(packageIndex) : "";
                        if (!packageName.isEmpty()) {
                            try {
                                posterDrawable = packageManager.getApplicationIcon(packageName);
                            } catch (Exception e) {
                                Log.w("LetiHomePlus", "Failed to load application icon", e);
                            }
                        }
                    }
                    if (posterDrawable == null) {
                        posterDrawable = getDefaultApplicationIcon();
                    }
                    entry.put("posterImage", encodeImageToBase64(posterDrawable));
                    result.put(entry);
                }
            }
        } catch (Exception e) {
            Log.e("LetiHomePlus", "Error querying Watch Next", e);
        } finally {
            if (watchNextCursor != null) watchNextCursor.close();
        }
        return result.toString();
    }

    // Launch an app with the content from Watch Next using intentUri
    public void launchWatchNextContent(String intentUri) {
        if (intentUri == null || intentUri.isEmpty()) {
            Log.w("LetiHomePlus", "No intentUri provided to launchWatchNextContent");
            return;
        }
        try {
            Intent intent = Intent.parseUri(intentUri, 0);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
            Log.d("LetiHomePlus", "Launched content with intentUri: " + intentUri);
        } catch (Exception e) {
            Log.e("LetiHomePlus", "Failed to launch content with intentUri: " + intentUri, e);
        }
    }
}
