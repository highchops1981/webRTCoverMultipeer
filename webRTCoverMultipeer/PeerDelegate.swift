import Foundation
import MultipeerConnectivity
import AVFoundation


import Wrap
import Unbox

protocol PeerDelegate {
    
    func peerFound(displayName:String)
    func peerConnected(displayName:String)
    func peerNotConnected(displayName:String)
    func receivedOffer(data:MultiPeer)
    func receivedAnswer(data:MultiPeer)
    func receivedCandidate(data:MultiPeer)
    func receivedDisconnected(data:MultiPeer)
    
}

extension PeerDelegate {
    
    func peerFound(displayName:String) {}
    func peerConnected(displayName:String) {}
    func peerNotConnected(displayName:String) {}
    func receivedOffer(data:MultiPeer) {}
    func receivedAnswer(data:MultiPeer) {}
    func receivedCandidate(data:MultiPeer) {}
    func receivedDisconnected(data:MultiPeer) {}
    
}

class PeerUtil:NSObject {
    
    var delegate: PeerDelegate?
    var webRTCdelegate: PeerDelegate?
    
    var numOfCapture = 0
    var displayName: String = ""
    var serviceType: String = ""
    var peerId: MCPeerID? = nil
    var remotePeerId : MCPeerID? = nil
    var session: MCSession? = nil
    var advertiserAssistant: MCAdvertiserAssistant? = nil
    //var advertiserNearby: MCNearbyServiceAdvertiser? = nil
    var browser: MCNearbyServiceBrowser? = nil
    var nowConnect: Bool {
        get {
            
            if let se = session {
                
                if se.connectedPeers.count > 0 {
                    return true
                } else {
                    return false
                }
            }
            
            return false
            
        }
        
    }
    
    static func app() -> PeerUtil? {
        
        let app = UIApplication.shared.delegate as! AppDelegate
        return app.peerUtil
        
    }
    
    func setting(displayName: String, serviceType: String) {
        
        self.displayName = displayName
        self.serviceType = serviceType
        peerId = MCPeerID(displayName: self.displayName)
        session = MCSession(peer: self.peerId!, securityIdentity: nil, encryptionPreference: .optional)
        advertiserAssistant = MCAdvertiserAssistant(serviceType: self.serviceType, discoveryInfo: nil, session: self.session!)
        //advertiserNearby = MCNearbyServiceAdvertiser(peer: peerId!, discoveryInfo: nil, serviceType: self.serviceType)
        browser = MCNearbyServiceBrowser(peer: self.peerId!, serviceType: self.serviceType)
        
    }
    
    func advertise() {
        
        session?.delegate = self
        advertiserAssistant?.delegate = self
        advertiserAssistant?.start()
//        advertiserNearby?.delegate = self
//        advertiserNearby?.startAdvertisingPeer()
        
    }
    
    func browsering() {
        
        session?.delegate = self
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
    }
    
    func stopAdvertise() {
        
        advertiserAssistant?.stop()
        //advertiserNearby?.stopAdvertisingPeer()
        
    }
    
    func stopBrowsering() {
        
        browser?.stopBrowsingForPeers()
        
    }
    
    func sessionDisconnect() {
        
        session?.disconnect()
        
    }
    
    func sessionInvite() {
        
        guard let peerId = remotePeerId else {
            return
        }
        browser?.invitePeer(peerId, to: session!, withContext: nil, timeout: 0)
        
    }
    
    func send(peerSignage: MultiPeer) {
        
        let wrappedDictionary: WrappedDictionary = try! wrap(peerSignage)
        
        if JSONSerialization.isValidJSONObject(wrappedDictionary) {
            
            let serializationData: Data = try! JSONSerialization.data(withJSONObject: wrappedDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
            
            try? session?.send(serializationData, toPeers: (session?.connectedPeers)!, with: .reliable)
            
        }
        
    }
    
}

extension PeerUtil: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        print("foundPeer::\(peerID.displayName)")
        
        remotePeerId = peerID
        delegate?.peerFound(displayName: peerID.displayName)
        stopBrowsering()
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 0)
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        // advertise -> 落ちる、バックグラウンド、browsing ->受信
        print("lostPeer::\(peerID.displayName)")
        
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        
        print("didNotStartBrowsingForPeers:::\(error.localizedDescription)")
        
    }
    
}

extension PeerUtil: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Swift.Void) {

        invitationHandler(true,session)

    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        
        
    }
}

extension PeerUtil: MCSessionDelegate {
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
            delegate?.peerConnected(displayName: peerID.displayName)
            
            stopAdvertise()
            
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .notConnected:
            print("Not Connected: \(peerID.displayName)")
            
            sessionDisconnect()
            delegate?.peerNotConnected(displayName: peerID.displayName)
            
        }
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        do {
            
            let dic = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let model: MultiPeer = try unbox(dictionary: dic!)
            switch model.dataType {
            case MultiPeerDataType.offerOfWebRTC.rawValue:
                
                delegate?.receivedOffer(data: model)
                
            case MultiPeerDataType.answerOfWebRTC.rawValue:
                
                delegate?.receivedAnswer(data: model)
                
            case MultiPeerDataType.candidateOfWebRTC.rawValue:
                
                delegate?.receivedCandidate(data: model)
                
            case MultiPeerDataType.disconnectOfWebRTC.rawValue:

                delegate?.receivedDisconnected(data: model)
                
            default: break
            }
            
            
        } catch {
        }
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
}

extension PeerUtil: MCAdvertiserAssistantDelegate {
    
    
//    optional public func advertiserAssistantWillPresentInvitation(_ advertiserAssistant: MCAdvertiserAssistant)
//
//
//    // An invitation was dismissed from screen.
//    @available(iOS 7.0, *)
//    optional public func advertiserAssistantDidDismissInvitation(_ advertiserAssistant: MCAdvertiserAssistant)
}
