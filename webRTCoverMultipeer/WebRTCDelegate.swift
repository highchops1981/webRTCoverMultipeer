import Foundation
import AVFoundation
import WebRTC

protocol WebrtcDelegate {
    
    func offerSDPCreated(sdp:RTCSessionDescription)
    //    func localStream(stream:RTCMediaStream)
    func remoteStreamAvailable(stream:RTCMediaStream)
    func answerSDPCreated(sdp:RTCSessionDescription)
    func iceCandidatesCreated(candidate:RTCIceCandidate)
    func dataReceivedInChannel(data:NSData)
    func setLocalView(session: AVCaptureSession)
    func setRemoteVideoTrack(videoTrack: RTCVideoTrack)
    
}

class WebrtcUtil: NSObject {
    
    var peerConnection:RTCPeerConnection?
    var peerConnectionFactory:RTCPeerConnectionFactory?
    var videoCapturer:RTCCameraVideoCapturer? //RTCVideoCapturer
    var videoSource:RTCVideoSource?
    var localAudioTrack:RTCAudioTrack?
    var localVideoTrack:RTCVideoTrack?
    var localSDP:RTCSessionDescription?
    var remoteSDP:RTCSessionDescription?
    var delegate:WebrtcDelegate?
    var localStream:RTCMediaStream?
    var unusedICECandidates:[RTCIceCandidate] = []
    var initiator = true
    
    override init() {
        super.init()
        peerConnectionFactory = RTCPeerConnectionFactory.init()
        let iceServer = RTCIceServer.init(urlStrings: ["stun:stun.l.google.com:19302"])
        let configuration = RTCConfiguration.init()
        configuration.iceServers = [iceServer]
        configuration.sdpSemantics = RTCSdpSemantics.unifiedPlan
        configuration.certificate = RTCCertificate.generate(withParams: ["expires":10000,"name":"RSASSA-PKCS1-v1_5"])
        let constraints = RTCMediaConstraints.init(mandatoryConstraints: ["OfferToReceiveAudio":"false","OfferToReceiveVideo":"true"], optionalConstraints: ["DtlsSrtpKeyAgreement" : "true"])
        //let constraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = peerConnectionFactory?.peerConnection(with: configuration, constraints: constraints, delegate: self)
    }
    
    func addLocalMediaStream(){
        
        print("addLocalMediaStream")

        videoSource = self.peerConnectionFactory?.videoSource()
        localVideoTrack = self.peerConnectionFactory?.videoTrack(with: self.videoSource!, trackId: "ARDAMSv0")
        //localAudioTrack = self.peerConnectionFactory?.audioTrack(withTrackId: "ARDAMSa0")
        
//        localStream = peerConnectionFactory?.mediaStream(withStreamId: "ARDAMS")
//        localStream?.addVideoTrack(localVideoTrack!)
//        peerConnection?.add(localStream!)
        peerConnection?.add(localVideoTrack!, streamIds: ["ARDAMS"])
        
        for transceiver in (peerConnection?.transceivers)! {
            print("pass10")
            if transceiver.mediaType == RTCRtpMediaType.video {
                print("pass10")
                delegate?.setRemoteVideoTrack(videoTrack: transceiver.receiver.track as! RTCVideoTrack)
            }
        }

        videoCapturer = RTCCameraVideoCapturer(delegate: self)
        let captureDevices = RTCCameraVideoCapturer.captureDevices()
        for captureDevice in captureDevices {
            if captureDevice.position == AVCaptureDevice.Position.front {
                let format = captureDevice.formats.first
                let fps = format?.videoSupportedFrameRateRanges.first
                videoCapturer?.startCapture(with: captureDevice, format: format!, fps: Int(fps!.maxFrameRate))
                delegate?.setLocalView(session: (videoCapturer?.captureSession)!)
            }
        }
        
        if self.initiator {

            self.createOffer()

        } else {

            print("self.remoteSDP\(String(describing: self.remoteSDP))")
            self.peerConnection!.setRemoteDescription(self.remoteSDP!) { (error) in
                self.setSessionDescription(error: error)
            }

        }

    }
    
    func startWebrtcConnection(){
        if (initiator){
            addLocalMediaStream()
        }
        else{
            waitForAnswer()
        }
    }
    
    func createOffer(){
        let offerContratints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio":"false","OfferToReceiveVideo":"true"], optionalConstraints: nil)
        self.peerConnection?.offer(for: offerContratints) { (sdp, error) in
            self.peerConnection(didCreateSessionDescription: sdp, error: error)
        }
    }
    
    func waitForAnswer(){
    }
    
    func createAnswer(){
        DispatchQueue.main.async {
            self.addLocalMediaStream()
        }
    }
    
    func setAnswerSDP(){
        DispatchQueue.main.async {
            self.peerConnection!.setRemoteDescription(self.remoteSDP!) { (error) in
                self.setSessionDescription(error: error)
            }
            self.addUnusedIceCandidates()
        }
    }
    
    func setICECandidates(iceCandidate:RTCIceCandidate){
        DispatchQueue.main.async {
            print("self.peerConnection\(String(describing: self.peerConnection))")
            self.peerConnection?.add(iceCandidate)
        }
    }
    
    func addUnusedIceCandidates(){
        for (iceCandidate) in self.unusedICECandidates{
            print("added unused ices")
            self.peerConnection?.add(iceCandidate)
        }
        self.unusedICECandidates = []
    }
    
    func peerConnection(didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
        print("didCreateSessionDescription")
        if let er = error {
            print(er.localizedDescription)
        }
        if(sdp == nil) {
            print("Problem creating SDP - \(sdp)")
        } else {
            
            print("SDP created -: \(sdp)")
        }
        self.localSDP = sdp
        self.peerConnection?.setLocalDescription(sdp) { (error) in
            if error != nil {
                print("setLocalDescription error\(String(describing: error))")
                return
            } else {
                if (self.initiator){
                    self.delegate?.offerSDPCreated(sdp: sdp)
                }
                else{
                    self.delegate?.answerSDPCreated(sdp: sdp)
                }
            }
        }
        
    }
    
    func setSessionDescription(error: Error!) {
        print("didSetSessionDescriptionWithError")
        if error != nil{
            print("sdp error \(error.localizedDescription) \(error)")
        }
        else{
            print("SDP set success")
            if initiator == false && self.localSDP == nil{
                
                let answerConstraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio":"false","OfferToReceiveVideo":"true"], optionalConstraints: nil)
                self.peerConnection!.answer(for: answerConstraints) { (sdp, error) in
                    self.peerConnection(didCreateSessionDescription: sdp, error: error)
                }
            }
        }
    }
    
    // Called when the data channel state has changed.
    func channelDidChangeState(channel:RTCDataChannel){
        
    }
    
    func channel(channel: RTCDataChannel!, didReceiveMessageWithBuffer buffer: RTCDataBuffer!) {
        self.delegate?.dataReceivedInChannel(data: buffer.data as NSData)
    }
    
    func disconnect(){
        self.peerConnection?.close()
    }
}

// RTCPeerConnectionDelegate
extension WebrtcUtil: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("PEER CONNECTION:- didAdd stream")
        //self.delegate?.remoteStreamAvailable(stream: stream)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("PEER CONNECTION:- didGenerate candidate")
        self.delegate?.iceCandidatesCreated(candidate: candidate)
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("PEER CONNECTION:- peerConnectionShouldNegotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
        print("PEER CONNECTION:- didAdd rtpReceiver")
        //self.delegate?.remoteStreamAvailable(stream: mediaStreams.first!)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove rtpReceiver: RTCRtpReceiver) {
        print("PEER CONNECTION:- didRemove rtpReceiver")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("PEER CONNECTION:- didRemove candidates")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("PEER CONNECTION:- Signaling State Changed \(stateChanged.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didStartReceivingOn transceiver: RTCRtpTransceiver) {
        print("PEER CONNECTION:- didStartReceivingOn transceiver")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("PEER CONNECTION:- didRemove stream")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("PEER CONNECTION:- didOpen dataChannel")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("PEER CONNECTION:- ICE Gathering Changed - \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("PEER CONNECTION:- ICE Connection Changed \(newState.rawValue)")
    }
    
}

// RTCVideoCapturerDelegate
extension WebrtcUtil: RTCVideoCapturerDelegate {
    
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        
        
        //if self.localSDP == nil {
        //RTCVideoCapturerがRTCCameraVideoCapturerになっていてこのメソッドが呼ばれなかった。
           // self.videoSource = self.peerConnectionFactory?.videoSource()
           // self.videoSource?.capturer(capturer, didCapture: frame)
        //self.localVideoTrack = self.peerConnectionFactory?.videoTrack(with: self.videoSource!, trackId: "ARDAMSv0")
         //localStream = peerConnectionFactory?.mediaStream(withStreamId: "ARDAMS")
        //localStream?.addVideoTrack(localVideoTrack!)
//        localAudioTrack = peerConnectionFactory?.audioTrack(withTrackId: "ARDAMSa0")
//        localStream?.addAudioTrack(localAudioTrack!)
        //peerConnection?.add(localStream!)
            
        
       //self.peerConnection?.add(self.localVideoTrack!, streamIds: ["ARDAMS"])

//            if self.initiator {
//
//                self.createOffer()
//
//            } else {
//
//                print("pass1")
//                self.peerConnection!.setRemoteDescription(self.remoteSDP!) { (error) in
//                    print("pass3")
//                    self.setSessionDescription(error: error)
//                }
//
//            }
        //}
        
        
        //delegate?.localStream(stream: localStream!)
        
    }
}
