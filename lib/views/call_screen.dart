
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/signalling_service.dart';
import '../commons/show_dialog.dart';
import '../helpers/web-rtc_helper.dart';

class CallScreen extends StatefulWidget {
  final String callerId, calleeId;
  late int? callId;
  final dynamic offer;

  CallScreen({
    super.key,
    this.callId,
    this.offer,
    required this.callerId,
    required this.calleeId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final SupabaseClient client = Supabase.instance.client;

  // videoRenderer for localPeer
  final _localRTCVideoRenderer = RTCVideoRenderer();

  // videoRenderer for remotePeer
  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  // mediaStream for localPeer
  MediaStream? _localStream;

  // RTC peer connection
  RTCPeerConnection? _rtcPeerConnection;

  // media status
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;

  @override
  void initState() {
    // initializing renderers
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();

    // setup Peer Connection
    _setupPeerConnection();

    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  _setupPeerConnection() async {
    // create peer connection
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });

    // listen for remotePeer mediaTrack event
    _rtcPeerConnection!.onTrack = (event) {
      _remoteRTCVideoRenderer.srcObject = event.streams[0];
      setState(() {});
    };

    // get localStream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });

    // add mediaTrack to peerConnection
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    // set source for local video renderer
    _localRTCVideoRenderer.srcObject = _localStream;
    setState(() {});

    // offerがある場合は着信、ない場合は発信する
    if (widget.offer != null) {
      WebRTCHelper(rtcPeerConnection: _rtcPeerConnection!)
          .receiveCall(offer: widget.offer, callId: widget.callId!);
    } else {
       widget.callId = await WebRTCHelper(rtcPeerConnection: _rtcPeerConnection!)
          .makeCall(callerId: widget.callerId, calleeId: widget.calleeId);
    }

    _setCallEndListener(widget.callId);
  }

  void _setCallEndListener(callId){
    client
        .channel("onCallEnded")
        .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: "public",
        table: "calls",
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: callId,
        ),
        callback: (data) async {
          final String status = data.newRecord["status"];
          if(status == "finished"){
            await showOKDialog(
              context: context,
              message: "Call has been finished.",
            );
            if(context.mounted) {
              Navigator.pop(context);
            }
          }
        }).subscribe();
  }

  _leaveCall() async{
    await client.from("calls")
    .update({"status": "finished"})
    .match({"id": widget.callId});
  }

  _toggleMic() {
    // change status
    isAudioOn = !isAudioOn;
    // enable or disable audio track
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }

  _toggleCamera() {
    // change status
    isVideoOn = !isVideoOn;

    // enable or disable video track
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });
    setState(() {});
  }

  _switchCamera() {
    // change status
    isFrontCameraSelected = !isFrontCameraSelected;

    // switch camera
    _localStream?.getVideoTracks().forEach((track) {
      // ignore: deprecated_member_use
      track.switchCamera();
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("P2P Call App"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(children: [
                RTCVideoView(
                  _remoteRTCVideoRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: SizedBox(
                    height: 150,
                    width: 120,
                    child: RTCVideoView(
                      _localRTCVideoRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                )
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(isAudioOn ? Icons.mic : Icons.mic_off),
                    onPressed: _toggleMic,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end),
                    iconSize: 30,
                    onPressed: _leaveCall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch),
                    onPressed: _switchCamera,
                  ),
                  IconButton(
                    icon: Icon(isVideoOn ? Icons.videocam : Icons.videocam_off),
                    onPressed: _toggleCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    super.dispose();
  }
}
