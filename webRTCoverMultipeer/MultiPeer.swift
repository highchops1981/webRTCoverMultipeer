//
//  MultiPeer.swift
//  PackeT-SBX-iOS
//
//  Created by keisuke ishikura on 2018/08/02.
//  Copyright © 2018年 SoftBank. All rights reserved.
//

import Foundation
import Wrap
import Unbox

enum MultiPeerDataType: String {
    case offerOfWebRTC = "offerofwebrtc"
    case candidateOfWebRTC = "candidateofwebrtc"
    case answerOfWebRTC = "answerofwebrtc"
    case disconnectOfWebRTC = "disconnectofwebrtc"
}

struct MultiPeer {
    
    let dataType: String
    var offerSdp: [String:Any] = [:]
    var answerSdp: [String:Any] = [:]
    var candidateSdp: [String:Any] = [:]
    var disconnectWebRTC: [String:String] = [:]
    
    // webRTC offer
    init(offerSdp: [String:Any]) {
        
        self.dataType = MultiPeerDataType.offerOfWebRTC.rawValue
        self.offerSdp = offerSdp
        
    }
    
    // webRTC candidate
    init(candidateSdp: [String:Any]) {
        
        self.dataType = MultiPeerDataType.candidateOfWebRTC.rawValue
        self.candidateSdp = candidateSdp
    
    }
    
    // webRTC answer
    init(answerSdp: [String:Any]) {
        
        self.dataType = MultiPeerDataType.answerOfWebRTC.rawValue
        self.answerSdp = answerSdp
        
    }
    
    // webRTC disconnect
    init(disconnectWebRTC: [String:String]) {
        
        self.dataType = MultiPeerDataType.disconnectOfWebRTC.rawValue 
        self.disconnectWebRTC = disconnectWebRTC
        
    }
    
}

extension MultiPeer: WrapCustomizable {}

extension MultiPeer: Unboxable {
    init(unboxer: Unboxer) throws {
        self.dataType = try unboxer.unbox(key: "dataType")
        self.offerSdp = try unboxer.unbox(key: "offerSdp")
        self.answerSdp = try unboxer.unbox(key: "answerSdp")
        self.candidateSdp = try unboxer.unbox(key: "candidateSdp")
        self.disconnectWebRTC = try unboxer.unbox(key: "disconnectWebRTC")
        
    }
}

