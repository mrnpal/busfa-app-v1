import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

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
            .collection('alumniVerified')
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
        Get.snackbar(
          'Ukuran Gambar Terlalu Besar',
          'Maksimal ukuran gambar adalah 2 MB.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
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

    String? photoUrl = _photoUrl;
    if (_imageFile != null) {
      photoUrl = await _uploadImage(_imageFile!);
    }

    await FirebaseFirestore.instance
        .collection('alumniVerified')
        .doc(user.uid)
        .update({
          'name': _nameController.text.trim(),
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'job': _jobController.text.trim(),
          'photoUrl': photoUrl,
        });
    setState(() => _isLoading = false);
    Get.back();
    Get.snackbar(
      'Berhasil',
      'Profil berhasil diperbarui',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(20),
      borderRadius: 12,
      icon: Icon(Icons.check_circle, color: Colors.white),
    );
  }

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
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // <-- Ubah ke warna biru
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                            'Simpan Perubahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }
}
