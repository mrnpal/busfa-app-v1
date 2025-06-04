import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Berhasil',
        'Link reset password telah dikirim ke email Anda',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      _emailController.clear();
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'Email tidak terdaftar';
      } else {
        errorMessage = 'Terjadi kesalahan: ${e.message}';
      }
      Get.snackbar(
        'Gagal',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan yang tidak diketahui',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lupa Password'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Image.asset(
                    'assets/images/forgot_password.jpg',
                    height: MediaQuery.of(context).size.height * 0.4,
                    // fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 32),

                const SizedBox(height: 8),
                FadeInUp(
                  duration: const Duration(milliseconds: 1300),
                  child: Text(
                    'Masukkan email Anda yang terdaftar, kami akan mengirimkan link untuk reset password',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(milliseconds: 1600),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.lightGreen.shade700,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Masukkan email yang valid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(milliseconds: 1800),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                            : const Text(
                              'Kirim Link Reset',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
