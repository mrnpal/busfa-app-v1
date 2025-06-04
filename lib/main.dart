import 'package:busfa_app/maps/alumni_map_page.dart';
import 'package:busfa_app/views/activity_detail_page.dart';
import 'package:busfa_app/views/activity_page.dart';
import 'package:busfa_app/views/add_job_page.dart';
import 'package:busfa_app/views/auth/forget_password.dart';
import 'package:busfa_app/views/auth/login_page.dart';
import 'package:busfa_app/views/auth/sign_up.dart';
import 'package:busfa_app/views/edit_page.dart';
import 'package:busfa_app/views/group_chat_page.dart';
import 'package:busfa_app/views/job_page.dart';
import 'package:busfa_app/views/profil.dart';
import 'package:busfa_app/views/splash.dart';
import 'package:busfa_app/views/home_page.dart';
import 'package:busfa_app/views/welcome_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Pesan background diterima: ${message.messageId}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notifikasi Penting',
  description: 'Channel untuk notifikasi penting',
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      if (payload == 'job') {
        Get.toNamed('/job');
      } else if (payload == 'activity') {
        Get.toNamed('/activities');
      }
    },
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
    _checkInitialMessage();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final screen = message.data['screen'];
      if (screen == 'job') {
        Get.toNamed('/job');
      } else if (screen == 'activity') {
        Get.toNamed('/activities');
      }
    });
  }

  Future<void> _setupFCM() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Izin notifikasi diberikan');
      _saveTokenToFirestore();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            payload: message.data['screen'], // ⬅️ untuk navigasi on tap
          );
        }
      });
    } else {
      print('Izin notifikasi ditolak');
    }
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final screen = initialMessage.data['screen'];
      if (screen == 'job') {
        Get.toNamed('/job');
      } else if (screen == 'activity') {
        Get.toNamed('/activities');
      }
    }
  }

  Future<void> _saveTokenToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User belum login, token tidak disimpan');
        return;
      }

      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('alumniVerified')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));

        print('Token FCM berhasil disimpan di alumniVerified: $token');
      }
    } catch (e) {
      print('Error menyimpan token FCM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => SplashScreen()),
        GetPage(name: '/welcome-page', page: () => WelcomePage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/user-dashboard', page: () => HomePage()),
        GetPage(name: '/profile', page: () => ProfileScreen()),
        GetPage(name: '/alumni-map', page: () => AlumniMapPage()),
        GetPage(name: '/activities', page: () => ActivityPage()),
        GetPage(name: '/job', page: () => JobPage()),
        GetPage(name: '/add-job', page: () => AddJobPage()),
        GetPage(name: '/activity-detail', page: () => ActivityDetailPage()),
        GetPage(name: '/group-chat', page: () => GroupChatPage()),
        GetPage(name: '/forgot-pw', page: () => ForgetPasswordPage()),
        GetPage(name: '/edit-profile', page: () => EditProfilePage()),
      ],
    );
  }
}
