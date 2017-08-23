//
//  VideoEditVC.swift
//  VideoEditDemo-Swift
//
//  Created by 刘志伟 on 2017/8/21.
//  Copyright © 2017年 刘志伟. All rights reserved.
//

import UIKit
import AVFoundation

// 屏幕的物理宽度
let Screen_Width = UIScreen.main.bounds.size.width
// 屏幕的物理高度
let Screen_Height = UIScreen.main.bounds.size.height

// MARK: 全局变量
var playerItem : AVPlayerItem!
var playerLayer : AVPlayerLayer!
var player : AVPlayer!

var editScrollView : UIScrollView!
var bottomView     : UIView!
var leftDragView   : DragEditView!
var rightDragView  : DragEditView!
var line           : UIView!
var topBorder      : UIView!
var bottomBorder   : UIView!

var repeatTimer    :Timer! // 循环播放计时器
var lineMoveTimer  :Timer! // 播放条移动计时器
var framesArray    :NSMutableArray! // 视频帧数组
var tempVideoPath  : String!
var leftStartPoint : CGPoint!
var rightStartPoint: CGPoint!
var isDraggingRightOverlayView = false // 拖拽左侧编辑框
var isDraggingLeftOverlayView  = false // 拖拽右侧编辑框
var isEdited        = false // YES：编辑完成
var startTime :CGFloat = 0.0  // 编辑框内视频开始时间秒
var endTime   :CGFloat = 10.0  // 编辑框内视频结束时间秒
var startPointX     :CGFloat!   // 编辑框起始点
var endPointX       :CGFloat!   // 编辑框结束点
var IMG_Width       :CGFloat!   // 视频帧宽度
var linePositionX   :CGFloat!   // 播放条的位置
var boderX          :CGFloat?   // 编辑框边线X
var boderWidth      :CGFloat?   // 编辑框边线长度
var touchPointX     :CGFloat!   // 编辑视图区域外触点
let EDGE_EXTENSION_FOR_THUMB = 20.0


class VideoEditVC: UIViewController,UIScrollViewDelegate {

    // MARK: 公有变量
    /**
     * 默认为true , false：不显示视频帧并不可编辑剪切视频
     */
    open var isEidt = true
    
    /*
     待编辑视频的URL
     */
    open var videoUrl : NSURL?{
    
        didSet{
            print("已经设置了videoURL")
        }
    }

    // MARK: life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        
        self.initSettings()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        invalidatePlayer()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: 私有方法
    func initSettings() {
        // 手机静音时可播放声音
        let session = AVAudioSession.sharedInstance()
        do{ try session.setActive(true) }
        catch{}
        do{ try  session.setCategory(AVAudioSessionCategoryPlayback) }
        catch{}

        self.initSubViews()
        
        if isEidt{
            analysisVideoFrames()
        }
        else {
            leftDragView.isHidden = true
            rightDragView.isHidden = true
        }
        self.initPlayer(videoUrl: self.videoUrl!)
    }
    
    // MARK: 视图初始化
    func initSubViews() {
        let backBtn = UIButton.init(frame: CGRect.init(x: 0, y: 20, width: 60, height: 50))
        backBtn.setTitle("返回", for: UIControlState.normal)
        backBtn.setTitleColor(UIColor.white, for: UIControlState.normal)
        backBtn.addTarget(self, action: #selector(dismissSelfVC), for: UIControlEvents.touchUpInside)
        self.view.addSubview(backBtn)
        
        bottomView = UIView.init(frame: CGRect.init(x: 0, y: Screen_Height-80, width: Screen_Width, height: 80))
        bottomView.backgroundColor = UIColor.black
        self.view.addSubview(bottomView)
        
        editScrollView = UIScrollView.init(frame: CGRect.init(x: 0, y: 0, width: Screen_Width, height: 50))
        editScrollView.showsHorizontalScrollIndicator = false
        editScrollView.bounces = false
        bottomView.addSubview(editScrollView)
        editScrollView.delegate = self
        
        // 添加编辑框上下边线
        boderX = 45.0
        boderWidth = Screen_Width-90
        topBorder = UIView.init(frame: CGRect.init(x:boderX! , y: 0, width: boderWidth!, height: 2.0))
        topBorder.backgroundColor = UIColor.white
        bottomView.addSubview(topBorder)
        
        bottomBorder = UIView.init(frame: CGRect.init(x:boderX! , y: 50.0-2, width: boderWidth!, height: 2.0))
        bottomBorder.backgroundColor = UIColor.white
        bottomView.addSubview(bottomBorder)
        
        // 添加左右编辑框拖动条
        leftDragView = DragEditView.initEditView(frame: CGRect.init(x: -(Screen_Width-50), y: 0, width: Screen_Width, height: 50), isLeft: true)
        leftDragView.hitTestEdgeInsets = UIEdgeInsetsMake(0, -(CGFloat)(EDGE_EXTENSION_FOR_THUMB), 0, -(CGFloat)(EDGE_EXTENSION_FOR_THUMB))
        bottomView.addSubview(leftDragView)
        
        rightDragView = DragEditView.initEditView(frame: CGRect.init(x: (Screen_Width-50), y: 0, width: Screen_Width, height: 50), isLeft: false)
        rightDragView.hitTestEdgeInsets = UIEdgeInsetsMake(0, -(CGFloat)(EDGE_EXTENSION_FOR_THUMB), 0, -(CGFloat)(EDGE_EXTENSION_FOR_THUMB))
        bottomView.addSubview(rightDragView)
        
        let panGestureRecognizer = UIPanGestureRecognizer.init(target: self
            , action: #selector(moveOverlayView(gesture:)))
        bottomView.addGestureRecognizer(panGestureRecognizer)
        
        // 播放条
        line = UIView.init(frame: CGRect.init(x: 10, y: 0, width: 3, height: 50))
        line.backgroundColor = getColor(R: 214, G: 230, B: 247)
        bottomView.addSubview(line)
        line.isHidden = true
        
        let doneBtn = UIButton.init(frame: CGRect.init(x: Screen_Width-60, y: 50, width: 60, height: 30))
        doneBtn.setTitle("完成", for: UIControlState.normal)
        doneBtn.setTitleColor(getColor(R: 14, G: 178, B: 10), for: UIControlState.normal)
        doneBtn.addTarget(self, action: #selector(notifyDelegateOfDidChange), for: UIControlEvents.touchUpInside)
        bottomView.addSubview(doneBtn)
        
        // 默认值
        startPointX = 50;
        endPointX = Screen_Width-50;
        IMG_Width = (Screen_Width-100)/10;
    }
    
    // MARK: 读取视频帧
    func analysisVideoFrames() {
        // 初始化asset对象
        let videoAsset = AVURLAsset.init(url: self.videoUrl as! URL)
        // 获取总视频的长度 = 总帧数 / 每秒的帧数
        let videoSumTime = videoAsset.duration.value / int_fast64_t(videoAsset.duration.timescale)
        // 创建AVAssetImageGenerator对象
        let generator = AVAssetImageGenerator.init(asset: videoAsset)
        generator.maximumSize = bottomView.frame.size
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = kCMTimeZero
        generator.requestedTimeToleranceAfter = kCMTimeZero
        
        // 添加需要帧数的时间集合
        framesArray = NSMutableArray.init()
        
        for i in 0..<videoSumTime {
            let time = CMTimeMake(i*int_fast64_t(videoAsset.duration.timescale), videoAsset.duration.timescale)
            let value = NSValue.init(time: time)
            framesArray.add(value)
        }
        
        var count : CGFloat = 0.0
        generator.generateCGImagesAsynchronously(forTimes:framesArray as! [NSValue]) { (requestedTime:CMTime, img:CGImage?, actualTime:CMTime, result:AVAssetImageGeneratorResult, error:Error?) in
            
            if result == AVAssetImageGeneratorResult.succeeded {
            
                let thumImgView = UIImageView.init(frame: CGRect.init(x: 50+count*IMG_Width, y: 0, width: IMG_Width, height: 70))
                thumImgView.image = UIImage.init(cgImage: img!)
                
                // 主线程刷新UI
                DispatchQueue.main.async(execute: { 
                    editScrollView.addSubview(thumImgView)
                    editScrollView.contentSize = CGSize.init(width: 100.0+count*IMG_Width, height: 0.0)
                })
                
                count += 1
            }
            else if result == AVAssetImageGeneratorResult.failed{
                print("Failed with error: " + (error?.localizedDescription)!)
            }
            else if result == AVAssetImageGeneratorResult.cancelled{
                print("AVAssetImageGeneratorCancelled")
            }
        }
    }
    
    
    // MARK: 播放器初始化
    func initPlayer(videoUrl:NSURL) {
        playerItem = AVPlayerItem.init(url:videoUrl as URL)
        playerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        player = AVPlayer.init(playerItem: playerItem)
        player.addObserver(self, forKeyPath: "timeControlStatus", options: NSKeyValueObservingOptions.new, context: nil)
        playerLayer = AVPlayerLayer.init(player: player)
        playerLayer?.frame = CGRect.init(x: 0, y: 80, width: Screen_Width, height: Screen_Height-160)

        self.view.layer.addSublayer(playerLayer!)
    }
    
    // MARK: KVO监听
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status"{
            
            switch playerItem.status {
                
            case AVPlayerItemStatus.unknown:
              print("unknow 未知状态不能播放")
                break
                
            case AVPlayerItemStatus.readyToPlay:
                print("read to play 可以播放")
                player.play()
                if isEdited == false {
                    line.isHidden = false
                    startTimer()
                }
                break
                
            case AVPlayerItemStatus.failed:
                print("fail 播放失败")
                break
                
            }
            
        }
        else if keyPath == "timeControlStatus"{
            if player.timeControlStatus == AVPlayerTimeControlStatus.paused{
                player.seek(to: CMTime.init(value: 0, timescale: 1))
                player.play()
            }

        }
    }

    
    // MARK: 编辑区域手势拖动
    func moveOverlayView(gesture:UIPanGestureRecognizer) {
        switch gesture.state {
        case UIGestureRecognizerState.began:
            stopTimer()
            let isRight = rightDragView.pointInsideImgView(point: gesture.location(in: rightDragView))
            let isLeft = leftDragView.pointInsideImgView(point: gesture.location(in: leftDragView))
            isDraggingLeftOverlayView = false
            isDraggingRightOverlayView = false
            
            touchPointX = gesture.location(in: bottomView).x
            if isRight{
                rightStartPoint = gesture.location(in: bottomView)
                isDraggingLeftOverlayView = false
                isDraggingRightOverlayView = true
            }
            else if isLeft {
                leftStartPoint = gesture.location(in: bottomView)
                isDraggingLeftOverlayView = true
                isDraggingRightOverlayView = false
            }
            break
            
        case UIGestureRecognizerState.changed:
            let point = gesture.location(in: bottomView)
            // Left
            if isDraggingLeftOverlayView {
                let deltaX = point.x - leftStartPoint.x
                var center = leftDragView.center
                center.x += deltaX
                let durationTime = (Screen_Width-100)*2/10 // 最小范围2秒
                let flag = (endPointX!-point.x)>durationTime
                
                if center.x >= (50-Screen_Width/2) && flag {
                    leftDragView.center = center
                    leftStartPoint = point
                    startTime = (point.x+editScrollView.contentOffset.x)/IMG_Width
                   
                    // 不能直接在frame初始化方法里写成 boderX!+=deltaX 会报错
                    boderX!+=deltaX
                    boderWidth!-=deltaX
                    topBorder.frame = CGRect.init(x: boderX!, y: 0.0, width: boderWidth!, height: 2.0)
                    bottomBorder.frame = CGRect.init(x: boderX!, y: 50.0-2.0, width: boderWidth!, height: 2.0)
                    
                    startPointX = point.x
                }
                
                let second = (point.x+editScrollView.contentOffset.x)/IMG_Width
                let startTim = CMTimeMakeWithSeconds(Float64(second), player.currentTime().timescale)
                // 只有视频播放的时候才能够快进和快退1秒以内
                player .seek(to: startTim, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
                
            }
            else if isDraggingRightOverlayView { // Right
                let deltaX = point.x - rightStartPoint.x
                var center = rightDragView.center
                center.x += deltaX
                let durationTime = (Screen_Width-100)*2/10 // 最小范围2秒
                let flag = (point.x-startPointX)>durationTime
                
                if center.x <= (Screen_Width-50+Screen_Width/2) && flag {
                    rightDragView.center = center
                    rightStartPoint = point
                    endTime = (point.x+editScrollView.contentOffset.x)/IMG_Width
                    
                    boderWidth!+=deltaX
                    topBorder.frame = CGRect.init(x: boderX!, y: 0.0, width: boderWidth!, height: 2.0)
                    bottomBorder.frame = CGRect.init(x: boderX!, y: 50.0-2.0, width: boderWidth!, height: 2.0)
                    endPointX = point.x
                }
                
                let second = (point.x+editScrollView.contentOffset.x)/IMG_Width
                let startTim = CMTimeMakeWithSeconds(Float64(second), player.currentTime().timescale)
                // 只有视频播放的时候才能够快进和快退1秒以内
                player .seek(to: startTim, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            }
            else { // 移动scrollView
                let deltaX = point.x - touchPointX
                let newOffSet = editScrollView.contentOffset.x - deltaX
                let currentOffSet = CGPoint.init(x: newOffSet, y: 0)
                
                if currentOffSet.x >= 0 && currentOffSet.x <= (editScrollView.contentSize.width-Screen_Width){
                    editScrollView.contentOffset = currentOffSet
                    touchPointX = point.x
                }
                
            }
            
            break
            
        case UIGestureRecognizerState.ended:
            startTimer()
            
            break
            
        default:
            break
        }
    }
    
    // MARK: 编辑区域循环播放
    func repeatPlay() {
        let start = CMTimeMakeWithSeconds(Float64(startTime), player.currentTime().timescale)
        player.seek(to: start, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        player.play()
    }
    
    // MARK: 播放条移动
    func lineMove() {
        let duarationTime = (endPointX-startPointX-20)/Screen_Width*10;
        linePositionX = linePositionX + 0.01*(endPointX - startPointX-20)/duarationTime;
        if linePositionX >= rightDragView.frame.minX-3{
           linePositionX = leftDragView.frame.maxX+3
        }
        
        line.frame = CGRect.init(x: linePositionX, y: 0, width: 3, height: 50)
    }
    
    // MARK: 视频裁剪
    func notifyDelegateOfDidChange(){
        tempVideoPath = NSTemporaryDirectory().appending("tmpMov.mov")
        deleteTempFile()
        
        let asset = AVAsset.init(url: self.videoUrl! as URL)
        let exportSession : AVAssetExportSession! = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetPassthrough)
        
        let fUrl = NSURL.fileURL(withPath: tempVideoPath)
        exportSession.outputURL = fUrl as URL?
        exportSession.outputFileType = "com.apple.quicktime-movie"
        
        let start = CMTimeMakeWithSeconds(Float64(startTime), player.currentTime().timescale)
        let duration = CMTimeMakeWithSeconds(Float64(endTime - startTime), player.currentTime().timescale)
        let range = CMTimeRange.init(start: start, duration: duration)
        exportSession.timeRange = range
        
        exportSession.exportAsynchronously(completionHandler: {
            switch exportSession.status{
                case AVAssetExportSessionStatus.failed :
                    print("Export failed " + (exportSession.error?.localizedDescription)!)
                break
            
            case AVAssetExportSessionStatus.cancelled:
                    print("Export Canceled")
                break
            case AVAssetExportSessionStatus.completed:
                    print("Export completed")
                weak var weakSelf = self
                // 保存到相册
                UISaveVideoAtPathToSavedPhotosAlbum((fUrl.relativePath), weakSelf, #selector(weakSelf?.videoDidFinishedSaved(videoPath:error:contextInfo:)), nil)
                
                // 主线程刷新UI
                DispatchQueue.main.async(execute: {
                    isEdited = true
                    playerLayer.removeFromSuperlayer()
                    weakSelf?.invalidatePlayer()
                    weakSelf?.initPlayer(videoUrl: fUrl as NSURL)
                    bottomView.isHidden = true
                }) 
                break
                
            default:
                print("Export other status");
                
                break
            }
        })
    }
    
    func videoDidFinishedSaved(videoPath:NSString, error:NSError, contextInfo:UnsafeMutableRawPointer?) {
        if (error != nil) {
            print("保存到相册失败")
        }
        else {
            print("保存到相册成功")
        }
    }
    
    func deleteTempFile() {
        let url = NSURL.fileURL(withPath: tempVideoPath)
        let filem = FileManager.default
        let exist = filem.fileExists(atPath: url.path)
        var error : NSError?
        if exist {
            do{try filem.removeItem(at: url)}
            catch let err as NSError {
                error = err
            }
            print("file deleted")
            if (error != nil) {
                print("file remove error, " + (error?.localizedDescription)!)
            }
            
        }
        else {
            print("no file by that name")
        }
    }
    
    // MARK: 开启计时器
    func startTimer() {
        let duarationTime = (endPointX-startPointX-20)/Screen_Width*10;
        line.isHidden = false
        linePositionX = startPointX+10
        lineMoveTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(lineMove), userInfo: nil, repeats: true)
        
        // 开启播放循环
        repeatTimer = Timer.scheduledTimer(timeInterval: TimeInterval(duarationTime), target: self, selector: #selector(repeatPlay), userInfo: nil, repeats: true)
        repeatTimer.fire()
    }
    
    // MARK: 关闭计时器
    func stopTimer() {
        repeatTimer.invalidate()
        lineMoveTimer.invalidate()
        line.isHidden = true
    }
    
    // MARK: UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool){
        startTimer()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = editScrollView.contentOffset.x
        var start : CMTime?
        
        if offsetX >= 0{
            start = CMTimeMakeWithSeconds(Float64((offsetX+startPointX)/IMG_Width), player.currentTime().timescale)
            let duration = endTime-startTime
            startTime = (offsetX-startPointX)/IMG_Width
            endTime = startTime+duration
        }
        else {
            start = CMTimeMakeWithSeconds(Float64(startPointX), player.currentTime().timescale)
        }
        
        // 只有视频播放的时候才能够快进和快退1秒以内
        player.seek(to: start!, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
    
    func dismissSelfVC() {
        self.dismiss(animated: true) { 
            
        }
    }
    
    // MARK: 释放引用
    func invalidatePlayer() {
        stopTimer()
        player.removeObserver(self, forKeyPath: "timeControlStatus")
        player.pause()
        playerItem.removeObserver(self, forKeyPath: "status")
    }
    
    // MARK: 获取颜色方法
    func getColor(R:CGFloat , G:CGFloat ,B:CGFloat) -> UIColor {
        return UIColor.init(colorLiteralRed: Float(R)/255.0, green: Float(G)/255.0, blue: Float(B)/255.0, alpha: 1.0)
    }
    
}
