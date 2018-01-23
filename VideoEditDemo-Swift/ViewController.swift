//
//  ViewController.swift
//  VideoEditDemo-Swift
//
//  Created by 刘志伟 on 2017/8/21.
//  Copyright © 2017年 刘志伟. All rights reserved.
//

import UIKit
import CoreMedia
import MediaPlayer
import MobileCoreServices

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initSubViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func initSubViews() {
        let testButton = UIButton.init(frame:CGRect.init(x: 50, y: 50, width: 120, height: 50))
        testButton.addTarget(self, action: #selector(SelectVideo), for: UIControlEvents.touchUpInside)
        testButton.setTitle("选择编辑视频", for: UIControlState.normal)
        testButton.setTitleColor(UIColor.green, for: UIControlState.normal)
        self.view.addSubview(testButton)
    }
    
    func SelectVideo() {
        let imgPickerVC = UIImagePickerController.init()
        imgPickerVC.mediaTypes = NSArray.init(objects: kUTTypeMovie ) as! [String]
        imgPickerVC.delegate = self
        imgPickerVC.isEditing = true
        self.present(imgPickerVC, animated: true) { 
            
        }
    }
    
    // MARK: -  UIImagePickerControllerDelegate 代理方法
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        picker.dismiss(animated: true, completion: nil)
        let url = info[UIImagePickerControllerMediaURL]
        
        let videoEditVC = VideoEditVC.init()
        videoEditVC.videoUrl = url as? NSURL
        self.present(videoEditVC, animated: true) { 
            
        }
    }
}

