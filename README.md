# Preview Any File

[![npm version](https://img.shields.io/npm/v/cordova-plugin-preview-any-file)](https://www.npmjs.com/package/cordova-plugin-preview-any-file)
[![npm downloads](https://img.shields.io/npm/dm/cordova-plugin-preview-any-file)](https://www.npmjs.com/package/cordova-plugin-preview-any-file)
[![license](https://img.shields.io/npm/l/cordova-plugin-preview-any-file)](LICENSE)

**Open PDFs, Office documents, images and other files inside your Cordova or Capacitor app on iOS and Android.**

One call, any source: a file on the device, a URL, a base64 string, or a file bundled with your app.

<table>
  <tr>
    <th>iOS (Quick Look)</th>
    <th>Android (installed viewer app)</th>
  </tr>
  <tr>
    <td><img src="https://raw.githubusercontent.com/mostafa-mansour1/previewAnyFile/master/docs/ios.png" width="280" alt="A PDF invoice previewed with Quick Look on iOS"></td>
    <td><img src="https://raw.githubusercontent.com/mostafa-mansour1/previewAnyFile/master/docs/android.png" width="280" alt="The same PDF invoice opened in the PDF viewer on Android"></td>
  </tr>
</table>

```js
window.PreviewAnyFile.previewPath(
    status => console.log(status),          // "SUCCESS", then "CLOSING" when the user closes it
    error => console.error(error),
    'https://example.com/files/invoice.pdf'
);
```

## Contents

- [Features](#features)
- [Why this plugin exists](#why-this-plugin-exists)
- [Requirements](#requirements)
- [Install](#install)
- [API](#api)
- [Examples](#examples)
- [How it works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Upgrading from 0.2.x](#upgrading-from-02x)
- [Changelog](#changelog)
- [Contributing](#contributing)
- [Author](#author)

## Features

- **Any file type**: PDF, Word, Excel, PowerPoint, Keynote, Pages, Numbers, RTF, CSV, text, images, USDZ 3D models, and anything else the platform can display.
- **Any source**: local `file://` paths, `content://` URIs (Android), remote URLs, base64 strings or data URLs, and files in your app's `www` assets.
- **Native viewer**: Quick Look on iOS; the user's installed viewer app on Android (for example Google Drive's PDF viewer or Google Photos).
- **Close callback**: get `CLOSING` when the user dismisses the preview.
- **Cordova and Capacitor**: one plugin for both.
- **No setup**: no permissions to request, no extra configuration.

## Why this plugin exists

> In 2019 I was building a mobile app and wanted users to open files right inside it: a PDF, then a Word file, then an Excel sheet, without leaving the app. I couldn't find a Cordova plugin that did it cleanly on both iOS and Android, so I spent a few evenings writing one and put it on GitHub.
>
> Seven years and more than 600,000 downloads later, it has become one of the plugins developers use to show files in Cordova and Ionic apps, and 2026 is already its busiest year. Version 0.3.0 brings it up to date with current Cordova and Capacitor and fixes the long-standing issues.
>
> — [Mostafa Mansour](https://github.com/mostafa-mansour1)

## Requirements

| Platform | Version |
| --- | --- |
| cordova-android | 14 or newer |
| cordova-ios | 8 or newer |
| Capacitor | 7 or newer |

Cordova projects on older platforms keep installing 0.2.9 automatically.

**Tested with 0.3.0.** Built and run on an Android 16 emulator (API 36) and an iOS 26.5 simulator. Each run previewed a local PDF, a remote PDF, a base64 image and a bundled asset, and checked the callbacks.

| Setup | Android | iOS |
| --- | --- | --- |
| Cordova 13 + cordova-android 15.1 / cordova-ios 8.1 | ✅ | ✅ |
| cordova-android 14.0 | ✅ | — |
| Capacitor 8.5 | ✅ | ✅ |
| Capacitor 7.6 | ✅ | ✅ |

Not yet verified on physical devices.

## Install

**Cordova**

```bash
cordova plugin add cordova-plugin-preview-any-file
```

**Capacitor**

```bash
npm install cordova-plugin-preview-any-file
npx cap sync
```

Capacitor runs Cordova plugins directly, so no extra setup is needed.

**Ionic**: a typed wrapper is maintained in the community [awesome-cordova-plugins](https://github.com/danielsogl/awesome-cordova-plugins/tree/master/src/%40awesome-cordova-plugins/plugins/preview-any-file) project (`@awesome-cordova-plugins/preview-any-file`). If a method does not behave as expected through the wrapper, call `window.PreviewAnyFile` directly.

## API

The plugin is available as `window.PreviewAnyFile` once the `deviceready` event has fired.

| Method | Use it for |
| --- | --- |
| `previewPath(success, error, path, options?)` | A `file://` path, a `content://` URI, or an `http(s)://` URL |
| `previewBase64(success, error, base64, options?)` | A base64 string or a `data:` URL |
| `previewAsset(success, error, assetPath, options?)` | A file in your app's `www` folder, for example `/assets/manual.pdf` |

**Options** (optional; needed when the path has no file extension):

| Option | Type | Description |
| --- | --- | --- |
| `name` | `string` | File name to use, for example `report.pdf`. Only the file name is used; any folder part is ignored. |
| `mimeType` | `string` | MIME type, for example `application/pdf`. |

**Success callback values:**

| Value | Meaning |
| --- | --- |
| `"SUCCESS"` | The preview opened. |
| `"CLOSING"` | The user closed the preview. |
| `"NO_APP"` | No app on the device can open this file type (Android). |

The error callback receives a message string, for example `Download failed with HTTP 404`.

## Examples

### A file on the device

Pass an absolute `file://` path. With [cordova-plugin-file](https://github.com/apache/cordova-plugin-file), use `entry.nativeURL` or `cordova.file.dataDirectory + name`.

```js
window.PreviewAnyFile.previewPath(
    status => {
        if (status === 'NO_APP') alert('No app installed can open this file.');
    },
    error => console.error('Preview failed', error),
    cordova.file.dataDirectory + 'report.pdf'
);
```

### A file from a URL

On iOS the file is downloaded before the preview opens, so show a loading indicator until the first callback.

```js
showLoader();
window.PreviewAnyFile.previewPath(
    status => { hideLoader(); console.log(status); },
    error => { hideLoader(); console.error(error); },
    'https://example.com/download?id=42',
    { name: 'statement.pdf' }   // the URL has no extension, so give it a name
);
```

### A base64 string

```js
// a data: URL carries its own MIME type
window.PreviewAnyFile.previewBase64(success, error, 'data:image/png;base64,iVBORw0KGgo...');

// plain base64 needs a name or a MIME type
window.PreviewAnyFile.previewBase64(success, error, 'JVBERi0xLjMKJcTl8uXr...', { mimeType: 'application/pdf' });
```

### A file bundled with your app

```js
window.PreviewAnyFile.previewAsset(success, error, '/assets/user-guide.pdf');
```

## How it works

**iOS** uses Apple's [Quick Look](https://developer.apple.com/documentation/quicklook/qlpreviewcontroller) inside your app. Remote files are downloaded first, and an HTTP error is reported to the error callback. Files Quick Look cannot display show a screen with a share button. Previewed files are stored in the app's temporary folder.

**Android** has no built-in document viewer, so the plugin hands the file to an installed app with `Intent.ACTION_VIEW`. Local and base64 files are shared through the plugin's own `FileProvider`. If several apps can open the file, Android asks the user to choose one.

## Troubleshooting

**Android opens the viewer but the page is blank.**
Upgrade to 0.3.0. Older versions shared their `FileProvider` with cordova-android and other plugins, so the viewer app was denied access to the file.

**iOS build fails, or `cordova plugin add` fails on cordova-ios 8.**
Upgrade to 0.3.0. Versions up to 0.2.9 do not support cordova-ios 8.

**`unsupported URL` when previewing a file from cordova-plugin-file.**
You passed `entry.toURL()`. On current platforms it returns a WebView address (`app://localhost/...` or `https://localhost/...`). Pass `entry.nativeURL` instead.

**A remote file does not open on Android.**
On Android the URL goes straight to the viewer app, so it only opens if an installed app accepts web links for that file type (Google Drive's PDF viewer does; many others do not). For reliable results, download the file first and preview the local copy.

**The Ionic wrapper throws `The old format of this exec call has been removed`.**
Call `window.PreviewAnyFile` directly, as in the examples above.

## Upgrading from 0.2.x

The JavaScript API is unchanged. Check these if they apply to your app:

- **Minimum platforms** are now cordova-android 14 and cordova-ios 8. Older Cordova projects keep getting 0.2.9.
- **iOS** stores previewed files in the temporary folder instead of `Documents`. Save your own copy if you need to keep the file.
- **Android** no longer adds the `WRITE_EXTERNAL_STORAGE` permission to your app. If your own code needs it, declare it in your `config.xml`.
- **Android** uses its own `FileProvider` (`<applicationId>.previewanyfile.provider`). Nothing to change unless your code referenced the old `<applicationId>.fileprovider` authority from this plugin.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

**Known issue:** on Android, remote URLs are not downloaded before opening; whether they open depends on the viewer apps on the device.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/mostafa-mansour1/previewAnyFile/issues). For a bug, please include your platform versions (Cordova or Capacitor, iOS or Android), the method you called and the error message.

Thanks to everyone who has contributed fixes over the years, including [@Siedlerchr](https://github.com/Siedlerchr), [@florianguillaumin](https://github.com/florianguillaumin), [@camhungh](https://github.com/camhungh), [@drewwynne0](https://github.com/drewwynne0), and the [Missive](https://github.com/missive/cordova-plugin-preview-any-file) team, whose fork pointed the way to the FileProvider and URL-encoding fixes in 0.3.0.

## Author

Built and maintained by [Mostafa Mansour](https://github.com/mostafa-mansour1). Also by Mostafa: [OPAL](https://opalapi.dev), a free offline explorer for Oracle Fusion REST APIs.

## License

[MIT](LICENSE)
