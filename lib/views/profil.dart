import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('alumniVerified')
              .doc(user.uid)
              .get();

      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data();
        });
      }
    }
    // Pindahkan isLoading=false ke sini agar CircularProgressIndicator hilang
    // meskipun data user tidak ada di Firestore (user masih login via Auth)
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      Get.offAllNamed('/welcome-page');
    } catch (e) {
      Get.snackbar(
        "Error",
        "Gagal untuk keluar: ${e.toString()}", // Pesan error lebih detail
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showLogoutConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Konfirmasi Keluar",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Warna tema utama
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _logout,
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = userData?['name'] ?? user?.email?.split('@')[0] ?? "User";
    final graduationYear = userData?['graduationYear'] ?? 'Belum ditentukan';
    final currentJob = userData?['job'] ?? 'Belum ditentukan';
    final phoneNumber = userData?['phone'] ?? 'Belum diberikan';
    final address = userData?['address'] ?? 'Belum diberikan';

    final photoUrl =
        userData?['profilePictureUrl'] ??
        userData?['photoUrl'] ??
        userData?['profile-images']; // Pastikan key ini benar

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white, // Samakan dengan header profil
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blue), // Warna ikon
            tooltip: "Keluar",
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    Colors.grey[200], // Fallback background
                                backgroundImage:
                                    (photoUrl != null &&
                                            photoUrl
                                                .isNotEmpty) // Cek isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : const AssetImage(
                                              'assets/images/profile-icon.png',
                                            )
                                            as ImageProvider,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Get.toNamed('/edit-profile');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      // Tambah shadow kecil
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue, // Warna tema utama
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'Tidak ada email',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Personal Info Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 0, // Atau sedikit shadow jika diinginkan
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Informasi Pribadi",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoItem(
                                icon: Icons.school_outlined, // Icon outline
                                title: "Tahun Lulus",
                                value: graduationYear,
                              ),
                              const Divider(height: 24),
                              _buildInfoItem(
                                icon: Icons.work_outline, // Icon outline
                                title: "Pekerjaan",
                                value: currentJob,
                              ),
                              const Divider(height: 24),
                              _buildInfoItem(
                                icon: Icons.phone_outlined, // Icon outline
                                title: "Nomor Telepon",
                                value: phoneNumber,
                              ),
                              const Divider(height: 24),
                              _buildInfoItem(
                                icon:
                                    Icons.location_on_outlined, // Icon outline
                                title: "Alamat",
                                value: address,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Spasi sebelum tombol
                  ],
                ),
              ),
      bottomNavigationBar: _buildNavbar(),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1), // Warna tema utama
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.blue), // Warna tema utama
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow:
                    TextOverflow
                        .ellipsis, // Menghindari overflow jika teks panjang
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavbar() {
    // Kode Navbar Anda tidak berubah, jadi saya akan mempersingkatnya di sini
    // Pastikan untuk menyalin kembali implementasi _buildNavbar Anda yang lengkap
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Optimasi: Hanya setState jika index berbeda
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
              if (index == 0) {
                Get.offAllNamed('/user-dashboard');
              } else if (index == 1) {
                Get.offAllNamed('/job');
              } else if (index == 2) {
                Get.offAllNamed('/activities');
              } else if (index == 3) {
                // Jika sudah di halaman profil, tidak perlu navigasi ulang
                // Get.offAllNamed('/profile');
              }
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0F4C81),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ), // Sedikit bold
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ), // Pastikan ukuran sama
          showUnselectedLabels: true,
          elevation: 0, // Shadow sudah dihandle oleh Container
          items: [
            _buildNavbarItem(
              iconData: Icons.home_outlined,
              activeIconData: Icons.home,
              label: 'Home',
              index: 0,
            ),
            _buildNavbarItem(
              iconData: Icons.work_outline,
              activeIconData: Icons.work,
              label: 'Job',
              index: 1,
            ), // Menggunakan ikon work
            _buildNavbarItem(
              iconData: Icons.event_outlined,
              activeIconData: Icons.event,
              label: 'Kegiatan',
              index: 2,
            ),
            _buildNavbarItem(
              iconData: Icons.person_outlined,
              activeIconData: Icons.person,
              label: 'Profil',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk BottomNavigationBarItem agar lebih rapi
  BottomNavigationBarItem _buildNavbarItem({
    required IconData iconData,
    required IconData activeIconData,
    required String label,
    required int index,
  }) {
    bool isActive = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6), // Padding konsisten
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isActive
                  ? const Color(0xFF0F4C81).withOpacity(0.1)
                  : Colors.transparent,
        ),
        child: Icon(
          isActive ? activeIconData : iconData,
          size: 24,
          // color: isActive ? const Color(0xFF0F4C81) : Colors.grey[600], // Warna diatur oleh BottomNavigationBar
        ),
      ),
      label: label,
    );
  }
}
