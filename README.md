# Preview Any File

[![npm](https://img.shields.io/npm/v/cordova-plugin-preview-any-file)](https://www.npmjs.com/package/cordova-plugin-preview-any-file)
[![npm downloads](https://img.shields.io/npm/dm/cordova-plugin-preview-any-file)](https://www.npmjs.com/package/cordova-plugin-preview-any-file)

A Cordova plugin that previews any file natively in your iOS or Android app: PDF, Word, Excel and other Office documents, images, text, HTML, archives and more. Works in Cordova and Capacitor apps.

You can preview a local file, a remote URL, a base64 string, or a file bundled in your app's assets. If the path has no file extension, pass the file name or MIME type in the options.

## How it works

### iOS

Uses the built-in [QLPreviewController](https://developer.apple.com/documentation/quicklook/qlpreviewcontroller) (Quick Look). It can display:

- iWork documents
- Microsoft Office documents (Office ‘97 and newer)
- Rich Text Format (RTF) documents
- PDF files
- Images
- Text files whose uniform type identifier (UTI) conforms to `public.text`
- Comma-separated value (csv) files
- 3D models in USDZ format

For any other file type, Quick Look shows a "cannot preview" screen with a button to save or share the file. Remote URLs are downloaded first; if the server returns an HTTP error, the error callback is called.

### Android

Android has no built-in document viewer, so the plugin opens the file with `Intent.ACTION_VIEW`. If a suitable app is installed (for example Google Drive's PDF viewer or Google Photos), the file opens directly; otherwise the user is asked to choose an app.

Local files and base64 content are shared with the viewer app through the plugin's own `FileProvider`.

## Requirements

| Platform | Version |
| --- | --- |
| cordova-android | 14 or newer |
| cordova-ios | 8 or newer |
| Capacitor | 7 or newer |

Cordova projects on older platforms automatically keep installing 0.2.9, the previous release.

### Tested with (0.3.0)

Built and run on an emulator and a simulator. Each run previewed a local `file://` PDF, a remote PDF, a base64 image and a bundled asset, and checked the `SUCCESS` / `CLOSING` callbacks:

| Setup | Android 16 emulator (API 36) | iOS 26.5 simulator |
| --- | --- | --- |
| Cordova 13 + cordova-android 15.1 / cordova-ios 8.1 | ✅ | ✅ |
| cordova-android 14.0 | ✅ | — |
| Capacitor 8.5 | ✅ | ✅ |
| Capacitor 7.6 | ✅ | ✅ |

Not yet verified on physical devices.

## Install

### Cordova

```
cordova plugin add cordova-plugin-preview-any-file
```

### Capacitor

```
npm install cordova-plugin-preview-any-file
npx cap sync
```

Capacitor loads Cordova plugins directly; no extra setup is needed. Call the plugin through `window.PreviewAnyFile` as shown below.

### Ionic wrapper

A typed wrapper is maintained in the community [awesome-cordova-plugins](https://github.com/danielsogl/awesome-cordova-plugins/tree/master/src/%40awesome-cordova-plugins/plugins/preview-any-file) project (`@awesome-cordova-plugins/preview-any-file`). If a method does not behave as expected through the wrapper, call `window.PreviewAnyFile` directly.

## Usage

All methods take a success callback, an error callback, the file, and optional `{ name, mimeType }`.

The success callback is called with:

- `"SUCCESS"`: the preview opened
- `"CLOSING"`: the user closed the preview
- `"NO_APP"`: no app on the device can open this file (Android)

### Preview a file on the device

The path must be an absolute `file://` path. With [cordova-plugin-file](https://github.com/apache/cordova-plugin-file), use `entry.nativeURL` (or `cordova.file.dataDirectory + name`), not `entry.toURL()`: on current platforms `toURL()` returns a WebView URL (`app://localhost/...` or `https://localhost/...`) that native code cannot open.

```js
window.PreviewAnyFile.previewPath(
    win => {
        if (win == "SUCCESS") {
            console.log('success')
        } else if (win == "CLOSING") {
            console.log('closing')
        } else if (win == "NO_APP") {
            console.log('no suitable app to open the file (mainly on Android)')
        }
    },
    error => console.error("open failed", error),
    "file:///path/to/filename.ext"
);
```

### Preview a file from a URL

On iOS the file is downloaded before the preview opens, so show a loader before calling and hide it in the callback. If the URL has no file extension, pass the file name or MIME type.

On Android the URL is passed to the installed viewer app as is, so whether it opens depends on the apps on the device. Google Drive's PDF viewer opens `https` PDF links; many other viewers do not. If you need this to work reliably on Android, download the file first and preview the local copy.

```js
window.PreviewAnyFile.previewPath(
    win => console.log("open status", win),
    error => console.error("open failed", error),
    "https://www.example.com/samplefile",
    { name: 'file.pdf' }
);
```

### Preview a base64 string

```js
window.PreviewAnyFile.previewBase64(
    win => console.log("open status", win),
    error => console.error("open failed", error),
    'data:image/gif;base64,R0lGODlhP.....'
);

// without a data: prefix, pass the MIME type or a file name
window.PreviewAnyFile.previewBase64(
    win => console.log("open status", win),
    error => console.error("open failed", error),
    'JVBERi0xLjMKJcTl8uXr.....',
    { mimeType: 'application/pdf' }
);
```

### Preview a file from your app's assets

```js
window.PreviewAnyFile.previewAsset(
    win => console.log("open status", win),
    error => console.error("open failed", error),
    '/assets/localFile.pdf'
);

// if the file has no extension, pass the MIME type or a file name
window.PreviewAnyFile.previewAsset(
    win => console.log("open status", win),
    error => console.error("open failed", error),
    '/assets/fileWithoutExt',
    { mimeType: 'application/pdf', name: 'file.pdf' }
);
```

## Supported platforms

- Android
- iOS

## Change Log

-- version 0.3.0

Works on current Cordova and Capacitor again. Tested on cordova-android 14 and 15, cordova-ios 8, and Capacitor 7 and 8.

- (Security, iOS and Android) the `name` option was used as a file path as-is, so a name such as `../file` wrote outside the plugin's folder (and on iOS deleted the existing file there first). This could be exploited when an app passes a server-supplied file name. Only the last path component of `name` is used now.
- (Security, Android) removed debug logging that printed full URLs and file paths to logcat; signed URLs could leak access tokens there.
- (Privacy, iOS) previewed and downloaded files are now saved in the app's temporary folder instead of `Documents`, so they are no longer kept indefinitely or included in device backups. If your app relied on finding previewed files in `Documents`, save a copy yourself before previewing.
- (Privacy, Android) the plugin no longer requests the `WRITE_EXTERNAL_STORAGE` permission. It never needed it: files are written to app-specific storage. If your app needs that permission for its own code, declare it in your app's `config.xml`.
- (Android) replace the pinned `androidx.appcompat:appcompat:1.3.1` with `androidx.core:core:1.13.0`, the library the plugin actually uses. Supported Cordova and Capacitor versions already include it, so app dependency versions do not change.
- (iOS) fix build on cordova-ios 8: the plugin no longer compiled, and its `cordova-plugin-add-swift-support` dependency failed during install. That dependency is removed; cordova-ios 8 supports Swift natively.
- (iOS) a remote URL that returns an HTTP error (404, 403, ...) now calls the error callback instead of previewing the error page as the file.
- (iOS) URLs that are already percent-encoded are no longer encoded twice, which broke signed URLs and file names containing `#`, spaces or accents (#45).
- (Android) fix blank documents: local and base64 files opened in the viewer as empty pages on current cordova-android, because the plugin's `FileProvider` shared its class name with cordova-android's own provider. The plugin now uses its own provider class (`com.mostafa.previewanyfile.PreviewAnyFileProvider`), authority (`<applicationId>.previewanyfile.provider`) and paths file (`res/xml/preview_any_file_paths.xml`), so it no longer conflicts with Capacitor or other plugins either.
- (Android) remove the `cordova-plugin-androidx` and `cordova-plugin-androidx-adapter` dependencies, which are not needed on supported platforms (#44).
- `previewAsset` now calls the error callback when the asset cannot be loaded (it previously only logged to the console).
- Declare minimum platforms (cordova-android 14, cordova-ios 8). Cordova projects on older platforms keep installing 0.2.9.
- README: Capacitor install, requirements and tested versions, `nativeURL` vs `toURL()`, Android remote URL behaviour, working Ionic wrapper link (#47).

-- version 0.2.9

- (Android) fix Android AppCompat version to 1.3.1 #37 (https://github.com/mostafa-mansour1/previewAnyFile/issues/37)

-- version 0.2.8

- (IOS) fix issue some base64 not preview if it has the full mimetype

-- version 0.2.7

- (IOS) fix issue reported by @Siedlerchr #26 (https://github.com/mostafa-mansour1/previewAnyFile/issues/26)

-- version 0.2.6

- (IOS) fix issue reported by @Siedlerchr #23 (https://github.com/mostafa-mansour1/previewAnyFile/issues/23)

-- version 0.2.3

- (IOS) add CoreServices.framework to prevent build issues

-- version 0.2.2

- (Android) prevent application crashing on null

-- version 0.2.1

- fix compatibility with Ionic Capacitor

-- version 0.2.0

- (deprecated method) preview method will marked as deprecated, you have to use previewPath instead.
- add new methods to preview/open any file from any where (base64, asset folder, public url, locale file with any schema )
- (Android) add CLOSING callback when user finish the preview
- (Android) fix issue when open file:// or content:// (now you can view the file directly without resolve any path)

-- version 0.1.7

- add callback when closing in IOS (thank @drewwynne0)

-- version 0.1.6

- fix minor issues

-- version 0.1.5

- (Android) Temporary fix for the issue that file not opened in SDK > 28

-- version 0.1.4

- (Android) fix issue getting the file extension

-- version 0.1.3

- (IOS) fix issue when provide a path of the file not the url , now it accept path that start with "/" or url start with "file://"
- (IOS) fix issue if open external link more then one time
- (IOS, Android) fix call back

-- version 0.1.2

- update readme to add documentation

-- version 0.1.1

- initial the plugin

## Known issues

- (Android) remote URLs are not downloaded before opening; whether they open depends on the viewer apps installed on the device.
