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

import android.content.Context;
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

    /**
     * Fetch both full sized images and thumbnails via a single query.
     * Returns all images not in the Camera Roll.
     */
    private void getPhotos(int maxPhotoCount) throws JSONException {
        int int_position = 0;
        Uri uri;
        Cursor cursor;
        int column_index_data, column_index_folder_name,column_id,thum;

        String absolutePathOfImage = null;
        uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;

        String[] projection = {MediaStore.MediaColumns.DATA, MediaStore.Video.Media.BUCKET_DISPLAY_NAME,MediaStore.Video.Media._ID,MediaStore.Video.Thumbnails.DATA};

        final String orderBy = MediaStore.Images.Media.DATE_TAKEN;
        cursor = getApplicationContext().getContentResolver().query(uri, projection, null, null, orderBy + " DESC");

        column_index_data = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA);
        column_index_folder_name = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_DISPLAY_NAME);
        column_id = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID);
        thum = cursor.getColumnIndexOrThrow(MediaStore.Video.Thumbnails.DATA);

        while (cursor.moveToNext()) {
            
            // Get the tiny thumbnail and the full image path
            String thumbnailImageID = cursor.getString(column_id);
            String thumbnailPath = cursor.getString(thum);
            String absolutePathOfImage = cursor.getString(column_index_data);

            // Create the result object
            JSONObject json = new JSONObject();
            json.put("path", absolutePathOfImage);
            json.put("thumbnailPath", thumbnailPath);

            PluginResult r = new PluginResult(PluginResult.Status.OK, json);
            r.setKeepCallback(true);
            this.callbackContext.sendPluginResult(r);
		
        }
        cursor.close();

        // Send empty JSON to indicate the end of photostreaming
        PluginResult r = new PluginResult(PluginResult.Status.OK, new JSONObject());
        r.setKeepCallback(true);
        this.callbackContext.sendPluginResult(r);
    }

    private static int getOrientation(String fullImagePath) {
        ExifInterface exif;
        try {
            exif = new ExifInterface(fullImagePath);
        } catch (IOException e) {
            return 0;
        }
        if (exif == null) return 0;

        int exifOrientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);

        if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_90) return 90;
        if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_180) return 180;
        if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_270) return 270;
        return 0;
    }

    /**
     * Get the path to the full image for a given thumbnail.
     */
    private static String uriToFullImage(Cursor thumbnailsCursor, Context context){
        String imageId = thumbnailsCursor.getString(thumbnailsCursor.getColumnIndex(MediaStore.Images.Thumbnails.IMAGE_ID));

        // Request image related to this thumbnail
        String[] filePathColumn = { MediaStore.Images.Media.DATA };
        Cursor imagesCursor = context.getContentResolver().query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, filePathColumn, MediaStore.Images.Media._ID + "=?", new String[]{imageId}, null);

        if (imagesCursor != null && imagesCursor.moveToFirst()) {
            int columnIndex = imagesCursor.getColumnIndex(filePathColumn[0]);
            String filePath = imagesCursor.getString(columnIndex);
            imagesCursor.close();
            return filePath;
        } else {
            imagesCursor.close();
            return "";
        }
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
