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
    var initiator = false
    
    override init() {
        super.init()
        peerConnectionFactory = RTCPeerConnectionFactory.init()
        let iceServer = RTCIceServer.init(urlStrings: ["stun:stun.l.google.com:19302"])
        let configuration = RTCConfiguration.init()
        //configuration.iceServers = [iceServer]
        configuration.iceServers = [iceServer]
        configuration.sdpSemantics = RTCSdpSemantics.unifiedPlan
        configuration.certificate = RTCCertificate.generate(withParams: ["expires":10000,"name":"RSASSA-PKCS1-v1_5"])
        let constraints = RTCMediaConstraints.init(mandatoryConstraints: ["OfferToReceiveAudio":"false","OfferToReceiveVideo":"true"], optionalConstraints: ["DtlsSrtpKeyAgreement" : "true"])
//        let constraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = peerConnectionFactory?.peerConnection(with: configuration, constraints: constraints, delegate: self)
        
        let app = UIApplication.shared.delegate as! AppDelegate
        initiator = app.initiator

    }
    
    //
    func addData() {
        print("addData")
        let configuration = RTCDataChannelConfiguration.init()
        peerConnection?.dataChannel(forLabel: "sample", configuration: configuration)
        
    }
    
    func addLocalMediaStream(){
        
        videoSource = self.peerConnectionFactory?.videoSource()
        localVideoTrack = self.peerConnectionFactory?.videoTrack(with: self.videoSource!, trackId: "MARDAMSv0")
        //localAudioTrack = self.peerConnectionFactory?.audioTrack(withTrackId: "ARDAMSa0")
        
//        localStream = peerConnectionFactory?.mediaStream(withStreamId: "ARDAMS")
//        localStream?.addVideoTrack(localVideoTrack!)
//        peerConnection?.add(localStream!)
        peerConnection?.add(localVideoTrack!, streamIds: ["MARDAMS"])
        
        for transceiver in (peerConnection?.transceivers)! {
            if transceiver.mediaType == RTCRtpMediaType.video {
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
        
        if initiator {

            self.createOffer()

        } else {

            self.peerConnection!.setRemoteDescription(self.remoteSDP!) { [weak self] (error) in
                guard let self = self else {return}
                self.setSessionDescription(error: error)
                self.addUnusedIceCandidates()
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
        self.peerConnection?.offer(for: offerContratints) { [weak self] (sdp, error) in
            guard let self = self else {return}
            self.peerConnection(peer:self.peerConnection!,didCreateSessionDescription: sdp, error: error)
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
            print("setAnswerSDP")
            self.peerConnection!.setRemoteDescription(self.remoteSDP!) { [weak self] (error) in
                guard let self = self else {return}
                self.setSessionDescription(error: error)
                self.addUnusedIceCandidates()
            }
            
        }
    }
    
    func setICECandidates(iceCandidate:RTCIceCandidate){
        if peerConnection?.remoteDescription != nil {
            DispatchQueue.main.async {
                print("add iceCandidate")
                self.peerConnection?.add(iceCandidate)
            }
        } else {
            print("store iceCandidate")
            unusedICECandidates.append(iceCandidate)
        }
    }
    
    func addUnusedIceCandidates(){
        for (iceCandidate) in unusedICECandidates{
            print("add iceCandidate")
            self.peerConnection?.add(iceCandidate)
        }
        unusedICECandidates = []
    }
    
    func peerConnection(peer:RTCPeerConnection, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
        DispatchQueue.main.async {
            if let er = error {
                print(er.localizedDescription)
            }
            if(sdp == nil) {
                print("Problem creating SDP - \(String(describing: sdp))")
            } else {
                
                print("SDP created -: \(String(describing: sdp))")
            }
            self.localSDP = sdp
            peer.setLocalDescription(sdp) { [weak self] (error) in
                guard let self = self else {return}
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
    }
    
    func setSessionDescription(error: Error!) {
        if error != nil{
            print("sdp error \(error.localizedDescription) \(String(describing: error))")
        }
        else{
            print("SDP set success")
            if initiator == false && self.localSDP == nil{
                
                let answerConstraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio":"false","OfferToReceiveVideo":"true"], optionalConstraints: nil)
                self.peerConnection!.answer(for: answerConstraints) { [weak self] (sdp, error) in
                    guard let self = self else {return}
                    self.peerConnection(peer:self.peerConnection!,didCreateSessionDescription: sdp, error: error)
                }
            }
        }
    }
    
    // Called when the data channel state has changed.
    func channelDidChangeState(channel:RTCDataChannel){
        
        print("pass2")
        
    }
    
    func channel(channel: RTCDataChannel!, didReceiveMessageWithBuffer buffer: RTCDataBuffer!) {
        self.delegate?.dataReceivedInChannel(data: buffer.data as NSData)
    }
    
    func disconnect(){
        self.peerConnection?.close()
    }
}

//
extension WebrtcUtil: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        
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
        print("PEER CONNECTION:- didOpen dataChannel\(dataChannel.readyState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("PEER CONNECTION:- ICE Gathering Changed - \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("PEER CONNECTION:- ICE Connection Changed \(newState.rawValue)")
        
        if newState.rawValue == 3 {
            addData()
        }
        
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
