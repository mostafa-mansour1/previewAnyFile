import QuickLook

@objc(HWPPreviewAnyFile) class PreviewAnyFile: CDVPlugin {
    lazy var previewItem = NSURL()
    @objc(preview:)
    func preview(_command: CDVInvokedUrlCommand){
        let myUrl = _command.arguments[0] as! String
        self.downloadfile(withName: myUrl,completion: {(success, fileLocationURL) in
            
            if success {
                self.previewItem = fileLocationURL! as NSURL
                let previewController = QLPreviewController()
                previewController.dataSource = self;
                self.viewController?.present(previewController, animated: true, completion: nil)
            }else{
                debugPrint("File can't be downloaded")
            }
        })
    }

    
    func downloadfile(withName myUrl: String,completion: @escaping (_ success: Bool,_ fileLocation: URL?) -> Void){
            let itemUrl = URL(string: myUrl)
            if FileManager.default.fileExists(atPath: itemUrl!.path) {
               return completion(true, itemUrl)
            }
            let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationUrl = documentsDirectoryURL.appendingPathComponent(itemUrl?.lastPathComponent ?? "file.pdf")
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                do {
                    try FileManager.default.removeItem(at: destinationUrl)
                    //let error as NSError
                } catch   {
                    completion(false, nil)
                }
            }

            URLSession.shared.downloadTask(with: itemUrl!, completionHandler: { (location, response, error) -> Void in
                guard let tempLocation = location, error == nil else { return }
                do {
                    try FileManager.default.moveItem(at: tempLocation, to: destinationUrl)
                    completion(true, destinationUrl)
                    //let error as NSError
                } catch  {
                    completion(false, nil)
                }
            }).resume()
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
