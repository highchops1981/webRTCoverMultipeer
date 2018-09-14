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
    @IBOutlet weak var remoteView: RTCEAGLVideoView!
    //var   localVideoTrack:RTCVideoTrack?;
    var   remoteVideoTrack:RTCVideoTrack?;
    //var   localVideoSize:CGSize?;
    //var   remoteVideoSize:CGSize?;
    let   webrtcUtil = WebrtcUtil()
    
    var peerUtil = PeerUtil.app()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func pushConnectBtn(_ sender: Any) {
        
        webrtcUtil.delegate = self
        webrtcUtil.startWebrtcConnection()
        remoteView?.delegate = self
        
        peerUtil?.delegate = self
        
    }
    @IBAction func pushDisconnectBtn(_ sender: Any) {
    }
}

extension WebRTCViewController: PeerDelegate {
    
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
    
    func offerSDPCreated(sdp:RTCSessionDescription){
        print("pass0\(sdp)")
        let peerSignage = MultiPeer(offerSdp: ["offerSDP":sdp.sdp])
        peerUtil?.send(peerSignage: peerSignage)
    }
    
    func answerSDPCreated(sdp:RTCSessionDescription){
        let peerSignage = MultiPeer(answerSdp: ["answerSDP":sdp.sdp])
        peerUtil?.send(peerSignage: peerSignage)
    }
    
    func iceCandidatesCreated(candidate:RTCIceCandidate){
        print("iceCandidatesCreated\(candidate)")
        let peerSignage = MultiPeer(candidateSdp: ["iceCandidate":candidate.sdp,"sdpMid":candidate.sdpMid!,"sdpMLineIndex":candidate.sdpMLineIndex])
        peerUtil?.send(peerSignage: peerSignage)
    }
    
    func sendDisconnectToPeer(){
        let peerSignage = MultiPeer(disconnectWebRTC: ["disconnect":"disconnect"])
        peerUtil?.send(peerSignage: peerSignage)
    }
    
    func dataReceivedInChannel(data: NSData) {
    }
    
}