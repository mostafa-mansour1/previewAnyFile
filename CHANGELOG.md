# Changelog

## 0.4.0

New features; the callback API is unchanged. Tested on cordova-android 14 and 15, cordova-ios 8, and Capacitor 7 and 8.

- Promise API: call any method without callbacks to get a Promise, e.g. `await PreviewAnyFile.previewPath(path, { onClose })`. It resolves with `SUCCESS` or `NO_APP` and rejects with the error message.
- TypeScript types (`types/index.d.ts`).
- `headers` option for remote URLs (iOS and Android), e.g. `{ Authorization: 'Bearer …' }`. Headers are not forwarded when a redirect goes to another host or from https to http.
- `canPreview(nameOrMimeType)`: whether the device can show a file type. Uses Quick Look on iOS and the installed apps on Android (adds a `<queries>` entry to the Android manifest).
- `disableShare` option (iOS): hides Quick Look's share button, the "Save to Files"/"Print" title menu and markup editing, keeping the close button. Checked on iOS 18.5 and 26.5. It changes the UI only and is not a security control; no effect on Android.
- (Android) remote URLs are downloaded before opening, as on iOS, so they no longer depend on the viewer app accepting web links. HTTP errors now call the error callback.
- (Android) fix the close callback going to the wrong call (or arriving as `NO_APP`) when a previous viewer's result arrived late; each preview now gets its own request code.
- (Android) fix a stale MIME type from the previous call being reused when the next file has no recognisable extension.
- (Android) retry with the generic type on any "no app" error; the old check only worked on English-language devices.
- (Android) fall back to the cache folder when external storage is not available, instead of failing.
- (iOS) fix a crash when `mimeType` is unknown and no `name` is given.
- `previewAsset` reports an error for a missing asset instead of previewing the error page.

## 0.3.0

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

## 0.2.9

- (Android) fix Android AppCompat version to 1.3.1 #37 (https://github.com/mostafa-mansour1/previewAnyFile/issues/37)

## 0.2.8

- (IOS) fix issue some base64 not preview if it has the full mimetype

## 0.2.7

- (IOS) fix issue reported by @Siedlerchr #26 (https://github.com/mostafa-mansour1/previewAnyFile/issues/26)

## 0.2.6

- (IOS) fix issue reported by @Siedlerchr #23 (https://github.com/mostafa-mansour1/previewAnyFile/issues/23)

## 0.2.3

- (IOS) add CoreServices.framework to prevent build issues

## 0.2.2

- (Android) prevent application crashing on null

## 0.2.1

- fix compatibility with Ionic Capacitor

## 0.2.0

- (deprecated method) preview method will marked as deprecated, you have to use previewPath instead.
- add new methods to preview/open any file from any where (base64, asset folder, public url, locale file with any schema )
- (Android) add CLOSING callback when user finish the preview
- (Android) fix issue when open file:// or content:// (now you can view the file directly without resolve any path)

## 0.1.7

- add callback when closing in IOS (thank @drewwynne0)

## 0.1.6

- fix minor issues

## 0.1.5

- (Android) Temporary fix for the issue that file not opened in SDK > 28

## 0.1.4

- (Android) fix issue getting the file extension

## 0.1.3

- (IOS) fix issue when provide a path of the file not the url , now it accept path that start with "/" or url start with "file://"
- (IOS) fix issue if open external link more then one time
- (IOS, Android) fix call back

## 0.1.2

- update readme to add documentation

## 0.1.1

- initial the plugin
