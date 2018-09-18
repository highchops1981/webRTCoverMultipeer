//
//  WebRTCViewController.swift
//  webRTCoverMultipeer
//
//  Created by ishikurakeisuke on 2018/09/14.
//  Copyright © 2018年 ishikurakeisuke. All rights reserved.
//

import WebRTC
import UIKit

class WebRTCViewController: UIViewController {
    
    //webrtc
    @IBOutlet weak var localView: RTCCameraPreviewView!
    @IBOutlet weak var remoteView: RTCMTLVideoView!
    //var   localVideoTrack:RTCVideoTrack?;
    var   remoteVideoTrack:RTCVideoTrack?;
    //var   localVideoSize:CGSize?;
    //var   remoteVideoSize:CGSize?;
    var webrtcUtil:WebrtcUtil!
    var peerUtil:PeerUtil!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webrtcUtil = WebrtcUtil()
        webrtcUtil.delegate = self
        peerUtil = PeerUtil.app()
        peerUtil.delegate = self
        
    }

    @IBAction func pushConnectBtn(_ sender: Any) {
        
        webrtcUtil.startWebrtcConnection()
        remoteView?.delegate = self
        
    }
    @IBAction func pushDisconnectBtn(_ sender: Any) {
    }
}

extension WebRTCViewController: PeerDelegate {
    func receivedOffer2(dictionary:[String: Any]) {
        let sdp = dictionary["sdp"] as! String
        print("pass4\(sdp)")
        print("RTCSdpType.offer\(RTCSdpType.offer)")
        let offerSDP = RTCSessionDescription.init(type: RTCSdpType.offer, sdp: sdp)
        print("pass3\(offerSDP)")
        self.webrtcUtil.remoteSDP = offerSDP
        self.webrtcUtil.createAnswer()
    }
    
    func receivedAnswer2(dictionary:[String: Any]) {
        let sdp = dictionary["sdp"] as! String
        let answerSDP = RTCSessionDescription.init(type: RTCSdpType.answer, sdp: sdp)
        self.webrtcUtil.remoteSDP = answerSDP
        self.webrtcUtil.setAnswerSDP()
    }
    
    func receivedCandidate2(dictionary:[String: Any]) {
        let description = dictionary["candidate"] as! String
        let sdpMLineIndex = dictionary["sdpMLineIndex"] as! Int32
        let sdpMid = dictionary["sdpMid"] as! String
        let iceCandidate = RTCIceCandidate.init(sdp: description, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
        self.webrtcUtil.setICECandidates(iceCandidate: iceCandidate)
    }
    
    func receivedOffer(data:MultiPeer) {
        print("receivedOffer")
        let description = data.offerSdp["offerSDP"] as! String
        print("\(description)")
        let offerSDP = RTCSessionDescription.init(type: RTCSdpType.offer, sdp: description)
        self.webrtcUtil.remoteSDP = offerSDP
        self.webrtcUtil.createAnswer()
    }
    
    func receivedAnswer(data:MultiPeer) {
        print("receivedAnswer")
        let description = data.answerSdp["answerSDP"] as! String
        print("\(description)")
        let answerSDP = RTCSessionDescription.init(type: RTCSdpType.answer, sdp: description)
        self.webrtcUtil.remoteSDP = answerSDP
        self.webrtcUtil.setAnswerSDP()
    }
    
    func receivedCandidate(data:MultiPeer) {
        print("receivedCandidate")
        let description = data.candidateSdp["iceCandidate"] as! String
        let sdpMLineIndex = data.candidateSdp["sdpMLineIndex"] as! Int32
        let sdpMid = data.candidateSdp["sdpMid"] as! String
        print("\(description)")
        print("\(sdpMLineIndex)")
        print("\(sdpMid)")
        let iceCandidate = RTCIceCandidate.init(sdp: description, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
        print("init RTCIceCandidate")
        print("\(iceCandidate)")
        self.webrtcUtil.setICECandidates(iceCandidate: iceCandidate)
    }
    
    func receivedDisconnected(data:MultiPeer) {
        
    }
    
}

extension WebRTCViewController: RTCEAGLVideoViewDelegate {
    
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        
    }
}

extension WebRTCViewController: WebrtcDelegate {
    
    func setLocalView(session: AVCaptureSession) {
        
        DispatchQueue.main.async {
            self.localView.captureSession = session
        }
        
    }
    
    func setRemoteVideoTrack(videoTrack: RTCVideoTrack) {
        print("videoTrack\(videoTrack)")
        DispatchQueue.main.async {
            self.remoteVideoTrack = videoTrack
            self.remoteView.renderFrame(nil)
            self.remoteVideoTrack?.add(self.remoteView)            
        }
        
    }

    func remoteStreamAvailable(stream: RTCMediaStream) {
        print("remoteStreamAvailable\(stream.videoTracks.count)");
        DispatchQueue.main.async {
            let remoteVideoTrack = stream.videoTracks.first
            //            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            //                let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
            //                do{
            //                    try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            //                }
            //                catch{
            //                    print("Audio Port Error");
            //                }
            //            }
            print("self.remoteView.frame\(self.remoteView.frame)")
            self.remoteVideoTrack = nil
            self.remoteView.renderFrame(nil)
            self.remoteVideoTrack = remoteVideoTrack
            self.remoteVideoTrack?.add(self.remoteView)
        }
    }
    
    func offerSDPCreated(sdp:RTCSessionDescription) {
        //let peerSignage = MultiPeer(offerSdp: ["offerSDP":sdp.sdp])
        //peerUtil?.send(peerSignage: peerSignage)
        
        let dic = [
            "type":"offer",
            "sdp":sdp.sdp
        ] as [String : Any]
        
        let json = ["offerSDP":dic]
        peerUtil?.send2(json: json)
        
    }
    
    func answerSDPCreated(sdp:RTCSessionDescription){
//        let peerSignage = MultiPeer(answerSdp: ["answerSDP":sdp.sdp])
//        peerUtil?.send(peerSignage: peerSignage)
        
        let dic = [
            "type":"answer",
            "sdp":sdp.sdp
        ] as [String : Any]
        
        let json = ["answerSDP":dic]
        peerUtil?.send2(json: json)
    }
    
    func iceCandidatesCreated(candidate:RTCIceCandidate){
        print("iceCandidatesCreated\(candidate)")
//        let peerSignage = MultiPeer(candidateSdp: ["iceCandidate":candidate.sdp,"sdpMid":candidate.sdpMid!,"sdpMLineIndex":candidate.sdpMLineIndex])
//        peerUtil?.send(peerSignage: peerSignage)
        
        let adpMid = candidate.sdpMid!
        
        let dic = [
            "type":"candidate",
            "sdpMLineIndex":candidate.sdpMLineIndex,
            "sdpMid":adpMid,
            "candidate":candidate.sdp
        ] as [String : Any]
        
        let json = ["iceCandidate":dic]
        peerUtil?.send2(json: json)
    }
    
    func sendDisconnectToPeer(){
        let peerSignage = MultiPeer(disconnectWebRTC: ["disconnect":"disconnect"])
        peerUtil?.send(peerSignage: peerSignage)
    }
    
    func dataReceivedInChannel(data: NSData) {
    }
    
}
