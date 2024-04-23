import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String name;
  final DateTime createdAt;
  static final SupabaseClient client = Supabase.instance.client;

  UserModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory UserModel.fromMap(
    Map<String, dynamic> data,
  ) {
    return UserModel(
      id: data["id"],
      name: data['name'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
    };
  }

  static Future<UserModel> get({required String id}) async{
    Map<String, dynamic> result =
        await client.from("users").select().match({"id": id}).single();
    return UserModel.fromMap(result);
  }

  static Future<List<UserModel>> getAll({required String myId}) async{
    List<Map<String, dynamic>> result =
    await client.from("users").select().neq("id", myId);
    return result.map((Map<String, dynamic> map) => UserModel.fromMap(map)).toList();
  }

  static Future<UserModel> add({required String name}) async {
    Map<String, dynamic> result =
        await client.from("users").insert({"name": name}).select().single();
    return UserModel.fromMap(result);
  }

  static void remove({required String id}) async {
    await client.from("users").delete().match({"id": id});
  }
}
