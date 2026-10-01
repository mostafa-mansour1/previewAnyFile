import QuickLook
import CoreServices
//new
@objc(HWPPreviewAnyFile) class PreviewAnyFile: CDVPlugin {
    lazy var previewItem = NSURL()
    lazy var tempCommandId = String()
    @objc(preview:)
    func preview(_command: CDVInvokedUrlCommand){

        var pluginResult: CDVPluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        tempCommandId = _command.callbackId;

        let myUrl = _command.arguments[0] as! String;
        self.downloadfile(withName: myUrl,fileName: "",completion: {(success, fileLocationURL, callback) in
            if success {

                self.previewItem = fileLocationURL! as NSURL

                DispatchQueue.main.async(execute: {
                 let previewController = self.makePreviewController(disableShare: false);
                    self.viewController?.present(previewController, animated: true, completion: nil);
                    if self.viewController!.isViewLoaded {
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_OK,
                            messageAs: "SUCCESS"
                        );
                        pluginResult.keepCallback = true;
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
                    messageAs: callback?.localizedDescription ?? "Unknown error"
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
        var pluginResult: CDVPluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        tempCommandId = _command.callbackId;
        let myUrl = _command.arguments[0] as! String;
        let mimeType = _command.arguments[2] as! String;
        let name = safeFileName(_command.arguments[1] as! String);
        var fileName = "";
        var headers: [String: String] = [:];
        if _command.arguments.count > 3, let raw = _command.arguments[3] as? [String: Any] {
            for (key, value) in raw { headers[key] = "\(value)"; }
        }

        if(!name.isEmpty){
            fileName = name
        }else if(!mimeType.isEmpty){
            // an unknown MIME type used to crash here (force unwrap)
            fileName = extensionForMime(mimeType).map { "file." + $0 } ?? "file";
        }

        self.downloadfile(withName: myUrl,fileName: fileName,headers: headers,completion: {(success, fileLocationURL, callback) in
            if success {

                self.previewItem = fileLocationURL! as NSURL

                DispatchQueue.main.async(execute: {
                 let previewController = self.makePreviewController(disableShare: self.disableShareOption(_command));
                    self.viewController?.present(previewController, animated: true, completion: nil);
                    if self.viewController!.isViewLoaded {
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_OK,
                            messageAs: "SUCCESS"
                        );
                        pluginResult.keepCallback = true;
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
                    messageAs: callback?.localizedDescription ?? "Unknown error"
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

        var pluginResult: CDVPluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        tempCommandId = _command.callbackId;
        var base64String = _command.arguments[0] as! String;
        var mimeType = _command.arguments[2] as! String;
        let name = safeFileName(_command.arguments[1] as! String);
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
            // an unknown MIME type used to crash here (force unwrap)
            fileName = extensionForMime(mimeType).map { "file." + $0 } ?? "file";
        }

        guard
            // tmp, not Documents: previews are not kept forever or included in device backups.
            var documentsURL = Optional(FileManager.default.temporaryDirectory),
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
            return
        }

        let myUrl:String = documentsURL.absoluteString;

        self.downloadfile(withName: myUrl,fileName: fileName,completion: {(success, fileLocationURL, callback) in
            if success {

                self.previewItem = fileLocationURL! as NSURL

                DispatchQueue.main.async(execute: {
                 let previewController = self.makePreviewController(disableShare: self.disableShareOption(_command));
                    self.viewController?.present(previewController, animated: true, completion: nil);
                    if self.viewController!.isViewLoaded {
                        pluginResult = CDVPluginResult(
                            status: CDVCommandStatus_OK,
                            messageAs: "SUCCESS"
                        );
                        pluginResult.keepCallback = true;
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
                    messageAs: callback?.localizedDescription ?? "Unknown error"
                );
                self.commandDelegate!.send(
                    pluginResult,
                    callbackId: _command.callbackId
                );

            }
        })

    }

    func downloadfile(withName myUrl: String,fileName:String,headers: [String: String] = [:],completion: @escaping (_ success: Bool,_ fileLocation: URL? , _ callback : NSError?) -> Void){
        // Only percent-encode when the string doesn't parse as-is: encoding an already-encoded url
        // turns `%23` into `%2523` and breaks signed urls.
        var itemUrl: URL? = Foundation.URL(string: myUrl);
        if itemUrl == nil, let encoded = myUrl.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
            itemUrl = Foundation.URL(string: encoded);
        }
        guard itemUrl != nil else {
            return completion(false, nil, NSError(domain: "PreviewAnyFile", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid file path"]));
        }

        if FileManager.default.fileExists(atPath: itemUrl!.path) {

            if(itemUrl?.scheme == nil){
                itemUrl = Foundation.URL(fileURLWithPath: itemUrl!.path);
            }
            return completion(true, itemUrl,nil)
        }

        let documentsDirectoryURL = FileManager.default.temporaryDirectory
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
                return completion(false, nil,error)
            }
        }
        var request = URLRequest(url: itemUrl!);
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key); }
        let session = URLSession(configuration: .default, delegate: PreviewAnyFileRedirectGuard(original: itemUrl!, headers: headers), delegateQueue: nil);
        let downloadTask = session.downloadTask(with: request, completionHandler: { (location, response, error) -> Void in
            if error != nil{
                return completion(false, nil, error as NSError?)
            }
            // A 403/404 still yields a body; without this the error page is previewed as the file.
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200;
            guard (200..<300).contains(statusCode) else {
                return completion(false, nil, NSError(domain: "PreviewAnyFile", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Download failed with HTTP \(statusCode)"]));
            }
            guard let tempLocation = location else { return }
            do {
                try FileManager.default.moveItem(at: tempLocation, to: destinationUrl)
                completion(true, destinationUrl,nil)
                //let error as NSError
            } catch  let error as NSError  {
                completion(false, nil, error)
            }
        });

        downloadTask.resume();
        session.finishTasksAndInvalidate();

    }

    func disableShareOption(_ command: CDVInvokedUrlCommand) -> Bool {
        guard command.arguments.count > 4 else { return false }
        return (command.arguments[4] as? Bool) ?? ((command.arguments[4] as? NSNumber)?.boolValue ?? false);
    }

    func makePreviewController(disableShare: Bool) -> QLPreviewController {
        if disableShare {
            let restricted = PreviewAnyFileRestrictedController();
            restricted.dataSource = self;
            restricted.onDismiss = { [weak self] in self?.dismissPreviewCallback() };
            restricted.delegate = restricted;
            return restricted;
        }
        let previewController = QLPreviewController();
        previewController.dataSource = self;
        previewController.delegate = self;
        return previewController;
    }

    func extensionForMime(_ mimeType: String) -> String? {
        guard !mimeType.isEmpty,
              let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue(),
              let ext = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension)?.takeRetainedValue()
        else { return nil }
        return ext as String;
    }

    @objc(canPreview:)
    func canPreview(_command: CDVInvokedUrlCommand){
        let name = safeFileName(_command.arguments[0] as? String ?? "");
        let mimeType = _command.arguments.count > 1 ? (_command.arguments[1] as? String ?? "") : "";
        var ext = (name as NSString).pathExtension;
        if ext.isEmpty, let mimeExt = extensionForMime(mimeType) { ext = mimeExt; }
        var result = false;
        if !ext.isEmpty {
            // Quick Look decides by file type, so an empty file with the right extension is enough.
            let probe = FileManager.default.temporaryDirectory.appendingPathComponent("preview-any-file-probe.\(ext)");
            FileManager.default.createFile(atPath: probe.path, contents: Data());
            result = QLPreviewController.canPreview(probe as NSURL);
            try? FileManager.default.removeItem(at: probe);
        }
        self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result), callbackId: _command.callbackId);
    }

    // Keep only the last path component so a caller-supplied name like "../../x" cannot escape
    // the temporary directory (the destination is deleted before it is written).
    func safeFileName(_ name: String) -> String {
        let base = (name as NSString).lastPathComponent;
        return (base == "." || base == ".." || base == "/") ? "" : base;
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

// Caller headers (e.g. Authorization) follow redirects only on the original host and never over a downgrade to http.
class PreviewAnyFileRedirectGuard: NSObject, URLSessionTaskDelegate {
    let original: URL
    let headers: [String: String]

    init(original: URL, headers: [String: String]) {
        self.original = original
        self.headers = headers
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        var next = request
        let sameHost = request.url?.host?.lowercased() == original.host?.lowercased()
        let downgraded = original.scheme == "https" && request.url?.scheme != "https"
        for (key, value) in headers {
            next.setValue(sameHost && !downgraded ? value : nil, forHTTPHeaderField: key)
        }
        completionHandler(next)
    }
}

// disableShare: hides Quick Look's share, save, print and markup controls, keeping the close button.
// This changes the UI only (screenshots and copying from the document remain possible). It uses
// public UIKit API on Quick Look's own navigation controller, so a future iOS layout can bring the
// controls back; it never removes the close button. Checked on iOS 18.5 and 26.5.
class PreviewAnyFileRestrictedController: QLPreviewController, QLPreviewControllerDelegate {
    var onDismiss: (() -> Void)?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hideShareControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hideShareControls()
    }

    func hideShareControls() {
        toolbarItems = []
        for nav in navigationControllers(in: self) {
            nav.isToolbarHidden = true
            for vc in nav.viewControllers {
                vc.toolbarItems = []
                if #available(iOS 16.0, *) {
                    vc.navigationItem.documentProperties = nil
                    vc.navigationItem.titleMenuProvider = nil
                    vc.navigationItem.renameDelegate = nil
                }
            }
        }
        if #available(iOS 16.0, *) {
            navigationItem.documentProperties = nil
            navigationItem.titleMenuProvider = nil
        }
    }

    func navigationControllers(in vc: UIViewController) -> [UINavigationController] {
        var found: [UINavigationController] = []
        if let nav = vc as? UINavigationController { found.append(nav) }
        for child in vc.children { found += navigationControllers(in: child) }
        return found
    }

    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        return .disabled
    }

    func previewControllerWillDismiss(_ controller: QLPreviewController) {
        onDismiss?()
    }
}
