import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String photoUrl;
  final String? nickname;
  final String email;
  final bool isOnline;

  const AppUser({
    required this.id,
    required this.name,
    required this.photoUrl,
    this.nickname,
    this.email = '',
    this.isOnline = false,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      name: (data['name'] ?? 'Unknown').toString(),
      photoUrl: (data['photoUrl'] ?? '').toString(),
      nickname: (data['nickname'] ?? '').toString().isEmpty 
          ? null 
          : (data['nickname'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      isOnline: (data['isOnline'] ?? false) == true,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: (data['name'] ?? 'Unknown').toString(),
      photoUrl: (data['photoUrl'] ?? '').toString(),
      nickname: (data['nickname'] ?? '').toString().isEmpty 
          ? null 
          : (data['nickname'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      isOnline: (data['isOnline'] ?? false) == true,
    );
  }
}
