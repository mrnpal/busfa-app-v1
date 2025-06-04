import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async';

class GroupChatPage extends StatefulWidget {
  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  late StreamSubscription _typingStatusSub;

  bool _isTyping = false;
  bool _someoneTyping = false;
  String _typingUserName = '';

  @override
  void initState() {
    super.initState();
    _listenTypingStatus();
  }

  void _listenTypingStatus() {
    _typingStatusSub = FirebaseFirestore.instance
        .collection('typingStatus')
        .snapshots()
        .listen((snapshot) {
          final docs = snapshot.docs;
          for (var doc in docs) {
            if (doc.id != user?.uid && doc['isTyping'] == true) {
              setState(() {
                _someoneTyping = true;
                _typingUserName = doc['name'] ?? 'Alumni';
              });
              return;
            }
          }
          setState(() {
            _someoneTyping = false;
            _typingUserName = '';
          });
        });
  }

  void _updateTypingStatus(bool isTyping) async {
    if (user == null) return;

    final uid = user!.uid;
    final nameSnapshot =
        await FirebaseFirestore.instance
            .collection('alumniVerified')
            .doc(uid)
            .get();
    final name =
        nameSnapshot.exists
            ? (nameSnapshot.data()?['name'] ?? 'Alumni')
            : 'Alumni';

    await FirebaseFirestore.instance.collection('typingStatus').doc(uid).set({
      'isTyping': isTyping,
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final uid = user?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('alumniVerified')
            .doc(uid)
            .get();

    final name = doc.exists ? (doc.data()?['name'] ?? 'Alumni') : 'Alumni';
    final photoUrl = doc.data()?['photoUrl'] ?? null;

    await FirebaseFirestore.instance.collection('groupChats').add({
      'senderId': uid,
      'senderName': name,
      'photoUrl': photoUrl,
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    _updateTypingStatus(false);

    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return DateFormat('MMM d, y').format(date);
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFD),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Alumni Forum',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F4C81), Color(0xFF3A7BD5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                // image: DecorationImage(
                //   // image: AssetImage('assets/images/background.png'),
                //   fit: BoxFit.cover,
                // ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('groupChats')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6E56D8),
                        ),
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start a conversation with fellow alumni!',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data =
                          messages[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == user?.uid;

                      return FadeIn(
                        duration: Duration(milliseconds: 200),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Align(
                            alignment:
                                isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.8,
                              ),
                              child: GestureDetector(
                                onLongPress:
                                    isMe
                                        ? () async {
                                          final confirm = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: Text('Hapus Pesan'),
                                                  content: Text(
                                                    'Apakah kamu yakin ingin menghapus pesan ini?',
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: Text('Batal'),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: Text(
                                                        'Hapus',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );
                                          if (confirm == true) {
                                            await FirebaseFirestore.instance
                                                .collection('groupChats')
                                                .doc(messages[index].id)
                                                .delete();
                                          }
                                        }
                                        : null,
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: 8,
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            data['senderName'] ?? '',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      Row(
                                        mainAxisAlignment:
                                            isMe
                                                ? MainAxisAlignment.end
                                                : MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (!isMe)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: CircleAvatar(
                                                radius: 16,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                backgroundImage:
                                                    data['photoUrl'] != null
                                                        ? NetworkImage(
                                                          data['photoUrl'],
                                                        )
                                                        : AssetImage(
                                                              'assets/images/profile-icon.png',
                                                            )
                                                            as ImageProvider,
                                              ),
                                            ),
                                          Flexible(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    isMe
                                                        ? Color(0xFF6E56D8)
                                                        : Colors.white,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(18),
                                                  topRight: Radius.circular(18),
                                                  bottomLeft:
                                                      isMe
                                                          ? Radius.circular(18)
                                                          : Radius.circular(4),
                                                  bottomRight:
                                                      isMe
                                                          ? Radius.circular(4)
                                                          : Radius.circular(18),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 6,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12,
                                                horizontal: 16,
                                              ),
                                              child: Text(
                                                data['message'] ?? '',
                                                style: TextStyle(
                                                  color:
                                                      isMe
                                                          ? Colors.white
                                                          : Colors
                                                              .grey
                                                              .shade800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: 4,
                                          left: 8,
                                          right: 8,
                                        ),
                                        child: Text(
                                          data['timestamp'] != null
                                              ? _formatTimestamp(
                                                data['timestamp'] as Timestamp,
                                              )
                                              : '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (_someoneTyping)
            FadeIn(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6E56D8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$_typingUserName is typing...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (val) {
                        final isNowTyping = val.trim().isNotEmpty;
                        if (_isTyping != isNowTyping) {
                          _isTyping = isNowTyping;
                          _updateTypingStatus(isNowTyping);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  child: Material(
                    color: Colors.transparent,
                    shape: CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: sendMessage,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.send_rounded,
                          color: Color(0xFF0F4C81),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _updateTypingStatus(false);
    _typingStatusSub.cancel();
    super.dispose();
  }
}
