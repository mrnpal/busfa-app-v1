import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> registerAlumni({
  required String email,
  required String password,
  required String name,
  required String address,
  required String phone,
  required String job,
  required String graduationYear,
  required double latitude,
  required double longitude,
  String? photoUrl,
}) async {
  try {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final uid = credential.user!.uid;

    await FirebaseFirestore.instance.collection('pendingAlumni').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'address': address,
      'phone': phone,
      'job': job,
      'graduationYear': graduationYear,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
    });

    return 'Pendaftaran berhasil. Tunggu verifikasi admin.';
  } on FirebaseAuthException catch (e) {
    return e.message ?? 'Terjadi kesalahan';
  } catch (e) {
    return 'Gagal mendaftar: $e';
  }
}

Future<String?> loginAlumni(String email, String password) async {
  try {
    UserCredential credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    String uid = credential.user!.uid;

    // mengecek apakah alumni sudah diverifikasi oleh admin
    final doc =
        await FirebaseFirestore.instance
            .collection('alumniVerified')
            .doc(uid)
            .get();

    if (!doc.exists || doc.data()?['isVerified'] != true) {
      await FirebaseAuth.instance.signOut();
      return 'Akun belum diverifikasi oleh admin.';
    }

    return null;
  } on FirebaseAuthException catch (e) {
    String errorMsg = "Login gagal!";
    if (e.code == 'user-not-found') {
      errorMsg = "Email tidak terdaftar.";
    } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
      errorMsg = "Password salah.";
    }
    return errorMsg;
  }
}
