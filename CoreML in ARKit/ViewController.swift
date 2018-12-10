import UIKit
import SceneKit
import ARKit

import Vision

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var currentAngleY: Float = 0.0
    
    var isRotating = false
    var objectFound:String = ""
    
    var objectNode: SCNNode!
    
    @IBAction func captureFrame(_ sender: Any) {
        print("Frame captured")
        ///////////////////////////
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        print("Pixbuff Here : ")
        print(pixbuff ?? 0)
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        var image = UIImage.init(ciImage: ciImage)
        
        if image.cgImage == nil {
            guard let ciImage = image.ciImage, let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else { return }
            
            image = UIImage(cgImage: cgImage)
        }
        
        let imageData = UIImageJPEGRepresentation(image, 1)
        let base64String = imageData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        
        let todosEndpoint: String = "http://10.0.0.249:5000/classify"
//        let todosEndpoint: String = "http://10.201.21.63:5000/classify"
        guard let todosURL = URL(string: todosEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        var todosUrlRequest = URLRequest(url: todosURL)
        todosUrlRequest.httpMethod = "POST"
        let newTodo: [String: Any] = ["arg1": 1, "image": base64String as Any]
        let jsonTodo: Data
        do {
            jsonTodo = try JSONSerialization.data(withJSONObject: newTodo, options: [])
            todosUrlRequest.httpBody = jsonTodo
        } catch {
            print("Error: cannot create JSON from todo")
            return
        }
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: todosUrlRequest) {
            (data, response, error) in
            guard error == nil else {
                print("error calling POST on /todos/1")
                print(error as Any)
                return
            }
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            
            // parse the result as JSON, since that's what the API provides
            do {
                guard let receivedTodo = try JSONSerialization.jsonObject(with: responseData,
                                                                          options: []) as? [String: Any] else {
                                                                            print("Could not get JSON from responseData as dictionary")
                                                                            return
                }
                // x,y corresponds to a point within the parsed text bounding box
                // parsedText is the text string which had been detected by our OCR algorithm
                // objectFound is the object which is been mentioned in the text
                let x = receivedTodo["x"] as! Float
                let y = receivedTodo["y"] as! Float
                let parsedText = receivedTodo["text"] as! String
                self.objectFound = receivedTodo["object"] as! String
                print(parsedText)
                print(x)
                print(y)
                print(self.objectFound)
                self.tap_to_add_text(x: x,y: y,text: parsedText)
            } catch  {
                print("error parsing response from POST on /todos")
                return
            }
        }
        task.resume()
        
    }
    
    

    // SCENE
    @IBOutlet var sceneView: ARSCNView!
    let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
    var latestPrediction : String = "…" // a variable containing the latest CoreML prediction
    
    // COREML
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    @IBOutlet weak var debugTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
        
        //////////////////////////////////////////////////
        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Double Tap Gesture Recognizer
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didDoubleTapScreen))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(doubleTapRecognizer)
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Pan Gesture Recognizer (only rotating the object)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        // Pinch Gesture Recognizer
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
    }

    // function to add object on double tap
    private func addObject(anchor : ARAnchor) {
//        let scene = SCNScene(named: "art.scnassets/traesure/treasure.scn")!
//        objectNode = scene.rootNode.childNode(withName: "treasure", recursively: true)
        
        
            let scene = SCNScene(named: "art.scnassets/"+self.objectFound+"/"+self.objectFound+".scn")!
            objectNode = scene.rootNode.childNode(withName: self.objectFound, recursively: true)
        
        
       
//        planeNode?.position = SCNVector3(hitTestResult.worldTransform.columns.3.x,hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
       objectNode?.position = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
       objectNode?.scale = .init(0.03, 0.03, 0.03)
        
        self.sceneView.scene.rootNode.addChildNode(objectNode!)

    }
    
    // function to pass the string from the 3D node on single tap
    private func onTextTap(node : SCNNode) {
      
//        if !(node.childNodes.isEmpty) {
//            let scnText = node.childNodes[0].geometry as! SCNText
//                print(scnText.string as Any)
//                let text = scnText.string as! String
//                self.performSegue(withIdentifier: "textEditor", sender: text)
//
//
//        }
//        else{
//            let scnText = node.geometry as? SCNText
//            print(scnText?.string as Any)
//            let text = "Touch the Box"
//            //The line above is the hack
//            self.performSegue(withIdentifier: "textEditor", sender: text)
//        }
//
        if let scnText = node.geometry as? SCNText{
            print(scnText.string as Any)
            let text = scnText.string as! String
            self.performSegue(withIdentifier: "textEditor", sender: text)
            
        }
        
    }
        

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "textEditor" {
            print("Preparing Segue")
            let textEditorVC = segue.destination as! textEditorViewController
            let text = sender as! String
            let cleanedText = text.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: ":", with: ".")
            textEditorVC.text = cleanedText
        }
    }
    
    // create a 3D node to display text
    func createTextNode(string: String) -> SCNNode {
        let text = SCNText(string: string, extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1.0)
        text.flatness = 0.01
        text.firstMaterial?.diffuse.contents = UIColor.red
        
        let textNode = SCNNode(geometry: text)
        
        let fontSize = Float(0.04)
        textNode.scale = SCNVector3(fontSize, fontSize, fontSize)
        
        let (min, max) = (text.boundingBox.min, text.boundingBox.max)
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)

        let width = (max.x - min.x) * fontSize
        let height = (max.y - min.y) * fontSize
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        let planeNode1 = SCNNode(geometry: plane)
        planeNode1.geometry?.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
        planeNode1.geometry?.firstMaterial?.isDoubleSided = true
        planeNode1.position = textNode.position
        textNode.eulerAngles = planeNode1.eulerAngles

        planeNode1.addChildNode(textNode)
        
        return planeNode1
    }
    
    // create function to display 3D text once we've captured the text with the camera
    private func addtextScreen(hitTestResult: ARHitTestResult,text: String) {
        let textNode = self.createTextNode(string: text)

        textNode.position = SCNVector3(hitTestResult.worldTransform.columns.3.x,hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
//        planeNode?.scale = .init(0.005, 0.005, 0.005)
        
        
        self.sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    // find the 3D location corresponding to the 2D x,y coordinate returned from API
    private func tap_to_add_text(x : Float,y : Float,text : String) {
        let touchPosition = CGPoint(x:CGFloat(x),y:CGFloat(y))
        
        let hitTestResult = self.sceneView?.hitTest(touchPosition, types: .featurePoint)
        
        if !(hitTestResult?.isEmpty)! {
            guard let hitResult = hitTestResult?.first else {
                return
            }
            print(hitResult.worldTransform.columns.3)
            addtextScreen(hitTestResult: hitResult,text: text)
        }
    }
    
    // function to see what does single tap on the 3D text do (it calls onTextTap)
    @objc func didTap(rec :UITapGestureRecognizer) {

        if rec.state == .ended {
        let touchPosition = rec.location(in: sceneView)
//        let tappedNode = self.sceneView.hitTest(gesture.location(in: gesture.view), options: [:])
        let hits = self.sceneView.hitTest(touchPosition, options: nil)

        if !hits.isEmpty{
            if let tappednode = hits.first?.node {
                //do something with tapped object
                onTextTap(node: tappednode)
             }
           
        }
        else {
            print(touchPosition)
            return
            
            }
      
        }
        
    }
    
    // pinch as an object interation to zoom in and zoom out the objects
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let _ = objectNode else { return }
        var originalScale = objectNode?.scale
        
        switch gesture.state {
        case .began:
            originalScale = objectNode?.scale
            gesture.scale = CGFloat((objectNode?.scale.x)!)
        case .changed:
            guard var newScale = originalScale else { return }
            if gesture.scale < 0.01{ newScale = SCNVector3(x: 0.01, y: 0.01, z: 0.01) }else if gesture.scale > 2{
                newScale = SCNVector3(2, 2, 2)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            objectNode?.scale = newScale
        case .ended:
            guard var newScale = originalScale else { return }
            if gesture.scale < 0.01{ newScale = SCNVector3(x: 0.01, y: 0.01, z: 0.01) }else if gesture.scale > 2{
                newScale = SCNVector3(2, 2, 2)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            objectNode?.scale = newScale
            gesture.scale = CGFloat((objectNode?.scale.x)!)
        default:
            gesture.scale = 1.0
            originalScale = nil
        }
    }
    
    func adjustUITextViewHeight(arg : UITextView)
    {
        arg.translatesAutoresizingMaskIntoConstraints = true
        arg.sizeToFit()
        arg.isScrollEnabled = false
//        arg.isEditable = false
    }
    
    func increaseFontSize (arg : UITextView) {
        arg.font =  UIFont(name: arg.font!.fontName, size: arg.font!.pointSize+4)!
    }
//    var isEditable: Bool { return false }
    
    // function to call addObject when double tapped, it also anchors the object on a plane
    @objc func didDoubleTapScreen(_ recognizer :UIGestureRecognizer) {
                print("Double Tapped")
                let touchPosition = recognizer.location(in: sceneView)

//                let hitTestResult = sceneView.hitTest(touchPosition, types: .featurePoint)
//
//                // 3.
//                if !hitTestResult.isEmpty {
//                    guard let hitResult = hitTestResult.first else {
//                        return
//                    }
//                    print(hitResult.worldTransform.columns.3)
//                    addAirPlane(hitTestResult: hitResult)
//        //
//
//
//        }
        let planeHitTestResults = self.sceneView.hitTest(touchPosition, types: .existingPlaneUsingExtent)

        if let result = planeHitTestResults.first {
            //2. Create An Anchor At The World Transform
            let anchor = ARAnchor(transform: result.worldTransform)
            
            //3. Add It To The Scene
            sceneView.session.add(anchor:anchor)
            addObject(anchor : anchor)
        }
        
    }
    
    // another object interaction to rotate the object
    @objc
    func didPan(_ gesture: UIPanGestureRecognizer) {
        guard let _ = objectNode else { return }
        let translation = gesture.translation(in: gesture.view)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
        
        newAngleY += currentAngleY
        objectNode?.eulerAngles.y = newAngleY
        
        if gesture.state == .ended{
            currentAngleY = newAngleY
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Enable plane detection
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // Do any desired updates to SceneKit here.
        }
    }
    
    // MARK: - Status Bar: Hide
    override var prefersStatusBarHidden : Bool {
        return false
    }
}
