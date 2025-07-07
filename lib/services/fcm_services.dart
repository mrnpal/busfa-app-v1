import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  // Singleton pattern (optional)
  FCMService._privateConstructor();
  static final FCMService instance = FCMService._privateConstructor();

  // Simpan token pertama kali ke Firestore
  Future<void> saveTokenToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
        print('FCM token disimpan: $token');
      }
    } catch (e) {
      print('Gagal menyimpan token FCM: $e');
    }
  }

  // Listen perubahan token dan update ke Firestore
  void listenToTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': newToken});
        print('Token FCM diperbarui: $newToken');
      }
    });
  }
}
