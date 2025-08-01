import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Fungsi untuk mendaftarkan alumni baru ke koleksi pendingUsers (menunggu verifikasi admin)
Future<String> registerAlumni({
  required String email,
  required String password,
  required String name,
  required String phone,
  String? photoUrl,
}) async {
  try {
    // Membuat akun user di Firebase Auth
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final uid = credential.user!.uid;

    // Menyimpan data user ke koleksi pendingUsers (belum diverifikasi admin)
    await FirebaseFirestore.instance.collection('pendingUsers').doc(uid).set({
      'uid': uid,
      // 'indukNumber': indukNumber,
      'email': email,
      'name': name,
      'phone': phone,

      'photoUrl': photoUrl,
    });

    // Berhasil, user harus menunggu verifikasi admin
    return 'Pendaftaran berhasil. Tunggu verifikasi admin.';
  } on FirebaseAuthException catch (e) {
    // Error dari Firebase Auth (misal email sudah terdaftar)
    return e.message ?? 'Terjadi kesalahan';
  } catch (e) {
    // Error lain
    return 'Gagal mendaftar: $e';
  }
}

// Fungsi login alumni, hanya bisa login jika sudah diverifikasi admin
Future<String?> loginAlumni(String email, String password) async {
  try {
    // Login ke Firebase Auth
    UserCredential credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    String uid = credential.user!.uid;

    // Mengecek status verifikasi admin di koleksi users
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // Jika belum diverifikasi, logout dan tampilkan pesan
    if (!doc.exists || doc.data()?['isVerified'] != true) {
      await FirebaseAuth.instance.signOut();
      return 'Akun belum diverifikasi oleh admin.';
    }

    // Berhasil login
    return null;
  } on FirebaseAuthException catch (e) {
    // Error login (email/password salah, user tidak ditemukan, dll)
    String errorMsg = "Login gagal!";
    if (e.code == 'user-not-found') {
      errorMsg = "Email tidak terdaftar.";
    } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
      errorMsg = "Password salah.";
    }
    return errorMsg;
  }
}
