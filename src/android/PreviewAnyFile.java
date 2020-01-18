package com.mostafa.previewanyfile;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.webkit.MimeTypeMap;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import java.net.URLEncoder;

import android.os.Build;
import java.lang.reflect.Method;
import android.os.StrictMode;

public class PreviewAnyFile extends CordovaPlugin {

  private CallbackContext callbackContext; // The callback context from which we were invoked.
  private Context context;

  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    this.callbackContext = callbackContext;
    // this.executeArgs = args;
    if (action.equals("preview")) {
      String url = args.getString(0);
      this.viewFile(url, callbackContext);
    }

    return true;
  }

  private void presentFile(Intent intent, Uri uri, String type) {
    intent.setDataAndType(uri, type);
    this.cordova.getActivity().startActivityForResult(intent, 1);
  }

  private void viewFile(String url, CallbackContext callbackContext) {

    if (Build.VERSION.SDK_INT >= 24) {
      try {
        Method m = StrictMode.class.getMethod("disableDeathOnFileUriExposure");
        m.invoke(null);
      } catch (Exception e) {
        e.printStackTrace();
      }
    }

    boolean file_presented = false;
    String error = null;

    Uri uri = Uri.parse(url);
    Intent intent = new Intent(Intent.ACTION_VIEW);
    String safeURl = url.toLowerCase();
    String extension = MimeTypeMap.getFileExtensionFromUrl(safeURl);
    if (extension == "") {
      extension = safeURl.substring(safeURl.lastIndexOf(".") + 1);
    }
    String mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
    if (mimeType == null) {
      try {
        presentFile(intent, uri, "application/*");
        file_presented = true;
      } catch (ActivityNotFoundException t) {
        error = t.getLocalizedMessage();
        file_presented = false;
      }
    } else {
      try {
        presentFile(intent, uri, mimeType);
        file_presented = true;
      } catch (ActivityNotFoundException e) {
        try {
          presentFile(intent, uri, "application/*");
          file_presented = true;
        } catch (ActivityNotFoundException t) {
          error = t.getLocalizedMessage();
          file_presented = false;
        }
      }
    }

    if (file_presented) {
      callbackContext.success("SUCCESS");
    } else {
      callbackContext.error(error);
    }
  }

}