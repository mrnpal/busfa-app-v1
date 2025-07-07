import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:busfa_app/utils/lottie_toast.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobController = TextEditingController();

  bool _isLoading = false;
  File? _imageFile;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _addressController.text = data['address'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _jobController.text = data['job'] ?? '';
      _photoUrl = data['photoUrl'];
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.length();
      const maxSize = 2000000;

      if (bytes > maxSize) {
        showLottieToast(
          context: context,
          success: false,
          message: 'Maksimal ukuran gambar adalah 2 MB.',
        );
        return;
      }

      setState(() {
        _imageFile = file;
      });
    }
  }

  Future<String?> _uploadImage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile-images')
        .child('${user.uid}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? photoUrl = _photoUrl;
      if (_imageFile != null) {
        photoUrl = await _uploadImage(_imageFile!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'name': _nameController.text.trim(),
            'address': _addressController.text.trim(),
            'phone': _phoneController.text.trim(),
            'job': _jobController.text.trim(),
            'photoUrl': photoUrl,
          });

      showLottieToast(
        context: context,
        success: true,
        message: 'Profil berhasil diperbarui',
      );
      // Kembali ke halaman sebelumnya setelah delay toast selesai
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) Get.back();
      });
    } catch (e) {
      showLottieToast(
        context: context,
        success: false,
        message: 'Terjadi kesalahan, coba lagi',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Helper method menampilkan toast Lottie di tengah layar
  // void _showLottieToast({required bool success, required String message}) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return Center(
  //         child: Container(
  //           width: 250,
  //           padding: const EdgeInsets.symmetric(
  //             horizontal: 16.0,
  //             vertical: 20.0,
  //           ),
  //           decoration: BoxDecoration(
  //             color: success ? Colors.green : Colors.red,
  //             borderRadius: BorderRadius.circular(20.0),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black26,
  //                 blurRadius: 6,
  //                 offset: Offset(0, 3),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 message,
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w600,
  //                   decoration: TextDecoration.none,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               const SizedBox(height: 12),
  //               if (success)
  //                 SizedBox(
  //                   height: 70,
  //                   child: Lottie.asset(
  //                     'assets/lottie/success.json',
  //                     repeat: false,
  //                   ),
  //                 )
  //               else
  //                 const Icon(
  //                   Icons.error_outline,
  //                   color: Colors.white,
  //                   size: 48,
  //                 ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );

  //   Future.delayed(const Duration(seconds: 3), () {
  //     if (Navigator.canPop(context)) Navigator.pop(context);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade300,
                                Colors.purple.shade300,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                _imageFile != null
                                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                                    : (_photoUrl != null &&
                                            _photoUrl!.isNotEmpty
                                        ? Image.network(
                                          _photoUrl!,
                                          fit: BoxFit.cover,
                                        )
                                        : Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.white,
                                        )),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ubah Foto Profil',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields
              _buildTextField(
                controller: _nameController,
                label: 'Nama Lengkap',
                icon: Icons.person_outline_rounded,
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? 'Wajib diisi'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Alamat',
                icon: Icons.home_outlined,
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? 'Wajib diisi'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'No. HP',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? 'Wajib diisi'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _jobController,
                label: 'Pekerjaan',
                icon: Icons.work_outline_rounded,
                validator:
                    (val) =>
                        val == null || val.trim().isEmpty
                            ? 'Wajib diisi'
                            : null,
              ),
              const SizedBox(height: 32),

              // Save Button
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
    );
  }
}
