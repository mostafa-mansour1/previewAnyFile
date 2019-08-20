# Preview Any File
Cordova Plugin to preview any file in native mode by providing the local or external URL.

If the source file is base64 string, you must write it into file by *[cordova file plugin](https://github.com/apache/cordova-plugin-file)*

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

# Install

```
$ cordova plugin add cordova-plugin-preview-any-file --save
```

## Usage

Use this code to preview the file, it's mandatory to provide the correct extension at the last of the file path like 
file://filepath/filename.ext

```
 PreviewAnyFile.preview("file://filepath/filename.ext");
```

```
 PreviewAnyFile.preview("http://www.africau.edu/images/default/sample.pdf");
```

for ionic projects declare the plugin in the top of file 

```
declare var PreviewAnyFile: any;
```

## Supported platforms
- Android
- iOS


## TO DO
* add ionic wrapper
* support to view base64 string directly