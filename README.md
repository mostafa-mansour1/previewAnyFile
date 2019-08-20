# Preview Any File
Cordova Plugin to preview any file in native mode by providing the local or external URL.

If the source file is base64 string, you must write it into file by *cordova file plugin*

# Install

```
$ ionic cordova plugin add https://github.com/kareem289/previewAnyFile.git
```

## Usage

use this code to preview the file, it's mandatory to provide the correct extension at the last of the file path like 
file://filepath/filename.ext

```
 PreviewAnyFile.preview(link);
```

for ionic projects add in the top of file 

```
declare var PreviewAnyFile: any;
```

## Supported platforms
- Android
- iOS