import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/route_manager.dart';
import 'package:intl/intl.dart';

class JobPage extends StatefulWidget {
  const JobPage({Key? key}) : super(key: key);

  @override
  _JobPageState createState() => _JobPageState();
}

class _JobPageState extends State<JobPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Lowongan Pekerjaan',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari Pekerjaan...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                          : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          // Job List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('jobs')
                      .orderBy('postedDate', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada lowongan pekerjaan saat ini',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final jobs =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final matchesSearch =
                          data['title'].toString().toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          data['company'].toString().toLowerCase().contains(
                            _searchQuery,
                          );

                      final matchesFilter =
                          _selectedFilter == 'All' ||
                          data['type'] == _selectedFilter;

                      return matchesSearch && matchesFilter;
                    }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index].data() as Map<String, dynamic>;
                    final postedDate =
                        (job['postedDate'] as Timestamp).toDate();
                    final formattedDate = DateFormat(
                      'MMM d, y',
                    ).format(postedDate);

                    return GestureDetector(
                      onTap: () {
                        _showJobDetails(job);
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      image:
                                          job['companyLogo'] != null
                                              ? DecorationImage(
                                                image: NetworkImage(
                                                  job['companyLogo'],
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                              : null,
                                    ),
                                    child:
                                        job['companyLogo'] == null
                                            ? const Icon(
                                              Icons.business,
                                              color: Colors.grey,
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job['title'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          job['company'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(
                                        job['type'],
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      job['type'],
                                      style: TextStyle(
                                        color: _getTypeColor(job['type']),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      job['location'],
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed('/add-job');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildNavbar(),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Full-time':
        return Colors.green;
      case 'Part-time':
        return Colors.orange;
      case 'Internship':
        return Colors.purple;
      case 'Remote':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Filter Pekerjaan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All'),
              _buildFilterOption('Full-time'),
              _buildFilterOption('Part-time'),
              _buildFilterOption('Internship'),
              _buildFilterOption('Remote'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String filter) {
    return ListTile(
      title: Text(filter),
      trailing:
          _selectedFilter == filter
              ? const Icon(Icons.check, color: Colors.blue)
              : null,
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showJobDetails(Map<String, dynamic> job) {
    final postedDate = (job['postedDate'] as Timestamp).toDate();
    final formattedDate = DateFormat('MMMM d, y').format(postedDate);
    final deadlineDate = (job['deadline'] as Timestamp).toDate();
    final formattedDeadline = DateFormat('MMMM d, y').format(deadlineDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        image:
                            job['companyLogo'] != null
                                ? DecorationImage(
                                  image: NetworkImage(job['companyLogo']),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          job['companyLogo'] == null
                              ? const Icon(Icons.business, color: Colors.grey)
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            job['company'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      backgroundColor: _getTypeColor(
                        job['type'],
                      ).withOpacity(0.1),
                      label: Text(
                        job['type'],
                        style: TextStyle(color: _getTypeColor(job['type'])),
                      ),
                    ),
                    Chip(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      label: Text(
                        job['location'],
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    Chip(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      label: Text(
                        job['salary'] ?? 'Salary not specified',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Deskripsi Pekerjaan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  job['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Persyaratan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Column(
                  children:
                      (job['requirements'] as List<dynamic>)
                          .map(
                            (req) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4, right: 8),
                                    child: Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      req.toString(),
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tanggal Diposting',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Batas Waktu Pendaftaran',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            formattedDeadline,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  deadlineDate.isBefore(DateTime.now())
                                      ? Colors.red
                                      : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Apply for job
                    },
                    child: const Text(
                      'Lamar Pekerjaan',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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
                  _currentIndex == 1 ? Icons.work : Icons.work_outline,
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
