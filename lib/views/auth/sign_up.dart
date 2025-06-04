import 'dart:async';
import 'dart:io';
import 'package:busfa_app/maps/map_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import '/services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final jobController = TextEditingController();
  final graduationYearController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? message;
  bool showErrorAnimation = false;
  bool showErrorIcon = false;

  LatLng? selectedLocation;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToStorage() async {
    if (_selectedImage == null) return null;
    final fileName = basename(_selectedImage!.path);
    final ref = FirebaseStorage.instance.ref().child(
      'profile_images/$fileName',
    );
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _selectLocationFromMap() async {
    final location = await Navigator.push<LatLng>(
      this.context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(),
        fullscreenDialog: true,
      ),
    );
    if (location != null) {
      setState(() {
        selectedLocation = location;
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (selectedLocation == null) {
        setState(() {
          message = 'Silakan pilih lokasi di peta';
          showErrorAnimation = true;
          showErrorIcon = true;
        });

        // Reset animasi setelah beberapa detik
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            showErrorAnimation = false;
            showErrorIcon = false;
          });
        });
        return;
      }

      setState(() {
        isLoading = true;
        showErrorAnimation = false;
        showErrorIcon = false;
      });

      final photoUrl = await _uploadImageToStorage();

      final result = await registerAlumni(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        job: jobController.text.trim(),
        graduationYear: graduationYearController.text.trim(),
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
        photoUrl: photoUrl,
      );

      setState(() => isLoading = false);

      if (result == 'Pendaftaran berhasil. Tunggu verifikasi admin.') {
        // Clear form
        emailController.clear();
        passwordController.clear();
        nameController.clear();
        addressController.clear();
        phoneController.clear();
        jobController.clear();
        graduationYearController.clear();
        selectedLocation = null;
        _selectedImage = null;

        // Show success dialog
        showDialog(
          context: this.context,
          builder:
              (context) => AlertDialog(
                backgroundColor: Colors.green[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      "Registrasi Berhasil",
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
                content: Text(
                  result,
                  style: const TextStyle(color: Colors.black87),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.offAll(() => const LoginPage());
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      } else {
        setState(() {
          message = result;
          showErrorAnimation = true;
          showErrorIcon = true;
        });

        // Show error dialog
        showDialog(
          context: this.context,
          builder:
              (context) => AlertDialog(
                backgroundColor: Colors.red[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      "Registrasi Gagal",
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ],
                ),
                content: Text(
                  result,
                  style: const TextStyle(color: Colors.black87),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Tutup"),
                  ),
                ],
              ),
        );

        // Reset animasi setelah beberapa detik
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            showErrorAnimation = false;
            showErrorIcon = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: const Text(
                        "Buat Akun Baru",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1200),
                      child: Text(
                        "Isi formulir untuk mendaftar",
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Profile Picture
                    FadeInUp(
                      duration: const Duration(milliseconds: 1300),
                      child: Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child:
                                    _selectedImage != null
                                        ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        )
                                        : Container(
                                          color: Colors.grey.shade200,
                                          child: Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          isDarkMode
                                              ? Colors.grey.shade800
                                              : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Name Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 1400),
                      child: _buildTextField(
                        controller: nameController,
                        label: 'Nama Lengkap',
                        icon: Icons.person_outline,
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                      ),
                    ),

                    // Email Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 1500),
                      child: _buildTextField(
                        controller: emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Wajib diisi';
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(val)) {
                            return 'Email tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Password Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 1600),
                      child: _buildTextField(
                        controller: passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Wajib diisi';
                          if (val.length < 6) return 'Minimal 6 karakter';
                          return null;
                        },
                      ),
                    ),

                    // Phone Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 1700),
                      child: _buildTextField(
                        controller: phoneController,
                        label: 'Nomor HP',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Wajib diisi';
                          if (!RegExp(r'^[0-9]+$').hasMatch(val)) {
                            return 'Hanya angka yang diperbolehkan';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Address Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 1800),
                      child: _buildTextField(
                        controller: addressController,
                        label: 'Alamat',
                        icon: Icons.home_outlined,
                        maxLines: 1,
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                      ),
                    ),

                    // Location Picker
                    FadeInUp(
                      duration: const Duration(milliseconds: 1900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _selectLocationFromMap,
                            icon: const Icon(Icons.map_outlined),
                            label: Text(
                              selectedLocation == null
                                  ? 'Pilih Lokasi di Peta'
                                  : 'Ubah Lokasi',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          if (selectedLocation != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Lokasi dipilih: (${selectedLocation!.latitude.toStringAsFixed(4)}, ${selectedLocation!.longitude.toStringAsFixed(4)})',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Job Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 2000),
                      child: _buildTextField(
                        controller: jobController,
                        label: 'Pekerjaan',
                        icon: Icons.work_outlined,
                        validator:
                            (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Wajib diisi'
                                    : null,
                      ),
                    ),

                    // Graduation Year Field
                    FadeInUp(
                      duration: const Duration(milliseconds: 2100),
                      child: _buildTextField(
                        controller: graduationYearController,
                        label: 'Tahun Lulus',
                        icon: Icons.school_outlined,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'Wajib diisi';
                          if (!RegExp(r'^\d{4}$').hasMatch(val)) {
                            return 'Format tahun tidak valid (contoh: 2023)';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Error Icon and Message
                    if (showErrorIcon)
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),
                    if (message != null && showErrorAnimation)
                      ShakeX(
                        duration: const Duration(milliseconds: 700),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            message!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),

                    // Register Button
                    FadeInUp(
                      duration: const Duration(milliseconds: 2200),
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.only(top: 3, left: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.black),
                        ),
                        child: MaterialButton(
                          minWidth: double.infinity,
                          height: 60,
                          onPressed: isLoading ? null : _register,
                          color: Colors.greenAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            isLoading ? "Memproses..." : "Daftar Sekarang",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Login Redirect
                    FadeInUp(
                      duration: const Duration(milliseconds: 2300),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text("Sudah punya akun? "),
                          GestureDetector(
                            onTap: () {
                              Get.offAll(() => const LoginPage());
                            },
                            child: const Text(
                              "Masuk disini",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
