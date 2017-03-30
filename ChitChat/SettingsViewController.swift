//
//  SettingsViewController.swift
//  ChitChat
//
//  Created by next-shot on 3/23/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

struct Settings {
    var nb_of_days_to_fetch = 5
    var nb_of_days_to_keep = 10
    var palette = 0
}

class SettingsDB {
    var settings = Settings()
    
    let keyStore : NSUbiquitousKeyValueStore?
    init() {
        keyStore = NSUbiquitousKeyValueStore()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(SettingsDB.ubiquitousKeyValueStoreDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: keyStore
        )
    }
    
    @objc func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        // Update local values
    }
    
    func get() {
        let nb_of_days_to_fetch = keyStore?.double(forKey: "nb_of_days_to_fetch")
        if( nb_of_days_to_fetch != nil && nb_of_days_to_fetch! > 0 ) {
            settings.nb_of_days_to_fetch = Int(nb_of_days_to_fetch!)
        }
        
        let nb_of_days_to_keep = keyStore?.double(forKey: "nb_of_days_to_keep")
        if( nb_of_days_to_keep != nil && nb_of_days_to_keep! > 0 ) {
            settings.nb_of_days_to_keep = Int(nb_of_days_to_keep!)
        }
        
        let palette = keyStore?.double(forKey: "color_palette_index")
        if( palette != nil ) {
            settings.palette = Int(palette!)
        }

    }
    
    func put() {
        guard let keyStore = self.keyStore else { return }
        keyStore.set(Double(settings.nb_of_days_to_fetch), forKey: "nb_of_days_to_fetch")
        keyStore.set(Double(settings.nb_of_days_to_keep), forKey: "nb_of_days_to_keep")
        keyStore.set(Double(settings.palette), forKey: "color_palette_index")
        keyStore.synchronize()
    }
}

let settingsDB = SettingsDB()

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var displayDaysLabel: UILabel!
    @IBOutlet weak var displayDaysStepper: UIStepper!
    @IBOutlet weak var bluePalette: UIButton!
    @IBOutlet weak var greenPalette: UIButton!
    @IBOutlet weak var redPallette: UIButton!
    @IBOutlet weak var curPalette: UIImageView!
    @IBOutlet weak var keepDaysLabel: UILabel!
    @IBOutlet weak var keepDaysStepper: UIStepper!
    
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
        
        settingsDB.get()
        ColorPalette.cur = settingsDB.settings.palette
        displayDaysStepper.value = Double(settingsDB.settings.nb_of_days_to_fetch)
        displayDaysLabel.text = String(settingsDB.settings.nb_of_days_to_fetch)
        keepDaysStepper.value = Double(settingsDB.settings.nb_of_days_to_keep)
        keepDaysLabel.text = String(settingsDB.settings.nb_of_days_to_keep)
        
        curPalette.image = UIImage(named: images[ColorPalette.cur])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        settingsDB.put()
    }
    
    func buttonSelection(button: UIButton) {
        button.isSelected = true
        button.isHighlighted = true
        for (i,b) in buttons.enumerated() {
            if( b != button ) {
                button.isHighlighted = false
                button.isSelected = false
            } else {
                settingsDB.settings.palette = i
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
    
    @IBAction func displayDaysStepper(_ sender: UIStepper) {
        displayDaysLabel.text = String(Int(sender.value))
        
        model.setMessageFetchTimeLimit(numberOfDays: sender.value)
        
        settingsDB.settings.nb_of_days_to_fetch = Int(sender.value)
        
        keepDaysStepper.minimumValue = max(10, sender.value + 1)
        if( settingsDB.settings.nb_of_days_to_keep  <= Int(sender.value) ) {
            keepDaysStepper.value = sender.value + 1
            keepDaysLabel.text = String(Int(sender.value + 1))
            settingsDB.settings.nb_of_days_to_keep  = Int(sender.value + 1)
        }
    }
    
    @IBAction func keepDaysStepper(_ sender: UIStepper) {
        keepDaysLabel.text = String(Int(sender.value))
        
        settingsDB.settings.nb_of_days_to_keep = Int(sender.value)
    }
}

