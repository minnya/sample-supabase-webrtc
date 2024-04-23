
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebRTCHelper{
  final RTCPeerConnection rtcPeerConnection;
  final SupabaseClient client = Supabase.instance.client;

  WebRTCHelper({required this.rtcPeerConnection});

  void receiveCall({required Map<String, dynamic> offer, required int callId}) async{
    // set SDP offer as remoteDescription for peerConnection
    await rtcPeerConnection.setRemoteDescription(
      RTCSessionDescription(offer["sdp"], offer["type"]),
    );
    // create SDP answer
    RTCSessionDescription answer = await rtcPeerConnection.createAnswer();

    // set SDP answer as localDescription for peerConnection
    rtcPeerConnection.setLocalDescription(answer);
    await client.from("calls")
        .update({
          "status": "picked",
          "sdp_answer": answer.toMap(),
        })
        .match({"id": callId});

    // listen for call answer
    client
        .channel("onIceCandidates")
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
          final iceCandidates = data.newRecord["ice_candidates"];

          if (iceCandidates != null) {
            List listCandidates = data.newRecord["ice_candidates"];
            for (var element in listCandidates) {
              String candidate = element["candidate"];
              String sdpMid = element["sdpMid"];
              int sdpMLineIndex = element["sdpMLineIndex"];

              // add iceCandidate
              rtcPeerConnection.addCandidate(RTCIceCandidate(
                candidate,
                sdpMid,
                sdpMLineIndex,
              ));
            }
          }
        })
        .subscribe();
  }

  Future<int> makeCall({required String callerId, required String calleeId}) async{
    final offer = await rtcPeerConnection.createOffer();

    // set SDP offer as localDescription for peerConnection
    await rtcPeerConnection.setLocalDescription(offer);

    // listen for local iceCandidate and add it to the list of IceCandidate
    List<Map<String, dynamic>> rtcIceCandidates = [];
    rtcPeerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      Map<String, dynamic> candidateMap = {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      };
      rtcIceCandidates.add(candidateMap);
    };

    final sdpOffer = {
      "status": "calling",
      "caller_id": callerId,
      "callee_id": calleeId,
      "sdp_offer": offer.toMap(),
    };

    final result = await client.from("calls").insert(sdpOffer).select();
    final callId = result.first["id"];
    print("callId: $callId");

    // listen for call answer
    client
        .channel("onAnswered")
        .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: "public",
        table: "calls",
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: callId,
        ),
        callback: (data) async{
          final sdpAnswerData = data.newRecord['sdp_answer'];

          if (sdpAnswerData != null) {
            final sdpAnswer = RTCSessionDescription(
              sdpAnswerData['sdp'],
              sdpAnswerData['type'],
            );
            // set SDP answer as remoteDescription for peerConnection
            await rtcPeerConnection.setRemoteDescription(sdpAnswer);

            // send iceCandidate generated to remote peer over signalling
            await client.from("calls")
                .update({"ice_candidates": rtcIceCandidates})
                .match({"id": callId});
          }
        }).subscribe();

    return callId;
  }
}