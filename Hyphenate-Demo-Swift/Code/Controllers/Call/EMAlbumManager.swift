//
//  EMAlbumManager.swift
//  Hyphenate-Demo-Swift
//
//  Created by 杜洁鹏 on 2017/12/11.
//  Copyright © 2017年 杜洁鹏. All rights reserved.
//

import Foundation
import UIKit

class EMAlbumManager: NSObject{
    
    typealias SaveVideoCallBack = (_ error: NSError?) -> Void
    var callBack: SaveVideoCallBack?
    func saveVideoToAlbum(path: String, callBack _callBack: @escaping SaveVideoCallBack) {
        callBack = _callBack
        DispatchQueue.global().async {
            UISaveVideoAtPathToSavedPhotosAlbum(path, self, #selector(EMAlbumManager.video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func video(videoPath: String, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if callBack != nil {
            callBack!(error)
        }
    }
}
