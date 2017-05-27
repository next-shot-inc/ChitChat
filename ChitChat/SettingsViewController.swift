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
    var purchased_something = false
}

// Store user settings for the application behavior in the cloud key-value store.
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

        let purchased_something = keyStore?.bool(forKey: "purchased_something")
        if( purchased_something != nil ) {
            settings.purchased_something = purchased_something!
        }
    }
    
    func put() {
        guard let keyStore = self.keyStore else { return }
        keyStore.set(Double(settings.nb_of_days_to_fetch), forKey: "nb_of_days_to_fetch")
        keyStore.set(Double(settings.nb_of_days_to_keep), forKey: "nb_of_days_to_keep")
        keyStore.set(Double(settings.palette), forKey: "color_palette_index")
        keyStore.set(Bool(settings.purchased_something), forKey: "purchased_something")
        keyStore.synchronize()
    }
}

class SettingsInAppPurchaseView : InApppurchaseView {
    weak var ctrler: SettingsViewController?
    init(ctrler: SettingsViewController) {
        self.ctrler = ctrler
    }
    override func did_purchase() {
        settingsDB.settings.purchased_something = true
        if( ctrler != nil ) {
            ctrler!.initPurchaseZone()
        }
    }
}

let settingsDB = SettingsDB()

class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var displayDaysLabel: UILabel!
    @IBOutlet weak var displayDaysStepper: UIStepper!
    @IBOutlet weak var choosePaletteButton: UIButton!
    
    @IBOutlet weak var keepDaysLabel: UILabel!
    @IBOutlet weak var keepDaysStepper: UIStepper!
    @IBOutlet weak var iconButton: UIButton!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var IAPProductLabel: UILabel!
    @IBOutlet weak var IAPProductDesc: UILabel!
    @IBOutlet weak var IAPProductPrice: UILabel!
    @IBOutlet weak var purchaseButton: UIButton!
    @IBOutlet weak var restorePurchaseButton: UIButton!
    @IBOutlet weak var maximumKeepDaysLabel: UILabel!
    
    var changedIcon = false
    var iapView : SettingsInAppPurchaseView?
    let defaultMaximumKeepDays = 20
    let increaseNbDaysWithX2 = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Order of the palettes in ColorPalette
        
        settingsDB.get()
        ColorPalette.cur = settingsDB.settings.palette
        displayDaysStepper.value = Double(settingsDB.settings.nb_of_days_to_fetch)
        displayDaysLabel.text = String(settingsDB.settings.nb_of_days_to_fetch)
        keepDaysStepper.value = Double(settingsDB.settings.nb_of_days_to_keep)
        keepDaysLabel.text = String(settingsDB.settings.nb_of_days_to_keep)
        keepDaysStepper.maximumValue = Double(defaultMaximumKeepDays)
        displayDaysStepper.maximumValue = keepDaysStepper.maximumValue-1
        
        let colorPaletteView = ColorPaletteUIView()
        let image = colorPaletteView.generateImage(rect: CGRect(x: 0, y: 0, width: choosePaletteButton.frame.width, height: choosePaletteButton.frame.height))
        choosePaletteButton.setImage(image, for: .normal)
        
        if( model.me().icon != nil ) {
            iconButton.setImage(model.me().icon, for: .normal)
        }
        userNameTextField.text = model.me().label
        
        let tapper = UITapGestureRecognizer(target: self, action:#selector(endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)
        
        maximumKeepDaysLabel.text = "maximum: \(defaultMaximumKeepDays) days"
        initPurchaseZone()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        settingsDB.put()
        
        var modifyUser = false
        let user = model.me()
        if( changedIcon ) {
            user.icon = iconButton.image(for: .normal)
            modifyUser = true
        }
        if( user.label != userNameTextField.text ) {
            user.label = userNameTextField.text
            modifyUser = true
        }
        if( modifyUser ) {
            model.saveUser(user: user, completion: {_ in })
        }
        
        if( iapView != nil ) {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let iap = appDelegate.IAPHelper!
            iap.removeView(view: iapView!)
        }
    }
    
    func initPurchaseZone() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        if( appDelegate.IAPHelper!.products.count >= 1 ) {
            let iap = appDelegate.IAPHelper!
            let p = iap.products[0]
            IAPProductLabel.text = p.title
            IAPProductDesc.text = p.description
            let nf = NumberFormatter()
            nf.numberStyle = .currencyAccounting
            IAPProductPrice.text = nf.string(from: p.price)
            
            purchaseButton.isEnabled = true
            
            if( settingsDB.settings.purchased_something ) {
                iap.verifyReceipt()
                if( p.purchased == true ) {
                    purchaseButton.isEnabled = false
                    purchaseButton.setTitle("Already purchased", for: .normal)
                    if( p.productIdentifier == Products.Id.X2.rawValue ) {
                        keepDaysStepper.maximumValue = Double(defaultMaximumKeepDays+increaseNbDaysWithX2)
                        displayDaysStepper.maximumValue = keepDaysStepper.maximumValue - 1
                        maximumKeepDaysLabel.text = "maximum: \(defaultMaximumKeepDays+increaseNbDaysWithX2) days"
                    }
                }
                if( p.expired ) {
                    purchaseButton.setTitle("Renew subscription", for: .normal)
                }
            }
            
            restorePurchaseButton.isEnabled = true
        }
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
    
    // Image picker
    func imagePickerController(
        _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]
    ) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let imageSize = chosenImage.size
        let sx = 32/imageSize.width
        let sy = 32/imageSize.height
        let sc = min(sx, sy)
        let imageScaledSize = CGSize(width: imageSize.width*sc, height: imageSize.height*sc)
        
        let ciImage  = CIImage(cgImage: chosenImage.cgImage!)
        let ciDetector = CIDetector( ofType: CIDetectorTypeFace,context:CIContext() ,options: [
                CIDetectorAccuracy:CIDetectorAccuracyHigh
            ]
        )
        let features = ciDetector?.features(in: ciImage)
        if( features != nil && features!.count > 0 ) {
            var center = CGPoint.zero
            for feature in features! {
               //face
               let faceRect = (feature as! CIFaceFeature).bounds
               center.x += (faceRect.maxX + faceRect.minX)/2
               center.y += (faceRect.maxY + faceRect.minY)/2
            }
            center.x /= CGFloat(features!.count)
            center.y /= CGFloat(features!.count)
            
            iconButton.setImage(chosenImage.resize(newSize: imageScaledSize, center: center), for: .normal)
        } else {
            iconButton.setImage(chosenImage.resize(newSize: imageScaledSize), for: .normal)
        }
        changedIcon = true
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Display the Image Picker
    @IBAction func selectIcon(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }

    func endEditing() {
        userNameTextField.resignFirstResponder()
    }
    
    @IBAction func purchase(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let iap = appDelegate.IAPHelper!
        let p = iap.products[0]
        if( iapView == nil ) {
            iapView = SettingsInAppPurchaseView(ctrler: self)
            iap.addView(view: iapView!)
        }
        iap.buy(productIdentifier: p.productIdentifier)
    }
    
    @IBAction func restorePurchase(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let iap = appDelegate.IAPHelper!
        if( iapView == nil ) {
            iapView = SettingsInAppPurchaseView(ctrler: self)
            iap.addView(view: iapView!)
        }
        iap.restorePurchases()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier! == "choosePalette" ) {
            let ccpc = segue.destination as? ChooseColorPalettePopOver
            if( ccpc != nil ) {
                ccpc!.settingsController = self
                ccpc!.preferredContentSize = CGSize(width: 340, height: 340)
            }
        }
    }
}

class ChooseColorPalettePopOver : UIViewController {
    @IBOutlet weak var bluePalette: UIButton!
    @IBOutlet weak var greenPalette: UIButton!
    @IBOutlet weak var redPallette: UIButton!
    @IBOutlet weak var blueStackView: UIStackView!
    @IBOutlet weak var greenStackView: UIStackView!
    @IBOutlet weak var redStackView: UIStackView!
    
    weak var settingsController : SettingsViewController?
    var buttons = [UIButton]()
    var palettes = [UIStackView]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttons.append(redPallette)
        buttons.append(greenPalette)
        buttons.append(bluePalette)
        palettes.append(redStackView)
        palettes.append(greenStackView)
        palettes.append(blueStackView)
        
        let states : [ColorPalette.States] = [.unread, .mine, .read, .unsent]
        for (i,b) in buttons.enumerated() {
            let colorPaletteView = ColorPaletteUIView()
            
            colorPaletteView.palette = i
            let image = colorPaletteView.generateImage(rect: CGRect(x: 0, y: 0, width: b.frame.width, height: b.frame.height))
            b.setImage(image, for: .normal)
            
            for (j,sbv) in palettes[i].subviews.enumerated() {
                let bv = sbv as? BubbleView
                if( bv != nil ) {
                    bv!.fillColor = ColorPalette.all_colors[i][states[j]]
                    bv!.strokeColor = ColorPalette.all_colors[i][.borderColor]
                }
            }
            
            if( i == ColorPalette.cur ) {
                b.isHighlighted = true
            }
        }
    }
    
    @IBAction func blueButtonSelected(_ sender: UIButton) {
        buttonSelection(button: sender)
        dismiss(animated: true, completion: nil)
    }
    @IBAction func greenButtonSelected(_ sender: UIButton) {
        buttonSelection(button: sender)
        dismiss(animated: true, completion: nil)
    }
    @IBAction func redButtonSelected(_ sender: UIButton) {
        buttonSelection(button: sender)
        dismiss(animated: true, completion: nil)
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
            }
        }
        
        let mb = settingsController!.choosePaletteButton
        
        let colorPaletteView = ColorPaletteUIView()
        let image = colorPaletteView.generateImage(
            rect: CGRect(x: 0, y: 0, width: mb!.frame.width, height: mb!.frame.height))
        mb?.setImage(image, for: .normal)
        mb?.setNeedsDisplay()

    }
    

}

