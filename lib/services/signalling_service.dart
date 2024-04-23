import 'package:flutter/material.dart';
import 'package:sample_supabase_webrtc/models/users.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../commons/show_dialog.dart';
import '../views/call_screen.dart';

class SignallingService {
  SignallingService._();

  static final instance = SignallingService._();
  BuildContext? context;
  UserModel? userModel;

  void init({required BuildContext context, required UserModel userModel}) {
    this.context = context;
    this.userModel = userModel;
    // callsテーブル上でcalleeIdが自分のレコードが挿入されるかをリッスンする
    Supabase.instance.client
        .channel("onIncomingCall")
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: "public",
            table: "calls",
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'callee_id',
              value: userModel.id,
            ),
            callback: (data) {
              // handle the incoming call
              final int callId = data.newRecord["id"];
              final String? callerId = data.newRecord['caller_id'];
              final Map<String, dynamic>? sdpOffer =
                  data.newRecord['sdp_offer'];

              if (callerId != null && sdpOffer != null) {
                _handleIncomingCall(callId, callerId, sdpOffer);
              }
            })
        .subscribe();
  }

  void _handleIncomingCall(
      int callId, String callerId, Map<String, dynamic> sdpOffer) async {
    UserModel userModel = await UserModel.get(id: callerId);
    final bool result = await showOKCancelDialog(
      context: context!,
      message: "Calling from ${userModel.name}\nDo you want to join the call?",
    );

    if (result == true && context!.mounted) {
      Navigator.push(
        context!,
        MaterialPageRoute(
          builder: (BuildContext context) => CallScreen(
            callId: callId,
            callerId: callerId,
            calleeId: this.userModel!.id,
            offer: sdpOffer,
          ),
        ),
      );
    }
  }
}
