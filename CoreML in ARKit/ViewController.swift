import UIKit
import SceneKit
import ARKit

import Vision

class ViewController: UIViewController, ARSCNViewDelegate {
    
    //Store The Rotation Of The CurrentNode
    var currentAngleY: Float = 0.0
    
    //Not Really Necessary But Can Use If You Like
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
        
        // Show statistics such as fps and timing information
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
        
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didDoubleTapScreen))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(doubleTapRecognizer)
        
//        tapGesture.require(toFail: doubleTapRecognizer)
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(moveNode))
//        self.view.addGestureRecognizer(panGesture)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
    }
//    private func addAirPlane(hitTestResult: ARHitTestResult) {
    private func addAirPlane(anchor : ARAnchor) {
//        let scene = SCNScene(named: "art.scnassets/traesure/treasure.scn")!
//        objectNode = scene.rootNode.childNode(withName: "treasure", recursively: true)
        let scene = SCNScene(named: "art.scnassets/"+self.objectFound+"/"+self.objectFound+".scn")!
        objectNode = scene.rootNode.childNode(withName: self.objectFound, recursively: true)
       
        // 2.
//        planeNode?.position = SCNVector3(hitTestResult.worldTransform.columns.3.x,hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
       objectNode?.position = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
       objectNode?.scale = .init(0.03, 0.03, 0.03)
        
        // 3.
//        let bannerNode = planeNode?.childNode(withName: "banner", recursively: true)
//
//        // Find banner material and update its diffuse contents:
//        let bannerMaterial = bannerNode?.geometry?.materials.first(where: { $0.name == "logo" })
//        bannerMaterial?.diffuse.contents = UIImage(named: "next_reality_logo")
        
        // 4.
        self.sceneView.scene.rootNode.addChildNode(objectNode!)
//        moveNode(_ gesture: UIPanGestureRecognizer,currentNode:planeNode)
    }
    
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
//            let text = "Touch the Text"
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
            let cleanedText = text.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: ":", with: ".")
            textEditorVC.text = cleanedText
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
        let planeNode1 = SCNNode(geometry: plane)
        planeNode1.geometry?.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
        planeNode1.geometry?.firstMaterial?.isDoubleSided = true
        planeNode1.position = textNode.position
        textNode.eulerAngles = planeNode1.eulerAngles

        planeNode1.addChildNode(textNode)
        
        return planeNode1
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
    
    
    @objc func didTap(rec :UITapGestureRecognizer) {
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
        if rec.state == .ended {
        let touchPosition = rec.location(in: sceneView)
//        let tappedNode = self.sceneView.hitTest(gesture.location(in: gesture.view), options: [:])
        let hits = self.sceneView.hitTest(touchPosition, options: nil)
//        if !tappedNode.isEmpty {
//            let node = tappedNode[0].node
//            print("Calling onTextTap")
//            onTextTap(node: node)
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
    
    @objc func didDoubleTapScreen(_ recognizer :UIGestureRecognizer) {
                print("Double Tapped")
                let touchPosition = recognizer.location(in: sceneView)

                // 2.
                // Conduct a hit test based on a feature point that ARKit detected to find out what 3D point this 2D coordinate relates to
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
            addAirPlane(anchor : anchor)
        }
        
    }
    
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
    
//    /// Rotates An Object On It's YAxis
//    ///
//    /// - Parameter gesture: UIPanGestureRecognizer
//    @objc func moveNode(_ gesture: UIPanGestureRecognizer) {
//
//        if !isRotating{
//
//            //1. Get The Current Touch Point
//            let currentTouchPoint = gesture.location(in: sceneView)
//
//            //2. Get The Next Feature Point Etc
//            let hitTestResult = sceneView.hitTest(currentTouchPoint, types: .featurePoint)
//            if !hitTestResult.isEmpty {
//
//                print("hit result")
//
//                guard let hitResult = hitTestResult.first else {
//                    return
//                }
//
//                let node = hitTestResult.node
//            //3. Convert To World Coordinates
//            let worldTransform = hitResult.worldTransform
//
//            //4. Set The New Position
//            let newPosition = SCNVector3(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
////
//            //5. Apply To The Node
//            node!.simdPosition = float3(newPosition.x, newPosition.y, newPosition.z)
//            }
//        }
//    }
    
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
