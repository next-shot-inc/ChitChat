//
//  ViewController.swift
//  ChitChat
//
//  Created by next-shot on 3/6/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import UIKit

class ThemeCollectionViewCell : UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
}

class ThemesPickerSource : NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let themes = ["flowers", "clovers", "hearts", "music notes"]
    weak var controller: FancyTextViewController?
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themes.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThemeCollectionViewCell", for: indexPath) as! ThemeCollectionViewCell
        cell.label.text = themes[indexPath.item]
        
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 6
        cell.layer.borderColor = ColorPalette.colors[.borderColor]?.cgColor
        cell.layer.borderWidth = 1.0

        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        controller?.setTheme(string: themes[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing : CGFloat = 10
        
        let label = UILabel()
        label.text = themes[indexPath.item]
        label.font = UIFont.systemFont(ofSize: 17)
        
        let size = label.sizeThatFits(CGSize(width: 1000, height: 1500))
        return CGSize(width: size.width + spacing, height: size.height + spacing)
    }

}

class FancyTextViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var themeCollectionView: UICollectionView!
    @IBOutlet weak var textEditableView: UITextView!
    @IBOutlet weak var textView: DrawingTextView!
    
    var themePickerSource : ThemesPickerSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        themePickerSource = ThemesPickerSource()
        themeCollectionView.delegate = themePickerSource
        themeCollectionView.dataSource = themePickerSource
        themePickerSource?.controller = self
        
        textEditableView.delegate = self
        
        let tapper = UITapGestureRecognizer(target: self, action:#selector(endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setTheme(string: String) {
        var theme = DrawingTextView.theme.test
        if( string == "flowers" ) {
            theme = DrawingTextView.theme.flowers
        } else if( string == "clovers" ) {
            theme = DrawingTextView.theme.clover
        } else if( string == "hearts" ) {
            theme = DrawingTextView.theme.heart
        } else if ( string == "music notes" ) {
            theme = DrawingTextView.theme.musicnotes
        }
        textView.atheme = theme
        textView.setNeedsDisplay()
    }
    
    func textViewDidChange(_ view: UITextView) {
        textView.text = view.text
        textView.setNeedsDisplay()
    }
    
    func endEditing() {
        textEditableView.resignFirstResponder()
    }
}

