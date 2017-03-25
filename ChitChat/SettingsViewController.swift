//
//  SettingsViewController.swift
//  ChitChat
//
//  Created by next-shot on 3/23/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var weeksLabel: UILabel!
    @IBOutlet weak var dayStepper: UIStepper!
    @IBOutlet weak var bluePalette: UIButton!
    @IBOutlet weak var greenPalette: UIButton!
    @IBOutlet weak var redPallette: UIButton!
    @IBOutlet weak var curPalette: UIImageView!
    var buttons = [UIButton]()
    var images = ["palette_red", "palette_green", "palette_blue" ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Order of the palettes in ColorPalette
        buttons.append(redPallette)
        buttons.append(greenPalette)
        buttons.append(bluePalette)
        
        for b in buttons {
            b.layer.masksToBounds = true
            b.layer.cornerRadius = 4
            b.layer.borderColor = UIColor.darkGray.cgColor
            b.layer.borderWidth = 1.0
        }
        
        curPalette.image = UIImage(named: images[ColorPalette.cur])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func buttonSelection(button: UIButton) {
        button.isSelected = true
        button.isHighlighted = true
        for (i,b) in buttons.enumerated() {
            if( b != button ) {
                button.isHighlighted = false
                button.isSelected = false
            } else {
                ColorPalette.cur = i
                curPalette.image = UIImage(named: images[i])
            }
        }
    }
    
    @IBAction func blueButtonSelected(_ sender: UIButton) {
        buttonSelection(button: sender)
    }
    @IBAction func greenButtonSelected(_ sender: UIButton) {
        buttonSelection(button: sender)
    }
    @IBAction func redButtonSelected(_ sender: UIButton) {
        buttonSelection(button: sender)
    }
    
    @IBAction func weeksStepper(_ sender: UIStepper) {
        weeksLabel.text = String(Int(sender.value))
        model.setMessageFetchTimeLimit(numberOfDays: sender.value)
    }
}

