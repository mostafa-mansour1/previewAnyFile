import QuickLook
//new
@objc(HWPPreviewAnyFile) class PreviewAnyFile: CDVPlugin {
    lazy var previewItem = NSURL()
    @objc(preview:)
    func preview(_command: CDVInvokedUrlCommand){
        
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        
        let myUrl = _command.arguments[0] as! String;
        self.downloadfile(withName: myUrl,completion: {(success, fileLocationURL, callback) in
            if success {
                
                self.previewItem = fileLocationURL! as NSURL
                let previewController = QLPreviewController();
                previewController.dataSource = self;
                DispatchQueue.main.async(execute: {
                    self.viewController?.present(previewController, animated: true, completion: nil);
                    if self.viewController!.isViewLoaded {
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_OK,
                            messageAs: "SUCCESS"
                        );
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
    
    func downloadfile(withName myUrl: String,completion: @escaping (_ success: Bool,_ fileLocation: URL? , _ callback : NSError?) -> Void){
        let  url = myUrl.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!;
        var itemUrl: URL? = Foundation.URL(string: url);
        if FileManager.default.fileExists(atPath: itemUrl!.path) {
            if(itemUrl?.scheme == nil){
                itemUrl = Foundation.URL(string: "file://\(url)");
            }
            return completion(true, itemUrl,nil)
        }
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(itemUrl?.lastPathComponent ?? "file.pdf")
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
    
    
    
}

extension PreviewAnyFile: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem as QLPreviewItem
    }
}
