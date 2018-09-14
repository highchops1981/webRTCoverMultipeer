//
//  MultipeerConnectivityViewController.swift
//  webRTCoverMultipeer
//
//  Created by ishikurakeisuke on 2018/09/14.
//  Copyright © 2018年 ishikurakeisuke. All rights reserved.
//

import UIKit

class MultipeerConnectivityViewController: UIViewController {
    
    var peerUtil = PeerUtil.app()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peerUtil?.delegate = self
        
    }
    
    @IBAction func pushBrowsingBtn(_ sender: Any) {
        
        peerUtil?.browsering()
        
    }
    
    @IBAction func pushAdvertisingBtn(_ sender: Any) {
        
        peerUtil?.advertise()
        
    }
    
}

extension MultipeerConnectivityViewController: PeerDelegate {
    
    func peerConnected(displayName: String) {
        
        DispatchQueue.main.async {

            let alert = UIAlertController(title: "Info", message: "MultipeerConnect ok", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { _ in

                self.performSegue(withIdentifier: "toNextPage", sender: nil)

            }))

            self.present(alert, animated: true, completion: nil)

        }
        
    }
    
}
