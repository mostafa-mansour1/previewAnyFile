# Preview Any File
Whatever the file is PDF document, Word document, Excel, office document, archive file, image, text, html or anything else, you can perform a preview by this awesome cordova Plugin to preview any file in native mode by providing the local or external URL.

If the source file is base64 string, you must write it into file by *[cordova file plugin](https://github.com/apache/cordova-plugin-file)*

the input path file must end with a valid extension

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

the file path in android must be absolute path to the file starting with file:// if the file is starting with content:// you can resolve the native url by *[cordova file path plugin](https://github.com/hiddentao/cordova-plugin-filepath)*

# Install

```
$ cordova plugin add cordova-plugin-preview-any-file --save
```
for ionic projects 
```
$ ionic cordova plugin add cordova-plugin-preview-any-file --save
```

## Usage

Use this code to preview the file, it's mandatory to provide the correct extension at the last of the file path like 
file://filepath/filename.ext

```
 PreviewAnyFile.preview("file://filepath/filename.ext",
    function(win){ 
        if (win == "SUCCESS") {
            console.log('success') 
        }else{
            console.log('error')    
        }
     }, 
      function(err){
           console.log('err',err)     
     }
     
 );
```

you can use external link, the preview will not opened until the file downloaded successfully, so present loader before call the function then dismiss it in call back 
```
// add your code here  to show loader
 PreviewAnyFile.preview("http://www.africau.edu/images/default/sample.pdf",
    function(win){ 
        if (win == "SUCCESS") {
            console.log('success') 
        }else{
            console.log('error')    
        }
        // then dismiss the loader
     }, 
      function(err){
           console.log('err',err)   
            // then dismiss the loader  
     });
```



## Supported platforms
- Android
- iOS

## Change Log

-- version 0.1.5
* (Android) Temporary fix for the issue that file not opened in SDK > 28

-- version 0.1.4
* (Android) fix issue getting the file extension

-- version 0.1.3

* (IOS) fix issue when provide a path of the file not the url , now it accept path that start with "/" or url start with "file://"
* (IOS) fix issue if open external link more then one time
* (IOS, Android) fix call back

-- version 0.1.2
* update readme to add documentation 

-- version 0.1.1
* initial the plugin

## known Issues
* cannot open https url in android

## TO DO
* add ionic wrapper  [(Done)](https://ionicframework.com/docs/native/preview-any-file)
* support to view base64 string directly (Working on it)