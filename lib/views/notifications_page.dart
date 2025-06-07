import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Notifikasi")),
      body:
          user == null
              ? Center(child: Text("Belum login"))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('notifications')
                        .where('uid', isEqualTo: user.uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(child: Text("Belum ada notifikasi"));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['title'] ?? ''),
                        subtitle: Text(data['body'] ?? ''),
                        trailing: Text(
                          data['timestamp'] != null
                              ? (data['timestamp'] as Timestamp)
                                  .toDate()
                                  .toLocal()
                                  .toString()
                                  .split('.')[0]
                              : '',
                          style: TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          final screen = data['screen'];
                          if (screen == 'job') {
                            Get.toNamed('/job');
                          } else if (screen == 'activity') {
                            Get.toNamed('/activities');
                          }
                        },
                      );
                    },
                  );
                },
              ),
    );
  }
}
