package com.mostafa.previewanyfile;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
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
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class PreviewAnyFile extends CordovaPlugin {

  private CallbackContext callbackContext; // The callback context from which we were invoked.
  private String mimeType = null;

  // Each preview gets its own request code, so a viewer's close result is reported to the call that
  // opened it (with that call's MIME type) and late results from older previews are ignored.
  private final Map<Integer, Object[]> pendingPreviews = Collections.synchronizedMap(new HashMap<Integer, Object[]>());
  private int nextRequestCode = 1000;

  // Keep only the last path segment so a caller-supplied name like "../../x" cannot escape the
  // plugin's directory.
  private static String safeFileName(String name) {
    if (name == null)
      return null;
    String base = new File(name).getName();
    return (".".equals(base) || "..".equals(base)) ? "" : base;
  }

  private static boolean notEmpty(String what) {
    return what != null && !"".equals(what) && !"null".equalsIgnoreCase(what);
  }

  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    if ("canPreview".equals(action)) {
      callbackContext.sendPluginResult(new PluginResult(Status.OK, canPreview(args.optString(0), args.optString(1))));
      return true;
    }
    this.callbackContext = callbackContext;
    this.mimeType = null;

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
              previewPath(path, namePreviewPath, PathMimetype, args.optJSONObject(3));
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
    viewFile(pathToUri(url));
  }

  private void previewPath(String path, String name, String mediaType, JSONObject headers)
      throws URISyntaxException, IOException {
    if (notEmpty(mediaType))
      this.mimeType = mediaType;
    else
      this.mimeType = notEmpty(name) ? bathToMime(name) : bathToMime(path);
    String lower = path.toLowerCase();
    if (lower.startsWith("http://") || lower.startsWith("https://")) {
      // Download first, like iOS: viewer apps rarely accept an https link together with a MIME type.
      viewFile(fileToUri(download(path, name, headers)));
    } else {
      viewFile(pathToUri(path));
    }
  }

  private static final int MAX_REDIRECTS = 5;

  private File download(String url, String name, JSONObject headers) throws IOException {
    URL original = new URL(url);
    URL current = original;
    HttpURLConnection conn = null;
    for (int redirects = 0;; redirects++) {
      conn = (HttpURLConnection) current.openConnection();
      conn.setInstanceFollowRedirects(false);
      conn.setConnectTimeout(15000);
      conn.setReadTimeout(30000);
      // Send caller headers (e.g. Authorization) only to the original host and never over a downgrade to http.
      boolean sameHost = current.getHost().equalsIgnoreCase(original.getHost());
      boolean downgraded = "https".equals(original.getProtocol()) && !"https".equals(current.getProtocol());
      if (headers != null && sameHost && !downgraded) {
        Iterator<String> keys = headers.keys();
        while (keys.hasNext()) {
          String key = keys.next();
          conn.setRequestProperty(key, headers.optString(key));
        }
      }
      int code = conn.getResponseCode();
      String location = conn.getHeaderField("Location");
      if (code >= 300 && code < 400 && notEmpty(location)) {
        conn.disconnect();
        if (redirects >= MAX_REDIRECTS)
          throw new IOException("Download failed: too many redirects");
        current = new URL(current, location);
        continue;
      }
      if (code < 200 || code >= 300) {
        conn.disconnect();
        throw new IOException("Download failed with HTTP " + code);
      }
      break;
    }

    if (!notEmpty(mimeType) && notEmpty(conn.getContentType()))
      mimeType = conn.getContentType().split(";")[0].trim();

    String fileName = safeFileName(name);
    if (!notEmpty(fileName))
      fileName = safeFileName(Uri.parse(current.toString()).getLastPathSegment());
    if (!notEmpty(fileName))
      fileName = "file";
    if (fileName.lastIndexOf('.') <= 0 && notEmpty(mimeType)) {
      String ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType);
      if (notEmpty(ext))
        fileName = fileName + "." + ext;
    }

    File out = new File(getDownloadDir(), fileName);
    InputStream in = conn.getInputStream();
    OutputStream os = new FileOutputStream(out);
    try {
      byte[] buffer = new byte[8192];
      int read;
      while ((read = in.read(buffer)) != -1)
        os.write(buffer, 0, read);
    } catch (IOException e) {
      // noinspection ResultOfMethodCallIgnored
      out.delete();
      throw e;
    } finally {
      os.close();
      in.close();
      conn.disconnect();
    }
    return out;
  }

  private boolean canPreview(String name, String mediaType) {
    String type = notEmpty(mediaType) ? mediaType : null;
    if (type == null && notEmpty(name)) {
      String ext = MimeTypeMap.getFileExtensionFromUrl(name.replace(" ", "_"));
      if (notEmpty(ext))
        type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext.toLowerCase());
    }
    if (type == null)
      return false;
    Intent intent = new Intent(Intent.ACTION_VIEW);
    intent.setDataAndType(Uri.parse("content://" + providerAuthority() + "/probe"), type);
    PackageManager pm = cordova.getActivity().getPackageManager();
    return !pm.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY).isEmpty();
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
      int requestCode;
      synchronized (this) {
        requestCode = nextRequestCode++;
      }
      pendingPreviews.put(requestCode, new Object[] { this.callbackContext, mimeType });
      try {
        this.cordova.startActivityForResult(this, intent, requestCode);
      } catch (ActivityNotFoundException e) {
        pendingPreviews.remove(requestCode);
        throw e;
      }
      this.returnResult(Status.OK, "SUCCESS");
    } catch (ActivityNotFoundException t) {
      if (!mimeType.equalsIgnoreCase("application/*")) {
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
      uri = fileToUri(new File(new URI(url)));
    } else {
      uri = Uri.parse(url);
    }
    return uri;
  }

  private String providerAuthority() {
    return this.cordova.getActivity().getApplicationContext().getPackageName() + ".previewanyfile.provider";
  }

  private Uri fileToUri(File file) {
    return FileProvider.getUriForFile(this.cordova.getActivity(), providerAuthority(), file);
  }

  private String base64ToPath(String base64, String fileName) throws IOException {
    fileName = safeFileName(fileName);
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
    File base = Environment.MEDIA_MOUNTED.equals(Environment.getExternalStorageState())
        ? webView.getContext().getExternalFilesDir(null)
        : null;
    if (base == null)
      base = webView.getContext().getCacheDir();
    final String dir = base + "/preview-any-files";
    createOrCleanDir(dir);
    return dir;
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
    Object[] preview = pendingPreviews.remove(requestCode);
    if (preview != null) {
      String type = (String) preview[1];
      String status = notEmpty(type) && !type.equalsIgnoreCase("application/*") ? "CLOSING" : "NO_APP";
      PluginResult result = new PluginResult(Status.OK, status);
      result.setKeepCallback(true);
      ((CallbackContext) preview[0]).sendPluginResult(result);
    }
    super.onActivityResult(requestCode, resultCode, intent);
  }

  private void returnResult(PluginResult.Status status, String message) {
    PluginResult pluginResult = new PluginResult(status, message);
    pluginResult.setKeepCallback(true);
    this.callbackContext.sendPluginResult(pluginResult);

  }

}