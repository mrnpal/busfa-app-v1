import 'dart:async';
import 'package:busfa_app/services/fcm_services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage > 2) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
    FCMService.instance.saveTokenToFirestore();
    FCMService.instance.listenToTokenRefresh();
    // Cek apakah data pengguna sudah lengkap
    Future.microtask(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          // Daftar field yang wajib diisi
          final requiredFields = [
            'name',
            'address',
            'phone',
            'job',
            'graduationYear',
            'parentName',
            'dateEntry',
            'education',
            'birthPlaceDate',
            'indukNumber',
          ];
          final isIncomplete = requiredFields.any(
            (f) => (data[f] == null || (data[f] as String).trim().isEmpty),
          );
          if (isIncomplete) {
            _showDataReminderDialog();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<String?> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (snapshot.exists) {
        return snapshot.data()?['name'];
      }
    }
    return null;
  }

  Future<int> _getAlumniCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.size;
  }

  Future<int> _getEventCount() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('kegiatan').get();
    return snapshot.size;
  }

  Future<int> _getJobCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('jobs').get();
    return snapshot.size;
  }

  Future<List<Map<String, dynamic>>> _getRecentActivities() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('kegiatan')
            .orderBy('date', descending: true)
            .limit(3)
            .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Widget _buildProfileButton() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future:
          user != null
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get()
              : null,
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            if (data.containsKey('profile-images') &&
                data['profile-images'] != null) {
              photoUrl = data['profile-images'];
            } else if (data.containsKey('photoUrl') &&
                data['photoUrl'] != null) {
              photoUrl = data['photoUrl'];
            }
          }
        }

        return GestureDetector(
          onTap: () {
            Get.toNamed('/profile');
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              backgroundImage:
                  photoUrl != null
                      ? NetworkImage(photoUrl) as ImageProvider
                      : const AssetImage('assets/images/profile-icon.png'),
              child:
                  photoUrl == null
                      ? const Icon(Icons.person, color: Colors.transparent)
                      : null,
            ),
          ),
        );
      },
    );
  }

  void _showDataReminderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F4C81),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Lengkapi Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Hai Alumni, mohon lengkapi data diri Anda sebelum menggunakan aplikasi alumni Busfa.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.toNamed('/edit-profile');
                },
                child: Text(
                  'Isi Sekarang',

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Nanti Saja',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F4C81), Color(0xFF3A7BD5)],
                  ),
                ),
                padding: const EdgeInsets.only(left: 24, bottom: 16, top: 65),
                alignment: Alignment.bottomLeft,
                child: FutureBuilder<String?>(
                  future: _getUserName(),
                  builder: (context, snapshot) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Selamat datang,",
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${snapshot.data ?? "Alumni Member"} 👋",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            actions: [_buildProfileButton()],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 140,
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            children: [
                              FutureBuilder<int>(
                                future: _getAlumniCount(),
                                builder: (context, snapshot) {
                                  return _buildStatCard(
                                    title: "Total Pengguna",
                                    value:
                                        snapshot.hasData
                                            ? "${snapshot.data}"
                                            : "-",
                                    icon: Icons.people_alt_outlined,
                                    color: const Color(0xFF6366F1),
                                  );
                                },
                              ),
                              FutureBuilder<int>(
                                future: _getEventCount(),
                                builder: (context, snapshot) {
                                  return _buildStatCard(
                                    title: "Total Kegiatan",
                                    value:
                                        snapshot.hasData
                                            ? "${snapshot.data}"
                                            : "-",
                                    icon: Icons.event_outlined,
                                    color: const Color(0xFF10B981),
                                  );
                                },
                              ),
                              FutureBuilder<int>(
                                future: _getJobCount(),
                                builder: (context, snapshot) {
                                  return _buildStatCard(
                                    title: "Lowongan Kerja",
                                    value:
                                        snapshot.hasData
                                            ? "${snapshot.data}"
                                            : "-",
                                    icon: Icons.work_outline,
                                    color: const Color(0xFFF59E0B),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: SmoothPageIndicator(
                            controller: _pageController,
                            count: 3,
                            effect: WormEffect(
                              dotHeight: 8,
                              dotWidth: 8,
                              activeDotColor: Theme.of(context).primaryColor,
                              dotColor: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      "Fitur Utama",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.6,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    padding: EdgeInsets.zero,
                    children: [
                      _buildFeatureTile(
                        icon: Icons.map_outlined,
                        title: "Alumni Map",
                        color: const Color(0xFF10B981),
                        onTap: () => Get.toNamed('/alumni-map'),
                      ),
                      // _buildFeatureTile(
                      //   icon: Icons.event_outlined,
                      //   title: "Kegiatan",
                      //   color: const Color(0xFFF59E0B),
                      //   onTap: () => Get.toNamed('/activities'),
                      // ),
                      _buildFeatureTile(
                        icon: Icons.chat_bubble_outline,
                        title: "Grup Chat",
                        color: const Color(0xFFF59E0B),
                        onTap: () => Get.toNamed('/group-chat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Kegiatan Terkini",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 140,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getRecentActivities(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text("Belum ada aktivitas terkini."),
                          );
                        }
                        final activities = snapshot.data!;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: activities.length,
                          itemBuilder: (context, i) {
                            final activity = activities[i];
                            // Format tanggal
                            String dateStr = '-';
                            if (activity['date'] != null) {
                              DateTime? date;
                              if (activity['date'] is Timestamp) {
                                date = (activity['date'] as Timestamp).toDate();
                              } else if (activity['date'] is String) {
                                date = DateTime.tryParse(activity['date']);
                              }
                              if (date != null) {
                                dateStr =
                                    "${date.day}-${date.month}-${date.year}";
                              }
                            }
                            return Container(
                              child: Stack(
                                children: [
                                  Container(
                                    width: 260,
                                    margin: EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.07),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                      image:
                                          activity['imageUrl'] != null &&
                                                  activity['imageUrl'] != ""
                                              ? DecorationImage(
                                                image: NetworkImage(
                                                  activity['imageUrl'],
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                              : null,
                                    ),
                                  ),
                                  // Gradient overlay
                                  Container(
                                    width: 260,
                                    margin: EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.55),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Text content
                                  Container(
                                    width: 260,
                                    margin: EdgeInsets.only(right: 16),
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activity['title'] ?? '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color:
                                                Colors
                                                    .white, // <-- Putih agar kontras
                                            shadows: [
                                              Shadow(
                                                blurRadius: 8,
                                                color: Colors.black54,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 8,
                                                    color: Colors.black54,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavbar(),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar() {
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
            setState(() => _currentIndex = index);
            if (index == 0)
              Get.offAllNamed('/user-dashboard');
            else if (index == 1)
              Get.offAllNamed('/job');
            else if (index == 2)
              Get.offAllNamed('/activities');
            else if (index == 3)
              Get.offAllNamed('/profile');
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0F4C81),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontSize: 12),
          showUnselectedLabels: true,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentIndex == 0
                          ? const Color(0xFF0F4C81).withOpacity(0.1)
                          : Colors.transparent,
                ),
                child: Icon(
                  _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: 24,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentIndex == 1
                          ? const Color(0xFF0F4C81).withOpacity(0.1)
                          : Colors.transparent,
                ),
                child: Icon(
                  _currentIndex == 1 ? Icons.event : Icons.work_outline,
                  size: 24,
                ),
              ),
              label: 'Job',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentIndex == 2
                          ? const Color(0xFF0F4C81).withOpacity(0.1)
                          : Colors.transparent,
                ),
                child: Icon(
                  _currentIndex == 2 ? Icons.event : Icons.event_outlined,
                  size: 24,
                ),
              ),
              label: 'Kegiatan',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentIndex == 3
                          ? const Color(0xFF0F4C81).withOpacity(0.1)
                          : Colors.transparent,
                ),
                child: Icon(
                  _currentIndex == 3 ? Icons.person : Icons.person_outlined,
                  size: 24,
                ),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
