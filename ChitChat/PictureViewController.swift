//
//  PictureViewController.swift
//  ChitChat
//
//  Created by next-shot on 5/8/17.
//  Copyright © 2017 next-shot. All rights reserved.
//

import Foundation
import UIKit

class ShareableImageView : UIImageView {
    weak var ctrler: PictureViewController?
    
    override init(image: UIImage?) {
        super.init(image: image)
        
        let tapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ShareableImageView.handleTapGesture))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func handleTapGesture(sender: UILongPressGestureRecognizer) {
        if( sender.state == .ended && self.becomeFirstResponder() ) {
            let sharedMenu = UIMenuController.shared
            let loc = sender.location(in: self)
            sharedMenu.setTargetRect(CGRect(origin: loc, size: CGSize(width: 0, height: 0)), in: self)
            sharedMenu.menuItems = [UIMenuItem(title: "Save", action: #selector(ShareableImageView.saveImage))]
            sharedMenu.setMenuVisible(true, animated: true)
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        get {
           return true
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if( action == #selector(UIResponderStandardEditActions.copy(_:)) ) {
            return true
        }
        if( action == #selector(ShareableImageView.saveImage) ) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    override func copy(_ sender: Any?) {
        UIPasteboard.general.image = self.image
    }
    
    func saveImage(_sender: Any?) {
        UIImageWriteToSavedPhotosAlbum(self.image!, self, #selector(ShareableImageView.handleSaveToPhotoAlbumError), nil)
    }
    
    func handleSaveToPhotoAlbumError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if( error != nil ) {
            let ac = UIAlertController(title: "Save error", message: error?.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            ctrler?.present(ac, animated: true, completion: nil)
        }
    }
}

class PictureViewController : UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: ShareableImageView!
    @IBOutlet weak var imageCaption: UILabel!
    var message : Message?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        imageView.image = message?.image
        imageView.ctrler = self
        imageCaption.text = message?.text
        
        let tapGestureRecognizer = UILongPressGestureRecognizer(target: imageView, action: #selector(ShareableImageView.handleTapGesture))
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let minScaleX = scrollView.frame.size.width / imageView.frame.size.width
        let minScaleY = scrollView.frame.size.height / imageView.frame.size.height
        scrollView.minimumZoomScale = min(minScaleX, minScaleY)
        scrollView.maximumZoomScale = 3.0;
        
        scrollView.contentSize = imageView.frame.size
        
        super.viewWillAppear(animated)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}
