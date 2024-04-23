import 'package:flutter/material.dart';
import 'package:sample_supabase_webrtc/views/user_list_screen.dart';

import '../models/users.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreen();
}

class _JoinScreen extends State<JoinScreen> {

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          title: const Text("Supabase × WebRTC Demo App"),
        ),
        body: Container(
          padding: const EdgeInsets.all(50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter your username',
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                child: const Text("Join"),
                onPressed: () async {
                  UserModel userModel = await UserModel.add(name: controller.text);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              UserListScreen(myUserModel: userModel)));
                },
              ),
            ],
          ),
        ));
  }
}
