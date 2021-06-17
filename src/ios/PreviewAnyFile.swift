import Cordova
import Cordova
import QuickLook
import CoreServices
//new
let IPAD_PREVIEW_TOOLBAR_HEIGHT = 80;
let IPHONE_PREVIEW_TOOLBAR_HEIGHT_PORTRAIT = 60;
let IPHONE_PREVIEW_TOOLBAR_HEIGHT_LANDSCAPE = 60;
let CLOSE_TEXT = "Close";

class PreviewOptions: NSObject{
    let closeButtonText: String = CLOSE_TEXT;
  override  init() {
        super.init();
    }
   
}

class PreviewNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
     }
    
 
    override func viewDidLayoutSubviews() {
        if let controller = viewControllers.first {
            let fullscreen =  controller.prefersStatusBarHidden;
            if(!fullscreen){
                self.resetToolbarNavbar();
            }
         }
       
        self.setIpadToolbarBackground();
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        if let controller = viewControllers.first {
            controller.navigationItem.leftBarButtonItem = UIBarButtonItem();
            controller.navigationItem.titleView = UIView();
         }
        self.resetToolbarNavbar();
        self.setIpadToolbarBackground();
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
    }
    
    private func resetToolbarNavbar(){
        self.setToolbarHidden(false, animated: false);
        self.setNavigationBarHidden(true, animated: false);
    }
    
    private func setIpadToolbarBackground(){
        if(UIDevice.current.userInterfaceIdiom == .pad){
            if #available(iOS 13, *) {
                self.toolbar.backgroundColor = UIColor.systemBackground;
             } else {
                self.toolbar.backgroundColor = UIColor.white;
             }
        }
    }
}

 
extension Notification.Name {
    static let didCloseButtonTap = Notification.Name("didCloseButtonTap")
}

class PreviewControllerToolbar: UIToolbar {
    public static var CLOSE_BUTTON_TEXT: String = CLOSE_TEXT;
    @objc(doneButtonTapped)
     func doneButtonTapped() -> Void {
        NotificationCenter.default.post(name: .didCloseButtonTap, object: nil);
      }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size);
        if(UIDevice.current.userInterfaceIdiom == .pad){
            size.height = CGFloat(IPAD_PREVIEW_TOOLBAR_HEIGHT);
        }else{
           if(UIDevice.current.orientation.isPortrait){
                size.height = CGFloat(IPHONE_PREVIEW_TOOLBAR_HEIGHT_PORTRAIT);
            }else{
                size.height = CGFloat(IPHONE_PREVIEW_TOOLBAR_HEIGHT_LANDSCAPE);
            }
        }
        return size;
    }

     override func setItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        let labelTap = UITapGestureRecognizer(target: self, action: #selector(doneButtonTapped))
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 70));
        label.text = PreviewControllerToolbar.CLOSE_BUTTON_TEXT
            label.textAlignment = .left;
            label.sizeToFit();
            label.textColor = UIColor.systemBlue;
            label.isUserInteractionEnabled = true;
            label.addGestureRecognizer(labelTap)
        let doneButton = UIBarButtonItem(customView: label);
        super.setItems([doneButton], animated: true)
    }
    
}

@objc(HWPPreviewAnyFile) class PreviewAnyFile: CDVPlugin {
    lazy var previewItem = NSURL()
    lazy var tempCommandId = String()
    lazy  var previewNavigationController = PreviewNavigationController();
    @objc func didCloseButtonTap(_ notification: Notification)
    {
        self.viewController?.dismiss(animated: true, completion:nil);
        NotificationCenter.default.removeObserver(self, name: .didCloseButtonTap, object: nil);
    }

    
    @objc(preview:)
    func preview(_command: CDVInvokedUrlCommand){
   
        NotificationCenter.default.addObserver(self, selector: #selector(self.didCloseButtonTap), name: .didCloseButtonTap, object: nil);
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        tempCommandId = _command.callbackId;

        let myUrl = _command.arguments[0] as! String;
        let options = _command.arguments[1] as! NSDictionary;
        PreviewControllerToolbar.CLOSE_BUTTON_TEXT = options["closeButtonText"] != nil ?  options["closeButtonText"]  as! String : CLOSE_TEXT;
         self.downloadfile(withName: myUrl,fileName: "",completion: {(success, fileLocationURL, callback) in
            if success {
                self.previewItem = fileLocationURL! as NSURL
                let previewController = QLPreviewController();
                 previewController.dataSource = self;
                previewController.delegate = self;
                previewController.navigationItem.rightBarButtonItem = UIBarButtonItem();
                previewController.navigationItem.titleView = UIView();
                let previewNavigationController = PreviewNavigationController(navigationBarClass: nil, toolbarClass: PreviewControllerToolbar.self);
                previewNavigationController.setViewControllers([previewController], animated: false)
                previewNavigationController.modalPresentationStyle = .fullScreen;
                
                DispatchQueue.main.async(execute: {
                    self.viewController?.present(previewNavigationController, animated: true, completion: {});
                   
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
                let previewController = QLPreviewController();
                previewController.dataSource = self;
                previewController.delegate = self;
                DispatchQueue.main.async(execute: {
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
                let previewController = QLPreviewController();
                previewController.dataSource = self;
                previewController.delegate = self;
                DispatchQueue.main.async(execute: {
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
