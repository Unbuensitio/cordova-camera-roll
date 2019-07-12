package com.drifty.cordova.cameraroll;

import android.content.Context;
import android.media.MediaScannerConnection;
import android.os.Environment;
import android.os.SystemClock;
import android.provider.MediaStore;
import android.util.Base64;
import java.lang.reflect.Method;

import org.apache.cordova.CordovaInterface;

import java.io.FileOutputStream;
import java.net.URI;
import java.net.URL;
import java.net.URISyntaxException;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.TimeZone;

import java.io.File;
import java.io.IOException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Bitmap.CompressFormat;
import android.content.Context;
import android.database.Cursor;
import android.provider.MediaStore;
import android.media.ExifInterface;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;

import android.graphics.Canvas;
import android.graphics.LinearGradient;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PorterDuffXfermode;
import android.graphics.Shader;
import android.media.ThumbnailUtils;

import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.io.InputStream;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;

public class IonicCameraRoll extends CordovaPlugin {

	public final String ACTION_GET_PHOTOS = "getPhotos";
	public final String ACTION_GET_VIDEOS = "getVideos";
	public final String ACTION_GET_VIDEOTHUMBNAIL = "getVideoThumbnail";

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
        }else if (action.equals(ACTION_GET_VIDEOS)) {
            getVideos(args.getInt(0));
            return true;
        }else if(action.equals(ACTION_GET_VIDEOTHUMBNAIL)) {
	    getVideoThumbnail(args.getString(0));
	    return true;
	}
        return false;
    }

    /**
     * Fetch both full sized images and thumbnails via a single query.
     * Returns all images not in the Camera Roll.
     */
    private void getPhotos(int maxPhotoCount) throws JSONException {
        int photoCount = 0;
        boolean hasLimit = maxPhotoCount > 0;

        final String[] projection = { MediaStore.Images.Thumbnails.DATA, MediaStore.Images.Thumbnails.IMAGE_ID };

        Context context = this.cordova.getActivity();
        Cursor thumbnailsCursor = context.getContentResolver().query( MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI,
                projection, // Which columns to return
                null,       // Return all rows
                null,
                null);

        // Extract the proper column thumbnails
        int thumbnailColumnIndex = thumbnailsCursor.getColumnIndex(MediaStore.Images.Thumbnails.DATA);

        boolean hasImage = thumbnailsCursor.moveToLast();
        while (hasImage && (!hasLimit || photoCount < maxPhotoCount)) {
            // Get the tiny thumbnail and the full image path
            int thumbnailImageID = thumbnailsCursor.getInt(thumbnailColumnIndex);
            String thumbnailPath = thumbnailsCursor.getString(thumbnailImageID);
            String fullImagePath = uriToFullImage(thumbnailsCursor, context);

            // Create the result object
            JSONObject json = new JSONObject();
            json.put("path", fullImagePath);
            json.put("thumbnailPath", thumbnailPath);
            json.put("orientation", getOrientation(fullImagePath));
            json.put("date", dateFromImagePath(fullImagePath));

            PluginResult r = new PluginResult(PluginResult.Status.OK, json);
            r.setKeepCallback(true);
            this.callbackContext.sendPluginResult(r);

            photoCount++;
            hasImage = thumbnailsCursor.moveToPrevious();
        }
        thumbnailsCursor.close();

        // Send empty JSON to indicate the end of photostreaming
        PluginResult r = new PluginResult(PluginResult.Status.OK, new JSONObject());
        r.setKeepCallback(true);
        this.callbackContext.sendPluginResult(r);
    }
	
    private void getVideos(int maxPhotoCount) throws JSONException {
        int photoCount = 0;
        boolean hasLimit = maxPhotoCount > 0;
	int column_index_data, column_index_folder_name,column_id,thum;

        final String[] projection = { MediaStore.MediaColumns.DATA, MediaStore.Video.Thumbnails.DATA, MediaStore.Video.Media.BUCKET_DISPLAY_NAME, MediaStore.Video.Media._ID };

        Context context = this.cordova.getActivity();
        Cursor thumbnailsCursor = context.getContentResolver().query( MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                projection, // Which columns to return
                null,       // Return all rows
                null,
                null);
	    
	/*final String orderBy = MediaStore.Images.Media.DATE_TAKEN;
        Cursor thumbnailsCursor = getApplicationContext().getContentResolver().query(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, projection, null, null, orderBy + " DESC");
	*/
        // Extract the proper column thumbnails
        int thumbnailColumnIndex = thumbnailsCursor.getColumnIndex(MediaStore.Video.Thumbnails.DATA);
	column_index_data = thumbnailsCursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA);
	thum = thumbnailsCursor.getColumnIndexOrThrow(MediaStore.Video.Thumbnails.DATA);
	    
        boolean hasImage = thumbnailsCursor.moveToLast();
        while (hasImage && (!hasLimit || photoCount < maxPhotoCount)) {
            // Get the tiny thumbnail and the full image path
	    String absolutePathOfImage = thumbnailsCursor.getString(column_index_data);
            String fullImagePath = absolutePathOfImage;
	    Bitmap thumbnail = getVidioThumbnail(absolutePathOfImage);
	    String imagen = "data:image/jpeg;base64," + convert(thumbnail);

            // Create the result object
            JSONObject json = new JSONObject();
            json.put("path", fullImagePath);
	    json.put("imagen", imagen);

            PluginResult r = new PluginResult(PluginResult.Status.OK, json);
            r.setKeepCallback(true);
            this.callbackContext.sendPluginResult(r);

            photoCount++;
            hasImage = thumbnailsCursor.moveToPrevious();
        }
        thumbnailsCursor.close();

        // Send empty JSON to indicate the end of photostreaming
        PluginResult r = new PluginResult(PluginResult.Status.OK, new JSONObject());
        r.setKeepCallback(true);
        this.callbackContext.sendPluginResult(r);
    }

    private static Bitmap getVideoThumbnail(String path) throws JSONException {
	  Bitmap bitmap = null;
	    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
		bitmap = ThumbnailUtils.createVideoThumbnail(path, MediaStore.Images.Thumbnails.MINI_KIND);
		if (bitmap != null) {
		    String imagen = "data:image/jpeg;base64," + convert(bitmap);
		    JSONObject json = new JSONObject();
		    json.put("path", path);
		    json.put("imagen", imagen);
		    PluginResult r = new PluginResult(PluginResult.Status.OK, json);
		    r.setKeepCallback(true);
		    this.callbackContext.sendPluginResult(r);
		}
	    }
	    // MediaMetadataRetriever is available on API Level 8 but is hidden until API Level 10
	    Class<?> clazz = null;
	    Object instance = null;
	    try {
		clazz = Class.forName("android.media.MediaMetadataRetriever");
		instance = clazz.newInstance();
		final Method method = clazz.getMethod("setDataSource", String.class);
		method.invoke(instance, path);
		// The method name changes between API Level 9 and 10.
		if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.GINGERBREAD) {
		    bitmap = (Bitmap) clazz.getMethod("captureFrame").invoke(instance);
		    String imagen = "data:image/jpeg;base64," + convert(bitmap);
		    JSONObject json = new JSONObject();
		    json.put("path", path);
		    json.put("imagen", imagen);
		    PluginResult r = new PluginResult(PluginResult.Status.OK, json);
		    r.setKeepCallback(true);
		    this.callbackContext.sendPluginResult(r);
		} else {
		    final byte[] data = (byte[]) clazz.getMethod("getEmbeddedPicture").invoke(instance);
		    if (data != null) {
			bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);
			    String imagen = "data:image/jpeg;base64," + convert(bitmap);
			    JSONObject json = new JSONObject();
			    json.put("path", path);
			    json.put("imagen", imagen);
			    PluginResult r = new PluginResult(PluginResult.Status.OK, json);
			    r.setKeepCallback(true);
			    this.callbackContext.sendPluginResult(r);
		    }
		    if (bitmap == null) {
			bitmap = (Bitmap) clazz.getMethod("getFrameAtTime").invoke(instance);
			    String imagen = "data:image/jpeg;base64," + convert(bitmap);
			    JSONObject json = new JSONObject();
			    json.put("path", path);
			    json.put("imagen", imagen);
			    PluginResult r = new PluginResult(PluginResult.Status.OK, json);
			    r.setKeepCallback(true);
			    this.callbackContext.sendPluginResult(r);
		    }
		}
	    } catch (Exception e) {
		bitmap = null;
	    } finally {
		try {
		    if (instance != null) {
			clazz.getMethod("release").invoke(instance);
		    }
		} catch (final Exception ignored) {
		}
	    }

            // Send empty JSON to indicate the end of photostreaming
            PluginResult r = new PluginResult(PluginResult.Status.OK, new JSONObject());
            r.setKeepCallback(true);
            this.callbackContext.sendPluginResult(r);
    }
	
    public static Bitmap getVidioThumbnail(String path) {
	    Bitmap bitmap = null;
	    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.FROYO) {
		bitmap = ThumbnailUtils.createVideoThumbnail(path, MediaStore.Images.Thumbnails.MICRO_KIND);
		if (bitmap != null) {
		    return bitmap;
		}
	    }
	    // MediaMetadataRetriever is available on API Level 8 but is hidden until API Level 10
	    Class<?> clazz = null;
	    Object instance = null;
	    try {
		clazz = Class.forName("android.media.MediaMetadataRetriever");
		instance = clazz.newInstance();
		final Method method = clazz.getMethod("setDataSource", String.class);
		method.invoke(instance, path);
		// The method name changes between API Level 9 and 10.
		if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.GINGERBREAD) {
		    bitmap = (Bitmap) clazz.getMethod("captureFrame").invoke(instance);
		} else {
		    final byte[] data = (byte[]) clazz.getMethod("getEmbeddedPicture").invoke(instance);
		    if (data != null) {
			bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);
		    }
		    if (bitmap == null) {
			bitmap = (Bitmap) clazz.getMethod("getFrameAtTime").invoke(instance);
		    }
		}
	    } catch (Exception e) {
		bitmap = null;
	    } finally {
		try {
		    if (instance != null) {
			clazz.getMethod("release").invoke(instance);
		    }
		} catch (final Exception ignored) {
		}
	    }
	    return bitmap;
   }
   
   public static String convert(Bitmap bitmap)
   {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);

        return Base64.encodeToString(outputStream.toByteArray(), Base64.DEFAULT);
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
