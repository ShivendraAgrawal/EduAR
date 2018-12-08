//
//  textEditorViewController.swift
//  CoreML in ARKit
//
//  Created by Shivendra Agrawal on 08/12/18.
//  Copyright © 2018 CompanyName. All rights reserved.
//

import UIKit

class textEditorViewController: UIViewController {
    
    var text:String = ""
    @IBOutlet weak var textArea: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        textArea.text = text
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
