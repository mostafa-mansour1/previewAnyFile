package com.mostafa.previewanyfile;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Environment;
import android.util.Base64;
import android.webkit.MimeTypeMap;

import androidx.core.content.FileProvider;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class PreviewAnyFile extends CordovaPlugin {

  private CallbackContext callbackContext; // The callback context from which we were invoked.
  private String mimeType = null;

  private static boolean notEmpty(String what) {
    return what != null && !"".equals(what) && !"null".equalsIgnoreCase(what);
  }

  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    this.callbackContext = callbackContext;
    cordova.setActivityResultCallback(this);
    // this.executeArgs = args;

    cordova.getThreadPool().execute(new Runnable() {
      @Override
      public void run() {
        try {

          switch (action) {
            case "preview":
              String url = args.getString(0);
              preview(url);
              break;
            case "previewPath":
              String path = args.getString(0);
              String namePreviewPath = args.getString(1);
              String PathMimetype = args.getString(2);
              previewPath(path, namePreviewPath, PathMimetype);
              break;
            case "previewBase64":
              String base64 = args.getString(0);
              String name = args.getString(1);
              String baseMimetype = args.getString(2);
              previewBase64(base64, name, baseMimetype);
              break;
            default:
              returnResult(Status.ERROR,
                  "Method " + action + " not Exist, only preview,previewPath and previewBase64 are allowed");
              break;

          }

        } catch (Exception e) {
          returnResult(Status.ERROR, e.getLocalizedMessage());
          e.printStackTrace();
        }

      }
    });

    returnResult(PluginResult.Status.NO_RESULT, null);
    return true;
  }

  private void preview(String url) throws URISyntaxException {
    this.mimeType = bathToMime(url);
    System.out.println("this.mimeType" + mimeType);
    System.out.println("this.url" + url);
    viewFile(pathToUri(url));
  }

  private void previewPath(String path, String name, String mediaType) throws URISyntaxException {
    if (notEmpty(mediaType))
      this.mimeType = mediaType;
    else
      this.mimeType = notEmpty(name) ? bathToMime(name) : bathToMime(path);
    viewFile(pathToUri(path));
  }

  private void previewBase64(String base64, String name, String mediaType) throws IOException, URISyntaxException {
    if (notEmpty(mediaType))
      this.mimeType = mediaType;
    String savedFile = base64ToPath(base64, name);
    if (notEmpty(savedFile))
      viewFile(pathToUri(savedFile));
  }

  private void viewFile(Uri uri) {
    try {

      if (!notEmpty(mimeType))
        mimeType = "application/*";
      Intent intent = new Intent(Intent.ACTION_VIEW);
      intent.setDataAndType(uri, mimeType);
      intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
      this.cordova.getActivity().startActivityForResult(intent, 1);
      this.returnResult(Status.OK, "SUCCESS");
    } catch (ActivityNotFoundException t) {
      if (t.getLocalizedMessage().toLowerCase().contains("no activity")
          && !mimeType.equalsIgnoreCase("application/*")) {
        mimeType = "application/*";
        viewFile(uri);
      } else {
        this.returnResult(Status.ERROR, t.getLocalizedMessage());
      }

    }
  }

  private Uri pathToUri(String url) throws URISyntaxException {

    Uri uri = null;
    if (url.startsWith("file:")) {
      File file = new File(new URI(url));
      uri = FileProvider.getUriForFile(this.cordova.getActivity(),
          this.cordova.getActivity().getApplicationContext().getPackageName() + ".fileprovider", file);

    } else {
      uri = Uri.parse(url);
    }
    return uri;
  }

  private String base64ToPath(String base64, String fileName) throws IOException {
    String dir = getDownloadDir();
    String localFile = null;
    String encodedBase64 = null;
    if (base64.startsWith("data:")) {
      // content is not a valid base64
      if (!base64.contains(";base64,")) {
        return null;
      }
      this.mimeType = base64ToMime(base64);
      // image looks like this: data:image/png;base64,R0lGODlhDAA...
      encodedBase64 = base64.substring(base64.indexOf(";base64,") + 8);

    } else {
      if (!notEmpty(this.mimeType))
        this.mimeType = bathToMime(fileName);
      encodedBase64 = base64;
    }
    if (!notEmpty(this.mimeType)) {
      returnResult(Status.ERROR, "You must specify either file name with extension or MimeType");
      return null;
    }
    if (!notEmpty(fileName)) {
      String ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType);
      fileName = System.currentTimeMillis() + "_file" + (notEmpty(ext) ? "." + ext : "");
    }
    System.out.println("fileName -> " + fileName);
    saveFile(Base64.decode(encodedBase64, Base64.DEFAULT), dir, fileName);
    localFile = "file://" + dir + "/" + fileName;
    File file = null;
    try {
      file = new File(new URI(localFile));
      if (file.exists() && !file.isDirectory())
        return localFile;
      else
        returnResult(Status.ERROR, "cannot write the base64 to a file");
    } catch (URISyntaxException e) {
      returnResult(Status.ERROR, e.getMessage());
    }
    return null;
  }

  private void saveFile(byte[] bytes, String dirName, String fileName) throws IOException {
    final File dir = new File(dirName);
    final FileOutputStream fos = new FileOutputStream(new File(dir, fileName));
    fos.write(bytes);
    fos.flush();
    fos.close();

  }

  private String base64ToMime(final String encoded) {
    final Pattern mime = Pattern.compile("^data:([a-zA-Z0-9]+/[a-zA-Z0-9]+).*,.*");
    final Matcher matcher = mime.matcher(encoded);
    if (matcher.find())
      mimeType = matcher.group(1).toLowerCase();
    return mimeType;
  }

  private String bathToMime(String url) {

    String extension = MimeTypeMap.getFileExtensionFromUrl(url);
    if (notEmpty(extension))
      mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
    return mimeType;
  }

  private String extToMime(String extension) {
    mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
    return mimeType;
  }

  private String getDownloadDir() throws IOException {
    // better check, otherwise it may crash the app
    if (Environment.MEDIA_MOUNTED.equals(Environment.getExternalStorageState())) {
      // we need to use external storage since we need to share to another app
      final String dir = webView.getContext().getExternalFilesDir(null) + "/preview-any-files";
      createOrCleanDir(dir);
      return dir;
    } else {
      return null;
    }
  }

  private void createOrCleanDir(final String downloadDir) throws IOException {
    final File dir = new File(downloadDir);
    if (!dir.exists()) {
      if (!dir.mkdirs()) {
        throw new IOException("CREATE_DIRS_FAILED");
      }
    } else {
      cleanupOldFiles(dir);
    }
  }

  private void cleanupOldFiles(File dir) {
    for (File f : dir.listFiles()) {
      // noinspection ResultOfMethodCallIgnored
      f.delete();
    }
  }

  @Override
  public void onActivityResult(int requestCode, int resultCode, Intent intent) {
    // do something with the result
    System.out.println("onActivityResult - " + requestCode + " - " + resultCode);
    String status = "NO_APP";
    if (notEmpty(mimeType)) {
      if (!mimeType.equalsIgnoreCase("application/*")) {
        status = "CLOSING";
      }
    }
    this.returnResult(Status.OK, status);
    super.onActivityResult(requestCode, resultCode, intent);
  }

  private void returnResult(PluginResult.Status status, String message) {
    System.out.println("java message - " + message);
    PluginResult pluginResult = new PluginResult(status, message);
    pluginResult.setKeepCallback(true);
    this.callbackContext.sendPluginResult(pluginResult);

  }

}