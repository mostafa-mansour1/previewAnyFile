# Preview Any File

Whatever the file is PDF document, Word document, Excel, office document, archive file, image, text, html or anything else, you can perform a preview by this awesome cordova Plugin to preview any file in native mode by providing the local or external URL.

From version 0.2.0, you can preview the file from any where, you can use base64 or local file from assets or local files from the device or even from internet.

From version 0.2.0, you can overwrite the file name or its mime type, if the file has no extension at the end of the path

you can find the project at github

https://github.com/mostafa-mansour1/previewAnyFile

# How it work

# For IOS

Using the built-in class [QLPreviewController](https://developer.apple.com/documentation/quicklook/qlpreviewcontroller),
A QLPreviewController can display previews for the following items:

- iWork documents
- Microsoft Office documents (Office ‘97 and newer)
- Rich Text Format (RTF) documents
- PDF files
- Images
- Text files whose uniform type identifier (UTI) conforms to the public.text type (see Uniform Type Identifiers Reference)
- Comma-separated value (csv) files
- 3D models in USDZ format (with both standalone and AR views for viewing the model)

for any other file it will present the preview with message "cannot preview file" and there is a button to save the file in the device

# For Android

Android not like ios, there is no way to render the file directly, the user must install a suitable application for every type.

So I used Intent.ACTION_VIEW to preview the file,

if there is a suitable application already installed in the user device it will preview the file directly,

if not, it will ask the user to select an application

the file path in android must be absolute path to the file starting with file:// or content://

# Install

```
$ cordova plugin add cordova-plugin-preview-any-file --save
```

for ionic projects

- [(How to use in ionic project)](https://ionicframework.com/docs/native/preview-any-file)
- [(preview-any-file.zip)](https://github.com/mostafa-mansour1/previewAnyFile/files/5912855/preview-any-file.zip) as I have a pull request to add the new wrapper from 2nd Feb on ionic-native project but still didn't merged till now , so you can replace the wrapper after install from the link

```
$ ionic cordova plugin add cordova-plugin-preview-any-file --save
```

## Usage

Use this code to preview the file,

if the correct extension not exist at the last of the file path like
file://filepath/filename.ext
you must define the file name or its mimeType in the 2nd params {name:'file.png',mimeType : 'image/png'}

### - View or Open file from the device

```
    window.PreviewAnyFile.previewPath(
        win =>
            {
                if (win == "SUCCESS") {
                    console.log('success')
                } else if (win == "CLOSING") {
                    console.log('closing')
                } else if (win == "NO_APP") {
                    console.log('no suitable app to open the file (mainly will appear on android')
                } else {
                    console.log('error')
                }
            },
        error => console.error("open failed", error),
        "file://filepath/filename.ext"
    );
```

### - View or Open file from an external link

you can use external link, the preview will not opened until the file downloaded successfully, so present loader before call the function then dismiss it in call back, you can define the name of the file or its mimeType in the options

```
    // add your code here  to show loader

    window.PreviewAnyFile.previewPath(
        win => console.log("open status",win),
        error => console.error("open failed", error),
        "http://www.domain.com/samplefile",{name : file.pdf}
    );

```

### - View or Open base64 file

```
    window.PreviewAnyFile.previewBase64(
        win => console.log("open status",win),
        error => console.error("open failed", error),
        'data:image/gif;base64,R0lGODlhP.....'
    );

    // you must define the mimeType or file name if the base64 string has no media type
    window.PreviewAnyFile.previewBase64(
        win => console.log("open status",win),
        error => console.error("open failed", error),
        'JVBERi0xLjMKJcTl8uXr.....',{mimeType:'application/pdf'}
    );
```

### - View or Open file from the asset folder

```
    window.PreviewAnyFile.previewAsset(
        win => console.log("open status",win),
        error => console.error("open failed", error),
        '/assets/localFile.pdf'
    );

    // you must define the mimeType or file name if the base64 string has no media type
    window.PreviewAnyFile.previewBase64(
        win => console.log("open status",win),
        error => console.error("open failed", error),
        '/assets/fileWithoutExt',{mimeType:'application/pdf',name:'file.pdf'}
    );
```

## Supported platforms

- Android
- iOS

## Change Log

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

## known Issues

- cannot open https url in android

## TO DO

- add ionic wrapper [(Done)](https://ionicframework.com/docs/native/preview-any-file)
- support to view base64 string directly (Working on it)
