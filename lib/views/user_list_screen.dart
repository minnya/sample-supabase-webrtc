import 'package:flutter/material.dart';
import 'package:sample_supabase_webrtc/commons/show_dialog.dart';
import 'package:sample_supabase_webrtc/models/users.dart';
import 'package:sample_supabase_webrtc/services/signalling_service.dart';
import 'package:sample_supabase_webrtc/views/call_screen.dart';

class UserListScreen extends StatefulWidget {
  final UserModel myUserModel;

  const UserListScreen({super.key, required this.myUserModel});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {

  @override
  void initState() {
    super.initState();
    SignallingService.instance.init(context: context, userModel: widget.myUserModel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User List"),
        actions: [
          TextButton(
            child: const Text("Refresh"),
            onPressed: () {
              setState(() {
                UserModel.getAll(myId: widget.myUserModel.id);
              });
            },
          ),
        ]
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            UserModel.getAll(myId: widget.myUserModel.id);
          });
        },
        child: WillPopScope(
          onWillPop: () async{
            final bool result = await showOKCancelDialog(context: context, message: "Do you want to exit?");
            if(result==true){
              UserModel.remove(id: widget.myUserModel.id);
            }
            return result;
          },
          child: FutureBuilder<List<UserModel>>(
              future: UserModel.getAll(myId: widget.myUserModel.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                List<UserModel> users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Container(
                      margin: const EdgeInsets.all(10),
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primaryContainer,
                      child: ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.id),
                        trailing: ElevatedButton(
                          child: const Text("Call"),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) =>
                                    CallScreen(
                                        callerId: widget.myUserModel.id, calleeId: user.id)));
                          },
                        ),
                      ),
                    );
                  },
                );
              }
          ),
        ),
      ),
    );
  }
}