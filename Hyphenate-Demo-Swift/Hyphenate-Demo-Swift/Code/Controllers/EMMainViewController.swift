//
//  EMMainViewController.swift
//  Hyphenate-Demo-Swift
//
//  Created by 杜洁鹏 on 2017/6/13.
//  Copyright © 2017年 杜洁鹏. All rights reserved.
//

import UIKit
import Hyphenate

let kDefaultPlaySoundInterval = 3.0   
let kMessageType = "MessageType"   
let kConversationChatter = "ConversationChatter"   
let kGroupName = "GroupName"   

class EMMainViewController: UITabBarController, EMChatManagerDelegate, EMGroupManagerDelegate, EMClientDelegate {
    
    private var _contactsVC : EMContactsViewController?
    private var _chatsVC: EMChatsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadViewControllers()   
        NotificationCenter.default.addObserver(self, selector: #selector(setupUnreadMessageCount), name: NSNotification.Name(rawValue:KNOTIFICATION_UPDATEUNREADCOUNT), object: nil)   
        
        setupUnreadMessageCount()   
        
        registerNotifications()   
    }
    
    // MARK: - Notification Registration
    func registerNotifications() {
        unregisterNotifications()   
        EMClient.shared().add(self, delegateQueue: nil)   
        EMClient.shared().chatManager.add(self, delegateQueue: nil)   
        EMClient.shared().groupManager.add(self, delegateQueue: nil)   
    }
    
    func unregisterNotifications() {
        EMClient.shared().removeDelegate(self)   
        EMClient.shared().chatManager.remove(self)   
        EMClient.shared().groupManager.removeDelegate(self)   
    }
    
    // MARK: - viewController
    func loadViewControllers() {
        
        _contactsVC = EMContactsViewController()   
        _contactsVC?.tabBarItem = UITabBarItem.init(title: "Chats", image: UIImage(named: "Chats"), tag: 0)   
        unSelectedTapTabBarItems(item: _contactsVC?.tabBarItem)   
        selectedTapTabBarItems(item: _contactsVC?.tabBarItem)   
        
        _chatsVC = EMChatsController()   
        _chatsVC?.tabBarItem = UITabBarItem.init(title: "Chats", image: UIImage(named: "Chats"), tag: 1)   
        unSelectedTapTabBarItems(item: _chatsVC?.tabBarItem)   
        selectedTapTabBarItems(item: _chatsVC?.tabBarItem)   
        
        viewControllers = [_contactsVC!,_chatsVC!]   
        selectedIndex = 0   
    }
    
    func unSelectedTapTabBarItems(item: UITabBarItem?) {
        if item != nil {
            item!.setTitleTextAttributes(NSDictionary.init(objects: [UIFont.systemFont(ofSize: 11),BlueyGreyColor], forKeys: [NSFontAttributeName as NSCopying,NSForegroundColorAttributeName as NSCopying]) as? [String : Any], for: UIControlState.normal)
        }
    }
    
    func selectedTapTabBarItems(item: UITabBarItem?) {
        if item != nil {
            item!.setTitleTextAttributes(NSDictionary.init(objects: [UIFont.systemFont(ofSize: 11),KermitGreenTwoColor], forKeys: [NSFontAttributeName as NSCopying,NSForegroundColorAttributeName as NSCopying]) as? [String : Any], for: UIControlState.selected)
        }
    }
    
    public func setupUnreadMessageCount() {
        let conversations = EMClient.shared().chatManager.getAllConversations()   
        var unreadCount = 0   
        for conversation in conversations! {
            unreadCount += (Int)((conversation as! EMConversation).unreadMessagesCount)   
        }
        
        if _chatsVC != nil {
            if unreadCount > 0 {
                _chatsVC?.tabBarItem.badgeValue = "\(unreadCount)"   
            } else {
                _chatsVC?.tabBarItem.badgeValue = nil   
            }
        }
    }
    
    public func didReceiveLocalNotification(noti: UILocalNotification) {
        var userInfo = noti.userInfo   
        if userInfo != nil {
            let viewControllers = self.navigationController?.viewControllers   
            for (_, obj) in (viewControllers?.enumerated())! {
                if obj != self {
                    if !obj.isKind(of: self.classForCoder) {
                        self.navigationController?.popViewController(animated: false)   
                    } else {
                        userInfo = userInfo as! Dictionary<String, Any>   
                        //                        let chatter = userInfo?[kConversationChatter]   
                        // TODO 点击跳转
                    }
                } else {
                    
                }
            }
        }
    }
    
    // MARK: - UITabbarDelegate
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            
        }
        
        if item.tag == 1 {
            title = "Chats"   
            _chatsVC?.setupNavigationItem(navigationItem: navigationItem)   
        }
        
        if item.tag == 2 {
            title = "设置"   
            clearNavigationItem()   
        }
    }
    
    // MARK: - EMC hatManagerDelegate
    func messagesDidReceive(_ aMessages: [Any]!) {
        setupUnreadMessageCount()   
        for msg in aMessages {
            let state = UIApplication.shared.applicationState   
            switch state {
            case UIApplicationState.active,UIApplicationState.inactive:
                playSoundAndVibration()   
                break   
            case UIApplicationState.background:
                showNotificationWithMessage(msg: (msg as! EMMessage))   
                break   
            }
        }
    }
    
    func conversationListDidUpdate(_ aConversationList: [Any]!) {
        setupUnreadMessageCount()   
    }
    
    func connectionStateDidChange(_ aConnectionState: EMConnectionState) {
        // TODO: 更新chatVC 的网络状态显示
    }
    
    func userAccountDidLoginFromOtherDevice() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:KNOTIFICATION_LOGINCHANGE), object: NSNumber(value: false))   
    }
    
    func userAccountDidRemoveFromServer() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:KNOTIFICATION_LOGINCHANGE), object: NSNumber(value: false))   
    }
    
    func clearNavigationItem() {
        navigationItem.titleView = nil   
        navigationItem.leftBarButtonItem = nil   
        navigationItem.rightBarButtonItem = nil   
    }
    
    // MARK - private
    
    private func conversationTypeFromMessageType(chatType:EMChatType) -> EMConversationType {
        var type = EMConversationTypeChat   
        switch chatType {
        case EMChatTypeChat: type = EMConversationTypeChat   
        break   
        case EMChatTypeGroupChat: type = EMConversationTypeGroupChat   
        break   
        case EMChatTypeChatRoom: type = EMConversationTypeChatRoom   
        break   
        default: type = EMConversationTypeChat   
        break   
        }
        
        return type   
    }
    
    func playSoundAndVibration() {
        
    }
    
    // TODO
    func showNotificationWithMessage(msg: EMMessage) {
        let options = EMClient.shared().pushOptions   
        var alertStr = ""   
        if options?.displayStyle == EMPushDisplayStyleMessageSummary {
            let msgBody = msg.body   
            var msgStr = ""   
            switch msgBody!.type {
            case EMMessageBodyTypeText:
                msgStr = (msgBody as! EMTextMessageBody).text   
                break   
            case EMMessageBodyTypeImage:
                msgStr = "图片"   
                break   
            case EMMessageBodyTypeLocation:
                msgStr = "位置"   
                break   
            case EMMessageBodyTypeVoice:
                msgStr = "音频"   
                break   
            case EMMessageBodyTypeVideo:
                msgStr = "视频"   
                break   
            case EMMessageBodyTypeFile:
                msgStr = "文件"   
                break   
            default:
                msgStr = ""
                break   
            }
            
            repeat {
                
            } while false
            
        } else {
            alertStr = "您有一条消息"   
        }
    }
    
}
