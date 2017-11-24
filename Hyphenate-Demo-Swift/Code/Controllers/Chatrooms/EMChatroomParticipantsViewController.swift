//
//  EMChatroomParticipantsViewController.swift
//  Hyphenate-Demo-Swift
//
//  Created by 杜洁鹏 on 2017/11/23.
//  Copyright © 2017年 杜洁鹏. All rights reserved.
//

import UIKit
import Hyphenate

class EMChatroomParticipantsViewController: EMBaseRefreshTableViewController, EMContactCellDelegate{

    let pageSize = 50
    var isOwner = false
    var isAdmin = false
    var chatroom: EMChatroom?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showRefreshHeader = true
        setupNavBar()
        tableViewDidTriggerHeaderRefresh()
    }
    
    func setupNavBar() {
        let leftBtn = UIButton(type: UIButtonType.custom)
        leftBtn.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        leftBtn.setImage(UIImage(named:"Icon_Back"), for: .normal)
        leftBtn.setImage(UIImage(named:"Icon_Back"), for: .highlighted)
        leftBtn.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        let leftBarButtonItem = UIBarButtonItem(customView: leftBtn)
        navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
    @objc func backAction() {
        navigationController?.popViewController(animated: true)
    }
    
    func contactCellDidLongPressed(model: EMUserModel?) {
        if isOwner == false  && isAdmin == false{
            return
        }
    }
    
    func postNotificationToUpdateChatroomInfo() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:KEM_REFRESH_CHATROOM_INFO), object: chatroom)
    }
    
    func fetchPersion(isHeader: Bool) {
        self.tableViewDidFinishTriggerHeader(isHeader: isHeader)
    }
    
    override func tableViewDidTriggerHeaderRefresh() {
        fetchPersion(isHeader: true)
    }
    
    override func tableViewDidTriggerFooterRefresh() {
        fetchPersion(isHeader: false)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellItentify = "EMContactCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellItentify)
        if cell == nil {
            let contactCell = Bundle.main.loadNibNamed("EMContactCell", owner: self, options: nil)?.first as! EMContactCell
            contactCell.delegate = self
            cell = contactCell
        }
        
        let model = dataArray![indexPath.row] as! EMUserModel
        (cell as! EMContactCell).set(model:model)
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray!.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

}
