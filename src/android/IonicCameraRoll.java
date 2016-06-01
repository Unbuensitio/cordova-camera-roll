package com.drifty.cordova.cameraroll;

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
    private DateFormat formatter;

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        this.callbackContext = callbackContext;

		if (action.equals(ACTION_GET_PHOTOS)) {
		    getPhotos();
            return true;
        } else if (action.equals(ACTION_SAVE)) {
            // Not implemented yet
        }
        return false;
    }

    private void getPhotos() throws JSONException {
        Uri uri;
        ArrayList<String> listOfAllImages = new ArrayList<String>();
        Cursor cursor;
        int column_index_data, column_index_folder_name;
        String pathOfImage = null;
        long dateOfImage = 0;
        uri = android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

        String[] projection = { MediaStore.MediaColumns.DATA,
                MediaStore.Images.Media.BUCKET_DISPLAY_NAME };

        cursor = this.cordova.getActivity().getContentResolver().query(uri, projection, null,
                null, null);

        column_index_data = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA);

        formatter = new SimpleDateFormat("yyyy:MM:dd HH:mm:ss");

        while (cursor.moveToNext()) {
            pathOfImage = cursor.getString(column_index_data);
            dateOfImage = dateFromImagePath(pathOfImage);

            JSONObject json = new JSONObject();
            json.put("path", pathOfImage);
            json.put("date", dateOfImage);

            PluginResult r = new PluginResult(PluginResult.Status.OK, json);
            r.setKeepCallback(true);
            this.callbackContext.sendPluginResult(r);
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

        if(intf != null) {
            String date = intf.getAttribute(ExifInterface.TAG_DATETIME);
            try {
                return formatter.parse(date).getTime();
            } catch (ParseException e) {
                e.printStackTrace();
            }

        }

        return 0;
    }
}