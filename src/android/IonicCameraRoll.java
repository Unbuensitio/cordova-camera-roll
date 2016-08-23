package com.drifty.cordova.cameraroll;

import java.io.File;
import java.io.IOException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;
import android.database.Cursor;
import android.provider.MediaStore;
import android.media.ExifInterface;
import android.net.Uri;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;

public class IonicCameraRoll extends CordovaPlugin {

	public final String ACTION_GET_PHOTOS = "getPhotos";

	public final String ACTION_SAVE = "saveToCameraRoll";

    private CallbackContext callbackContext;
    private DateFormat formatter = new SimpleDateFormat("yyyy:MM:dd HH:mm:ss");

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

		if (action.equals(ACTION_GET_PHOTOS)) {
		    getPhotos(args.getInt(0));
            return true;
        } else if (action.equals(ACTION_SAVE)) {
            // Not implemented yet
        }
        return false;
    }

    private void getPhotos(int maxPhotoCount) throws JSONException {
        int photoCount = 0;
        boolean hasLimit = maxPhotoCount > 0;

        Uri uri = android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
        String[] projection = { MediaStore.MediaColumns.DATA, MediaStore.Images.Media.BUCKET_DISPLAY_NAME };
        Cursor cursor = this.cordova.getActivity().getContentResolver().query(uri, projection, null,
                null, null);
        int column_index_data = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA);

        boolean hasImage = cursor.moveToLast();
        while (hasImage && (!hasLimit || photoCount < maxPhotoCount)) {
            String pathOfImage = cursor.getString(column_index_data);

            JSONObject json = new JSONObject();
            json.put("path", pathOfImage);
            json.put("date", dateFromImagePath(pathOfImage));
            photoCount++;

            PluginResult r = new PluginResult(PluginResult.Status.OK, json);
            r.setKeepCallback(true);
            this.callbackContext.sendPluginResult(r);

            hasImage = cursor.moveToPrevious();
        }

        // Send empty JSON to indicate the end of photostreaming
        PluginResult r = new PluginResult(PluginResult.Status.OK, new JSONObject());
        r.setKeepCallback(true);
        this.callbackContext.sendPluginResult(r);
    }

    private long dateFromImagePath(String path) {
        ExifInterface intf = null;
        try {
            intf = new ExifInterface(path);
        }
        catch(IOException e) {
            e.printStackTrace();
        }

        if (intf != null) {
            String date = intf.getAttribute(ExifInterface.TAG_DATETIME);
            if (date != null) {
                try {
                    return formatter.parse(date).getTime();
                } catch (ParseException e) {
                    e.printStackTrace();
                }
            } else {
                File file = new File(path);
                if (file.exists()) {
                    return file.lastModified();
                }
            }
        }

        return 0;
    }
}
