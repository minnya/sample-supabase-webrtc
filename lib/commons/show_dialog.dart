import 'dart:async';

import 'package:flutter/material.dart';


Future<bool> showOKDialog({required BuildContext context, required String message,}) {
  return _showAlertDialog(context: context, message: message, showCancelButton: false);
}

Future<bool> showOKCancelDialog({required BuildContext context, required String message,}) {
  return _showAlertDialog(context: context, message: message, showCancelButton: true);
}

// アラートダイアログを表示します
// OKを押した場合trueを、cancelを押した場合falseを返します
Future<bool> _showAlertDialog({
  required BuildContext context,
  required String message,
  bool showCancelButton = true,
}) async {
  bool result = false;

  if(context.mounted) {
    await showDialog(
        context: context,
        builder: (BuildContext context) =>
            AlertDialog(
              content: Text(message),
              actions: [
                showCancelButton
                ?TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel"))
                :const SizedBox(),
                TextButton(
                    onPressed: () async {
                      result = true;
                      Navigator.pop(context);
                    },
                    child: const Text("OK")),
              ],
            ));
  }
  return result;
}
