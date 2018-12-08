import UIKit
import SceneKit
import ARKit

import Vision

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBAction func captureFrame(_ sender: Any) {
        print("Frame captured")
        ///////////////////////////
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        print("Pixbuff Here : ")
        print(pixbuff ?? 0)
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        print(ciImage)
        var image = UIImage.init(ciImage: ciImage)
        print(image)
        
        if image.cgImage == nil {
            guard let ciImage = image.ciImage, let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else { return }
            
            image = UIImage(cgImage: cgImage)
        }
        print(image)
        
        
        let imageData = UIImageJPEGRepresentation(image, 1)
        let base64String = imageData!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
//        let imageData:Data =  UIImagePNGRepresentation(image)!
//        let base64String = imageData.base64EncodedString()
//        let imageData:NSData = UIImageJPEGRepresentation(image, 0.50) //UIImagePNGRepresentation(img)
//        let imgString = imageData.base64EncodedString(options: .init(rawValue: 0))
//        print(base64String)
//        let base64String = imageData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
//        print(base64String)
        //        let imageData = UIImagePNGRepresentation(image)
//        let data = imageData?.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
        
        
//        let todoEndpoint: String = "http://10.0.0.249:5000/classify"
//        guard let url = URL(string: todoEndpoint) else {
//            print("Error: cannot create URL")
//            return
//        }
//        let urlRequest = URLRequest(url: url)
//        let session = URLSession.shared
//        let task = session.dataTask(with: urlRequest) {
//            (data, response, error) in
//            // check for any errors
//            guard error == nil else {
//                print("error calling GET on /todos/1")
//                print(error!)
//                return
//            }
//            // make sure we got data
//            guard let responseData = data else {
//                print("Error: did not receive data")
//                return
//            }
//            // parse the result as JSON, since that's what the API provides
//            do {
//                guard let todo = try JSONSerialization.jsonObject(with: responseData, options: [])
//                    as? [String: Any] else {
//                        print("error trying to convert data to JSON")
//                        return
//                }
//                print(todo)
//                // now we have the todo
//                // let's just print it to prove we can access it
//                print("The todo is: " + todo.description)
//
//                // the todo object is a dictionary
//                // so we just access the title using the "title" key
//                // so check for a title and print it if we have one
//                guard let todoTitle = todo["title"] as? String else {
//                    print("Could not get todo title from JSON")
//                    return
//                }
//                print("The title is: " + todoTitle)
//            } catch  {
//                print("error trying to convert data to JSON")
//                return
//            }
//        }
//        task.resume()
        
//        let todosEndpoint: String = "http://10.0.0.249:5000/classify"
        let todosEndpoint: String = "http://10.201.21.63:5000/classify"
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
                
                let x = receivedTodo["x"] as! Float
                let y = receivedTodo["y"] as! Float
                let parsedText = receivedTodo["text"] as! String
                
                print(parsedText)
                print(x)
                print(y)
                
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
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
        
//        //////////////////////////////////////////////////
//        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        sceneView.addGestureRecognizer(tapGesture)
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(_:)))
//        tapGesture.numberOfTapsRequired = 1
//        tapGesture.numberOfTouchesRequired = 1
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didDoubleTapScreen))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(doubleTapRecognizer)
        
//        tapGesture.require(toFail: doubleTapRecognizer)
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        
//
//        //////////////////////////////////////////////////
//
//        // Set up Vision Model
//        guard let selectedModel = try? VNCoreMLModel(for: Inceptionv3().model) else { // (Optional) This can be replaced with other models on https://developer.apple.com/machine-learning/
//            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/ . Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
//        }
//
//        // Set up Vision-CoreML Request
//        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
//        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
//        visionRequests = [classificationRequest]
//
//        // Begin Loop to Update CoreML
//        loopCoreMLUpdate()
    }
    private func addAirPlane(hitTestResult: ARHitTestResult) {
        let scene = SCNScene(named: "art.scnassets/plane_banner.scn")!
        let planeNode = scene.rootNode.childNode(withName: "planeBanner", recursively: true)
        
        // 2.
        planeNode?.position = SCNVector3(hitTestResult.worldTransform.columns.3.x,hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
       planeNode?.scale = .init(0.005, 0.005, 0.005)
        
        // 3.
        let bannerNode = planeNode?.childNode(withName: "banner", recursively: true)
        
        // Find banner material and update its diffuse contents:
        let bannerMaterial = bannerNode?.geometry?.materials.first(where: { $0.name == "logo" })
        bannerMaterial?.diffuse.contents = UIImage(named: "next_reality_logo")
        
        // 4.
        self.sceneView.scene.rootNode.addChildNode(planeNode!)
    }
    
    private func onTextTap(node : SCNNode) {
       
        if !(node.childNodes.isEmpty) {
            let scnText = node.childNodes[0].geometry as? SCNText
            print(scnText?.string as Any)
            let text = scnText?.string as! String
            self.performSegue(withIdentifier: "textEditor", sender: text)
        }
        else{
            let scnText = node.geometry as? SCNText
            print(scnText?.string as Any)
            let text = scnText?.string as! String
            self.performSegue(withIdentifier: "textEditor", sender: text)
        }
        
    }
        
//    if let scnText = node.geometry as? SCNText {
//        print(scnText.string as Any)
//        }
//    else if let scnText = node.childNodes[0].geometry as? SCNText {
//            print(scnText.string as Any)
//        }
//    else{
//        print("invalid")
//        }
        
        
//        do {
//            let scnText = try node.childNodes[0].geometry
//            print(scnText.string as Any)
//            }
//        catch {
//            let scnText = node.geometry
//            print(scnText.string as Any)
//        }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "textEditor" {
            print("Preparing Segue")
            let textEditorVC = segue.destination as! textEditorViewController
            let text = sender as! String
            textEditorVC.text = text
        }
    }
    
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
        let planeNode = SCNNode(geometry: plane)
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
        planeNode.geometry?.firstMaterial?.isDoubleSided = true
        planeNode.position = textNode.position
        textNode.eulerAngles = planeNode.eulerAngles

        planeNode.addChildNode(textNode)
        
        return planeNode
    }
    
    
    private func addtextScreen(hitTestResult: ARHitTestResult,text: String) {
        let textNode = self.createTextNode(string: text)
//        textNode.position = SCNVector3Zero
        
//        self.sceneView.scene.rootNode.addChildNode(textNode)
        // 2.
        textNode.position = SCNVector3(hitTestResult.worldTransform.columns.3.x,hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
//        planeNode?.scale = .init(0.005, 0.005, 0.005)
        
        
        self.sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    private func tap_to_add_text(x : Float,y : Float,text : String) {
        let touchPosition = CGPoint(x:CGFloat(x),y:CGFloat(y))
        
        // 2.
        // Conduct a hit test based on a feature point that ARKit detected to find out what 3D point this 2D coordinate relates to
        let hitTestResult = self.sceneView?.hitTest(touchPosition, types: .featurePoint)
        
        // 3.
        if !(hitTestResult?.isEmpty)! {
            guard let hitResult = hitTestResult?.first else {
                return
            }
            print(hitResult.worldTransform.columns.3)
            addtextScreen(hitTestResult: hitResult,text: text)
        }
    }
    
    
    @objc func didTap(_ gesture :UIGestureRecognizer) {
//        print("Tapped")
        // Get exact position where touch happened on screen of iPhone (2D coordinate)
//        let touchPosition = recognizer.location(in: sceneView)
//
//        // 2.
//        // Conduct a hit test based on a feature point that ARKit detected to find out what 3D point this 2D coordinate relates to
//        let hitTestResult = sceneView.hitTest(touchPosition, types: .featurePoint)
//
//        // 3.
//        if !hitTestResult.isEmpty {
//            guard let hitResult = hitTestResult.first else {
//                return
//            }
//            print(hitResult.worldTransform.columns.3)
//            addPlane(hitTestResult: hitResult)
//
        let touchPosition = gesture.location(in: sceneView)
        let tappedNode = self.sceneView.hitTest(gesture.location(in: gesture.view), options: [:])
        
        if !tappedNode.isEmpty {
            guard tappedNode.first != nil else {
                return
            }
            onTextTap(node: tappedNode[0].node)
//            let node = tappedNode[0].node
//            print("Calling onTextTap")
//            onTextTap(node: node)
        } else {
            print(touchPosition)
            return
            
        }
        
    }
    
    @objc func didDoubleTapScreen(_ recognizer :UIGestureRecognizer) {
                print("Double Tapped")
                let touchPosition = recognizer.location(in: sceneView)
        
                // 2.
                // Conduct a hit test based on a feature point that ARKit detected to find out what 3D point this 2D coordinate relates to
                let hitTestResult = sceneView.hitTest(touchPosition, types: .featurePoint)
        
                // 3.
                if !hitTestResult.isEmpty {
                    guard let hitResult = hitTestResult.first else {
                        return
                    }
                    print(hitResult.worldTransform.columns.3)
                    addAirPlane(hitTestResult: hitResult)
        //
        
        
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
        return true
    }
    
    // MARK: - Interaction
    
//    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
//        // HIT TEST : REAL WORLD
//        // Get Screen Centre
//        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
//
//        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
//
//        if let closestResult = arHitTestResults.first {
//            // Get Coordinates of HitTest
//            let transform : matrix_float4x4 = closestResult.worldTransform
//            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
//
//            // Create 3D Text
//            let node : SCNNode = createNewBubbleParentNode(latestPrediction)
//            sceneView.scene.rootNode.addChildNode(node)
//            node.position = worldCoord
//        }
//    }
    
//    func createNewBubbleParentNode(_ text : String) -> SCNNode {
//        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
//
//        // TEXT BILLBOARD CONSTRAINT
//        let billboardConstraint = SCNBillboardConstraint()
//        billboardConstraint.freeAxes = SCNBillboardAxis.Y
//
//        // BUBBLE-TEXT
//        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
//        var font = UIFont(name: "Futura", size: 0.15)
//        font = font?.withTraits(traits: .traitBold)
//        bubble.font = font
//        bubble.alignmentMode = kCAAlignmentCenter
//        bubble.firstMaterial?.diffuse.contents = UIColor.orange
//        bubble.firstMaterial?.specular.contents = UIColor.white
//        bubble.firstMaterial?.isDoubleSided = true
//        // bubble.flatness // setting this too low can cause crashes.
//        bubble.chamferRadius = CGFloat(bubbleDepth)
//
//        // BUBBLE NODE
//        let (minBound, maxBound) = bubble.boundingBox
//        let bubbleNode = SCNNode(geometry: bubble)
//        // Centre Node - to Centre-Bottom point
//        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
//        // Reduce default text size
//        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
//
//        // CENTRE POINT NODE
//        let sphere = SCNSphere(radius: 0.005)
//        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
//        let sphereNode = SCNNode(geometry: sphere)
//
//        // BUBBLE PARENT NODE
//        let bubbleNodeParent = SCNNode()
//        bubbleNodeParent.addChildNode(bubbleNode)
//        bubbleNodeParent.addChildNode(sphereNode)
//        bubbleNodeParent.constraints = [billboardConstraint]
//
//        return bubbleNodeParent
//    }
//
//    // MARK: - CoreML Vision Handling
//
//    func loopCoreMLUpdate() {
//        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
//
//        dispatchQueueML.async {
//            // 1. Run Update.
//            self.updateCoreML()
//
//            // 2. Loop this function.
//            self.loopCoreMLUpdate()
//        }
//
//    }
//
//    func classificationCompleteHandler(request: VNRequest, error: Error?) {
//        // Catch Errors
//        if error != nil {
//            print("Error: " + (error?.localizedDescription)!)
//            return
//        }
//        guard let observations = request.results else {
//            print("No results")
//            return
//        }
//
//        // Get Classifications
//        let classifications = observations[0...1] // top 2 results
//            .flatMap({ $0 as? VNClassificationObservation })
//            .map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
//            .joined(separator: "\n")
//
//
//        DispatchQueue.main.async {
//            // Print Classifications
//            print(classifications)
//            print("--")
//
//            // Display Debug Text on screen
//            var debugText:String = ""
//            debugText += classifications
//            self.debugTextView.text = debugText
//
//            // Store the latest prediction
//            var objectName:String = "…"
//            objectName = classifications.components(separatedBy: "-")[0]
//            objectName = objectName.components(separatedBy: ",")[0]
//            self.latestPrediction = objectName
//
//        }
//    }
//
//    func updateCoreML() {
//        ///////////////////////////
//        // Get Camera Image as RGB
//        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
//        if pixbuff == nil { return }
//        print("Pixbuff Here : ")
//        print(pixbuff ?? 0)
//        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
//        print(ciImage)
//        // Note: Not entirely sure if the ciImage is being interpreted as RGB, but for now it works with the Inception model.
//        // Note2: Also uncertain if the pixelBuffer should be rotated before handing off to Vision (VNImageRequestHandler) - regardless, for now, it still works well with the Inception model.
//
//        ///////////////////////////
//        // Prepare CoreML/Vision Request
//        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
//        // let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: myOrientation, options: [:]) // Alternatively; we can convert the above to an RGB CGImage and use that. Also UIInterfaceOrientation can inform orientation values.
//
//        ///////////////////////////
//        // Run Image Request
//        do {
//            try imageRequestHandler.perform(self.visionRequests)
//        } catch {
//            print(error)
//        }
//
//    }
}

//extension UIFont {
//    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
//    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
//        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
//        return UIFont(descriptor: descriptor!, size: 0)
//    }
//}
