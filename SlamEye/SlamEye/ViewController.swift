//
//  ViewController.swift
//  SlamEye
//
//  Created by Tucker Morgan on 5/26/19.
//  Copyright © 2019 Tucker Morgan. All rights reserved.
//

import UIKit
import AVFoundation
import Network

class ViewController: UIViewController, FrameExtractorDelegate {
    var frameExtracor : FrameExtractor?

    var server: NetConnectionServer?
    var snc : StreamNetConnection?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.frameExtracor = FrameExtractor()
        self.frameExtracor!.delegate = self
        
        
        server = NetConnectionServer(type: "_eye._tcp.", name: "main_eye", accept: { (snc) in
            self.snc = snc
        })
 

    }
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func captured(image: UIImage) {
        if snc != nil {
            let newImage = imageWithImage(image: image, scaledToSize: CGSize(width: image.size.width * 0.1, height: image.size.height * 0.1))
            let pngImage = newImage.pngData()!
            //self.view! = UIImageView(image: newImage)
            let innerSnc = snc!
            innerSnc.send(pngImage)
            innerSnc.send(Data("ENDPNG".utf8))
        }
    }
}

