//
//  DragEditView.swift
//  VideoEditDemo-Swift
//
//  Created by 刘志伟 on 2017/8/21.
//  Copyright © 2017年 刘志伟. All rights reserved.
//

import UIKit

open class DragEditView: UIView {

    // MARK: 系统方法
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: 公有属性
    open var hitTestEdgeInsets : UIEdgeInsets!
    
    // MARK: 私有属性
    
    var imgView : UIImageView!
    var isLeft = false
    
    // MARK: 私有方法
    static func initEditView(frame:CGRect , isLeft:Bool) -> DragEditView {
        let `self` =   DragEditView.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isLeft = isLeft
        let backView = UIView.init(frame: self.bounds)
        backView.backgroundColor = UIColor.black
        backView.alpha = 0.6
        self.addSubview(backView)
        self.initSubViews()
        
        return `self`
    }
    
    func initSubViews() {
        let width = self.frame.size.width
        let height = self.frame.size.height
        
        var imgFrame = CGRect.init()
        
        if self.isLeft {
            imgFrame = CGRect.init(x: width-10, y: 0, width: 10, height: height)
        }
        else {
            imgFrame = CGRect.init(x: 0, y: 0, width: 10, height: height)
        }
        
        imgView = UIImageView.init(frame: imgFrame)
        imgView?.image = UIImage.init(named: "drag.jpg")
        self.addSubview(imgView!)
    }
    
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return self.pointInsideSelf(point: point)
    }
    
    func pointInsideSelf(point:CGPoint) -> Bool {
        let relativeFrame = self.bounds
        let hitFame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets!)
        return hitFame.contains(point)
    }
    
    func pointInsideImgView(point:CGPoint) -> Bool {
        let relativeFrame = imgView?.frame
        let hitFame = UIEdgeInsetsInsetRect(relativeFrame!, hitTestEdgeInsets!)
        return hitFame.contains(point)
    }

}
