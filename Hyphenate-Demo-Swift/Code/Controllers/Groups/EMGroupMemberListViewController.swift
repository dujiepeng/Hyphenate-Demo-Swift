//
//  EMGroupMemberListViewController.swift
//  Hyphenate-Demo-Swift
//
//  Created by 杜洁鹏 on 2017/12/1.
//  Copyright © 2017年 杜洁鹏. All rights reserved.
//

import UIKit
import Hyphenate
import MBProgressHUD

class EMGroupMemberListViewController: EMChatroomParticipantsViewController, EMSelectItemViewControllerDelegate{
    
    var cursor = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Member List"
        setupNavBar()
    }
    
    func setupNavBar() {
        let rightBtn = UIButton(type: .custom)
        rightBtn.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        rightBtn.setImage(UIImage(named:"Icon_Add"), for: .normal)
        rightBtn.setImage(UIImage(named:"Icon_Add"), for: .highlighted)
        rightBtn.addTarget(self, action: #selector(addMembersAction), for: .touchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: rightBtn)
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    // MARK: - EMSelectItemViewControllerDelegate
    func didSelected(item: Array<IEMUserModel>?) {
        if item != nil && item!.count > 0 {
            weak var weakSelf = self
            MBProgressHUD.showInMainWindow()
            EMClient.shared().groupManager.addMembers(item!.map({$0.hyphenateID}), toGroup: group?.groupId!, message: nil, completion: { (result, error) in
                MBProgressHUD.hideHubInMainWindow()
                if error == nil {
                    weakSelf?.show("Succeed")
                }else {
                    weakSelf?.show((error?.errorDescription)!)
                }
            })
        }
    }
    
    @objc func addMembersAction() {
        let selectItemVC = EMSelectItemViewController()
        selectItemVC.selectedAry = dataArray as? Array<IEMUserModel>
        selectItemVC.selectType = EMSelectItemType.unShowSelected
        selectItemVC.delegate = self
        let nav = UINavigationController.init(rootViewController: selectItemVC)
        present(nav, animated: true, completion: nil)
    }
    
    override func contactCellDidLongPressed(model: EMUserModel?) {
        if isOwner == false && isAdmin == false{
            return
        }
        weak var weakSelf = self
        let removeFromGroupAction = EMAlertAction.defaultAction(title: "Remove from group") { (action) in
            weakSelf?.showHub(inView: weakSelf!.view, "Uploading...")
            EMClient.shared().groupManager.removeMembers([(model?.hyphenateID)!], fromGroup: weakSelf?.group?.groupId, completion: { (result, error) in
                weakSelf?.hideHub()
                if error == nil {
                    weakSelf?.group = result
                    weakSelf?.postNotificationToUpdateGroupInfo()
                    weakSelf?.dataArray?.remove(at: (weakSelf?.dataArray?.index(where: {
                        return ($0 as! IEMUserModel).hyphenateID == model?.hyphenateID
                    }))!)
                    weakSelf?.tableView.reloadData()
                }else {
                    weakSelf?.show((error?.errorDescription)!)
                }
            })
        }
        
        let addToAdminAction = EMAlertAction.defaultAction(title: "Add to admin") { (action) in
            weakSelf?.showHub(inView: weakSelf!.view, "Uploading...")
            EMClient.shared().groupManager.addAdmin(model?.hyphenateID, toGroup: weakSelf?.group?.groupId, completion: { (result, error) in
                weakSelf?.hideHub()
                if error == nil {
                    weakSelf?.group = result
                    weakSelf?.postNotificationToUpdateGroupInfo()
                    weakSelf?.dataArray?.remove(at: (weakSelf?.dataArray?.index(where: {
                        return ($0 as! IEMUserModel).hyphenateID == model?.hyphenateID
                    }))!)
                    weakSelf?.tableView.reloadData()
                }else {
                    weakSelf?.show((error?.errorDescription)!)
                }
            })
        }
        
        let muteAction = EMAlertAction.defaultAction(title: "Mute") { (action) in
            weakSelf?.showHub(inView: weakSelf!.view, "Uploading...")
            EMClient.shared().groupManager.muteMembers([(model?.hyphenateID)!], muteMilliseconds: -1, fromGroup: weakSelf?.group?.groupId, completion: { (result, error) in
                weakSelf?.hideHub()
                if error == nil {
                    
                }else {
                    weakSelf?.show((error?.errorDescription)!)
                }
            })
        }
            
        
        let moveToBlackList = EMAlertAction.defaultAction(title: "Move to blackList") { (action) in
            weakSelf?.showHub(inView: weakSelf!.view, "Uploading...")
            EMClient.shared().groupManager.blockMembers(([(model?.hyphenateID)!]), fromGroup: weakSelf?.group?.groupId, completion: { (result, error) in
                weakSelf?.hideHub()
                if error == nil {
                    weakSelf?.group = result
                    weakSelf?.postNotificationToUpdateGroupInfo()
                    weakSelf?.dataArray?.remove(at: (weakSelf?.dataArray?.index(where: {
                        return ($0 as! IEMUserModel).hyphenateID == model?.hyphenateID
                    }))!)
                    weakSelf?.tableView.reloadData()
                }else {
                    weakSelf?.show((error?.errorDescription)!)
                }
            })
        }
        
        let alertController = UIAlertController.alertWith(item: removeFromGroupAction, muteAction,moveToBlackList)
        if isOwner {
            alertController.addAction(addToAdminAction)
        }
        present(alertController, animated: true, completion: nil)
    }
    
    override func tableViewDidTriggerFooterRefresh() {
        fetchPersion(isHeader: false)
        page += 50
    }
    
    override func fetchPersion(isHeader: Bool) {
        weak var weakSelf = self
        weakSelf?.showHub(inView: weakSelf!.view, "Loading...")
        EMClient.shared().groupManager.getGroupMemberListFromServer(withId: group?.groupId, cursor: cursor, pageSize: pageSize) { (result, error) in
            weakSelf?.hideHub()
            weakSelf?.tableViewDidFinishTriggerHeader(isHeader: isHeader)
            if error == nil {
                if result?.cursor != nil {
                    weakSelf?.cursor = (result?.cursor)!
                }
                if (isHeader) {
                    weakSelf?.dataArray!.removeAll()
                }
                if result?.list != nil {
                    var list = Array<IEMUserModel>()
                    for username in result!.list {
                        list.append(EMUserModel.createWithHyphenateId(hyphenateId: username as! String)!)
                    }
                    weakSelf?.dataArray! = (weakSelf?.dataArray!)! + list
                }
                
                DispatchQueue.main.async {
                    weakSelf?.tableView.reloadData()
                    if result!.list.count < self.pageSize {
                        self.showRefreshFooter = false
                    }else {
                        self.showRefreshFooter = true;
                    }
                }
            }else {
                weakSelf?.show((error?.errorDescription)!)
            }
        }
    }
}