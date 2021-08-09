import QuickLook
import CoreServices
//new
@objc(HWPPreviewAnyFile) class PreviewAnyFile: CDVPlugin {
    lazy var previewItem = NSURL()
    lazy var tempCommandId = String()
    @objc(preview:)
    func preview(_command: CDVInvokedUrlCommand){

        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        tempCommandId = _command.callbackId;

        let myUrl = _command.arguments[0] as! String;
        self.downloadfile(withName: myUrl,fileName: "",completion: {(success, fileLocationURL, callback) in
            if success {

                self.previewItem = fileLocationURL! as NSURL

                DispatchQueue.main.async(execute: {
                 let previewController = QLPreviewController();
                 previewController.dataSource = self;
                 previewController.delegate = self;
                    self.viewController?.present(previewController, animated: true, completion: nil);
                    if self.viewController!.isViewLoaded {
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_OK,
                            messageAs: "SUCCESS"
                        );
                        pluginResult?.keepCallback = true;
                        self.commandDelegate!.send(
                            pluginResult,
                            callbackId: _command.callbackId
                        );
                    }
                    else{
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_ERROR,
                            messageAs: "FAILED"
                        );
                        self.commandDelegate!.send(
                            pluginResult,
                            callbackId: _command.callbackId
                        );
                    }
                });

            }else{
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: callback?.localizedDescription
                );
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: _command.callbackId
                );

            }
        })
    }


    @objc(previewPath:)
    func previewPath(_command: CDVInvokedUrlCommand){
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        tempCommandId = _command.callbackId;
        var ext:String = "";
        let myUrl = _command.arguments[0] as! String;
        let mimeType = _command.arguments[2] as! String;
        let name = _command.arguments[1] as! String;
        var fileName = "";

        if(!name.isEmpty){
            fileName = name
        }else if(!mimeType.isEmpty){
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil);
            let NewExt = UTTypeCopyPreferredTagWithClass((uti?.takeRetainedValue())!, kUTTagClassFilenameExtension);
                ext = NewExt!.takeRetainedValue() as String;
                fileName = "file."+ext;
        }

        self.downloadfile(withName: myUrl,fileName: fileName,completion: {(success, fileLocationURL, callback) in
            if success {

                self.previewItem = fileLocationURL! as NSURL

                DispatchQueue.main.async(execute: {
                 let previewController = QLPreviewController();
                 previewController.dataSource = self;
                 previewController.delegate = self;
                    self.viewController?.present(previewController, animated: true, completion: nil);
                    if self.viewController!.isViewLoaded {
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_OK,
                            messageAs: "SUCCESS"
                        );
                        pluginResult?.keepCallback = true;
                        self.commandDelegate!.send(
                            pluginResult,
                            callbackId: _command.callbackId
                        );
                    }
                    else{
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_ERROR,
                            messageAs: "FAILED"
                        );
                        self.commandDelegate!.send(
                            pluginResult,
                            callbackId: _command.callbackId
                        );
                    }
                });

            }else{
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: callback?.localizedDescription
                );
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: _command.callbackId
                );

            }
        })
    }


    @objc(previewBase64:)
    func previewBase64(_command: CDVInvokedUrlCommand){

        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        tempCommandId = _command.callbackId;
        var ext:String = "";
        var base64String = _command.arguments[0] as! String;
        var mimeType = _command.arguments[2] as! String;
        let name = _command.arguments[1] as! String;
        var fileName = "";

        if(base64String.isEmpty){
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "No Base64 code found"
            );
            self.commandDelegate!.send(
                pluginResult,
                callbackId: _command.callbackId
            );
            return;
        }else if(base64String.contains(";base64,")){
            let baseTmp = base64String.components(separatedBy: ",");
            base64String = baseTmp[1];
            mimeType = baseTmp[0].replacingOccurrences(of: "data:",with: "").replacingOccurrences(of: ";base64",with: "");
        }

        if(name.isEmpty && mimeType.isEmpty){
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "You must define file name or mime type"
            );
            self.commandDelegate!.send(
                pluginResult,
                callbackId: _command.callbackId
            );
            return;
        }

        if(!name.isEmpty){
            fileName = name
        }else if(!mimeType.isEmpty){
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil);
            let NewExt = UTTypeCopyPreferredTagWithClass((uti?.takeRetainedValue())!, kUTTagClassFilenameExtension);
                ext = NewExt!.takeRetainedValue() as String;
                fileName = "file."+ext;
        }

        guard
            var documentsURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last,
            let convertedData = Data(base64Encoded: base64String)
            else {
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "base64 not valid"
            );
            self.commandDelegate!.send(
                pluginResult,
                callbackId: _command.callbackId
            );

            //handle error when getting documents URL
            return
        }
        documentsURL.appendPathComponent(fileName)
        do {
            try convertedData.write(to: documentsURL)
        } catch {

            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "cannot write the base64"
            );
            self.commandDelegate!.send(
                pluginResult,
                callbackId: _command.callbackId
            );
            //handle write error here
        }

        let myUrl:String = documentsURL.absoluteString;

        self.downloadfile(withName: myUrl,fileName: fileName,completion: {(success, fileLocationURL, callback) in
            if success {

                self.previewItem = fileLocationURL! as NSURL

                DispatchQueue.main.async(execute: {
                 let previewController = QLPreviewController();
                 previewController.dataSource = self;
                 previewController.delegate = self;
                    self.viewController?.present(previewController, animated: true, completion: nil);
                    if self.viewController!.isViewLoaded {
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_OK,
                            messageAs: "SUCCESS"
                        );
                        pluginResult?.keepCallback = true;
                        self.commandDelegate!.send(
                            pluginResult,
                            callbackId: _command.callbackId
                        );
                    }
                    else{
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_ERROR,
                            messageAs: "FAILED"
                        );
                        self.commandDelegate!.send(
                            pluginResult,
                            callbackId: _command.callbackId
                        );
                    }
                });

            }else{
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: callback?.localizedDescription
                );
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: _command.callbackId
                );

            }
        })

    }

    func downloadfile(withName myUrl: String,fileName:String,completion: @escaping (_ success: Bool,_ fileLocation: URL? , _ callback : NSError?) -> Void){
        let  url = myUrl.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!;
        var itemUrl: URL? = Foundation.URL(string: url);

       //if the file not exist by read the url, so try again to get the file by reading base64 string
        if !FileManager.default.fileExists(atPath: itemUrl!.path) {
                   itemUrl = Foundation.URL(string: myUrl);
        }
        
        if FileManager.default.fileExists(atPath: itemUrl!.path) {

            if(itemUrl?.scheme == nil){
                itemUrl = Foundation.URL(string: "file://\(url)");
            }
            return completion(true, itemUrl,nil)
        }

        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var disFileName = "";
        if(fileName.isEmpty){
            disFileName = itemUrl?.lastPathComponent ?? "file.pdf";
        }else{
            disFileName = fileName;
        }
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(disFileName);

        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            do {
                try FileManager.default.removeItem(at: destinationUrl)
                //let error as NSError
            } catch let error as NSError  {
                completion(false, nil,error)
            }
        }
        let downloadTask = URLSession.shared.downloadTask(with: itemUrl!, completionHandler: { (location, response, error) -> Void in
            if error != nil{
                completion(false, nil, error as NSError?)
            }
            guard let tempLocation = location, error == nil else { return }
            do {
                try FileManager.default.moveItem(at: tempLocation, to: destinationUrl)
                completion(true, destinationUrl,nil)
                //let error as NSError
            } catch  let error as NSError  {
                completion(false, nil, error)
            }
        });

        downloadTask.resume();

    }

    func dismissPreviewCallback(){
        print(tempCommandId)
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "CLOSING");
        self.commandDelegate!.send(pluginResult, callbackId: tempCommandId);
    }

}

extension PreviewAnyFile: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem as QLPreviewItem
    }

    func previewControllerWillDismiss(_ controller: QLPreviewController) {
        self.dismissPreviewCallback();

    }
}
