package com.drifty.cordova.cameraroll;

import android.net.Uri;
import java.util.ArrayList;
import android.database.Cursor;
import android.provider.MediaStore;

import org.json.JSONArray;
import org.json.JSONException;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;

public class IonicCameraRoll extends CordovaPlugin {

	public final String ACTION_GET_PHOTOS = "getPhotos";

	public final String ACTION_SAVE = "saveToCameraRoll";

    private CallbackContext callbackContext;

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
        String PathOfImage = null;
        uri = android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI;

        String[] projection = { MediaStore.MediaColumns.DATA,
                MediaStore.Images.Media.BUCKET_DISPLAY_NAME };

        cursor = this.cordova.getActivity().getContentResolver().query(uri, projection, null,
                null, null);

        column_index_data = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA);
        column_index_folder_name = cursor
                .getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
        while (cursor.moveToNext()) {
            PathOfImage = cursor.getString(column_index_data);

            PluginResult r = new PluginResult(PluginResult.Status.OK, PathOfImage);
            r.setKeepCallback(true);
            this.callbackContext.sendPluginResult(r);
        }

    }
}