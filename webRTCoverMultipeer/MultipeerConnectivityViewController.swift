//
//  MultipeerConnectivityViewController.swift
//  webRTCoverMultipeer
//
//  Created by ishikurakeisuke on 2018/09/14.
//  Copyright © 2018年 ishikurakeisuke. All rights reserved.
//

import UIKit

class MultipeerConnectivityViewController: UIViewController {
    
    var peerUtil:PeerUtil!
    @IBOutlet weak var browsingBtn: UIButton!
    @IBOutlet weak var advertiseBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peerUtil = PeerUtil.app()
        peerUtil.delegate = self
        
        let app = UIApplication.shared.delegate as! AppDelegate

        if app.initiator {
            
            browsingBtn.isHidden = false
            advertiseBtn.isHidden = true
            
        } else {
            
            browsingBtn.isHidden = true
            advertiseBtn.isHidden = false

        }

    }
    
    @IBAction func pushBrowsingBtn(_ sender: Any) {
        
        peerUtil.browsing()
        
    }
    
    @IBAction func pushAdvertisingBtn(_ sender: Any) {
        
        peerUtil.advertise()
        
    }
    
}

extension MultipeerConnectivityViewController: PeerDelegate {
    
    func peerConnected(displayName: String) {
        
        DispatchQueue.main.async {

            let alert = UIAlertController(title: "Info", message: "MultipeerConnect ok", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.default, handler: { _ in

                self.performSegue(withIdentifier: "toNextPage", sender: nil)

            }))

            self.present(alert, animated: true, completion: nil)

        }
        
    }
    
}
