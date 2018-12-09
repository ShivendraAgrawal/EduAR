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
    var selected_mode:String = ""
    
    @IBOutlet weak var textArea: UITextView!
    @IBOutlet weak var paragraphButtonOutlet: UIButton!
    @IBOutlet weak var sentenceButtonOutlet: UIButton!
    @IBOutlet weak var wordButtonOutlet: UIButton!
    @IBOutlet weak var instructionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        paragraphButtonOutlet.isEnabled = false
        self.selected_mode = "Paragraph"
        instructionLabel.text = "Tap or long press the text for more options"
        
        // Do any additional setup after loading the view.
        print("Setting text")
        textArea.text = text
        
        // Setting up the words and sentences
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
            
            if (self.selected_mode == "Sentence"){
                self.index_sentence = self.index_sentence + 1
                if (self.index_sentence == self.n_sentence){
                    self.index_sentence = self.index_sentence - 1
                }
                textArea.text = sentences2[self.index_sentence]
            }
            else if (self.selected_mode == "Word"){
                self.index_word = self.index_word + 1
                if (self.index_word == self.n_word){
                    self.index_word = self.index_word - 1
                }
                textArea.text = words2[self.index_word]
            }
            else {
                print("Swipe Left")
            }
        }
        
        if (sender.direction == .right) {
            
            if (self.selected_mode == "Sentence"){
                self.index_sentence = self.index_sentence - 1
                if (self.index_sentence == -1){
                    self.index_sentence = 0
                }
                textArea.text = sentences2[self.index_sentence]
            }
            else if (self.selected_mode == "Word"){
                self.index_word = self.index_word - 1
                if (self.index_word == -1){
                    self.index_word = 0
                }
                textArea.text = words2[self.index_word]
            }
            else {
                print("Swipe Right")
            }
            
            //            let labelPosition = CGPoint(x: self.swipeLabel.frame.origin.x + 50.0, y: self.swipeLabel.frame.origin.y)
            //            swipeLabel.frame = CGRect(x: labelPosition.x, y: labelPosition.y, width: self.swipeLabel.frame.size.width, height: self.swipeLabel.frame.size.height)
        }
    }
    
    @IBAction func paragraphButton(_ sender: Any) {
        paragraphButtonOutlet.isEnabled = false
        sentenceButtonOutlet.isEnabled = true
        wordButtonOutlet.isEnabled = true
        self.selected_mode = "Paragraph"
        print(self.selected_mode)
        self.textArea.text = self.text
        self.instructionLabel.text = "Tap or long press the text for more options"
    }
    
    @IBAction func sentenceButton(_ sender: Any) {
        paragraphButtonOutlet.isEnabled = true
        sentenceButtonOutlet.isEnabled = false
        wordButtonOutlet.isEnabled = true
        self.selected_mode = "Sentence"
        print(self.selected_mode)
        self.textArea.text = sentences2[self.index_sentence]
        self.instructionLabel.text = "Swipe left or right for next sentence"
    }
    
    @IBAction func wordButton(_ sender: Any) {
        paragraphButtonOutlet.isEnabled = true
        sentenceButtonOutlet.isEnabled = true
        wordButtonOutlet.isEnabled = false
        self.selected_mode = "Word"
        print(self.selected_mode)
        self.textArea.text = words2[self.index_word]
        self.instructionLabel.text = "Swipe left or right for next word"
    }
    
    @IBAction func decreaseFontSize(_ sender: Any) {
        textArea.font = UIFont(name: (textArea.font?.fontName)!, size: (textArea.font?.pointSize)! - 1)!
    }
    
    @IBAction func increaseFontSize(_ sender: Any) {
        textArea.font = UIFont(name: (textArea.font?.fontName)!, size: (textArea.font?.pointSize)! + 1)!
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
