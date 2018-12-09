//
//  textEditorViewController.swift
//  CoreML in ARKit
//
//  Created by Shivendra Agrawal on 08/12/18.
//  Copyright © 2018 CompanyName. All rights reserved.
//

import UIKit

class textEditorViewController: UIViewController {
    
    var index_sentence:Int = 0
    var index_word:Int = 0
    var n_word:Int = 0
    var n_sentence:Int = 0
    var text:String = ""
    var words2:[String] = []
    var sentences2:[String] = []
    var pickerData: [String] = [String]()
    
    @IBOutlet weak var textArea: UITextView!
    @IBOutlet weak var picker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("Setting text")
        textArea.text = text
        // Connect data:
        self.picker.delegate = self as? UIPickerViewDelegate
        self.picker.dataSource = self as? UIPickerViewDataSource
        pickerData = ["Paragraph", "Sentence", "Word"]
        
        // Setting up the words and sentences
        
        //        let words = text.components(separatedBy: " ")
        let local_words2 = text.split(separator: " ")
        n_word = local_words2.count
        var i = 0
        while i < n_word {
            words2.append(String(local_words2[i]))
            i = i + 1
        }
        print(words2)
        print(n_word)
        
        let local_sentences2 = text.split(separator: ".")
        n_sentence = local_sentences2.count
        i = 0
        while i < n_sentence {
            sentences2.append(String(local_sentences2[i]))
            i = i + 1
        }
        print(sentences2)
        print(n_sentence)
        
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
    }
    
    @objc func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        
        if (sender.direction == .left) {
            print("Swipe Left")
            
            //            let labelPosition = CGPoint(x: self.swipeLabel.frame.origin.x - 50.0, y: self.swipeLabel.frame.origin.y)
            //            swipeLabel.frame = CGRect(x: labelPosition.x, y: labelPosition.y, width: self.swipeLabel.frame.size.width, height: self.swipeLabel.frame.size.height)
        }
        
        if (sender.direction == .right) {
            print("Swipe Right")
            //            let labelPosition = CGPoint(x: self.swipeLabel.frame.origin.x + 50.0, y: self.swipeLabel.frame.origin.y)
            //            swipeLabel.frame = CGRect(x: labelPosition.x, y: labelPosition.y, width: self.swipeLabel.frame.size.width, height: self.swipeLabel.frame.size.height)
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        // Column count: use one column.
        return 1
    }
    
    func pickerView(pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        
        // Row count: rows equals array length.
        return pickerData.count
    }
    
    func pickerView(pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        
        // Return a string from the array for this row.
        return pickerData[row]
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
