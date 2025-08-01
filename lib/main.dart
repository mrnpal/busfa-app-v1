import 'package:busfa_app/maps/alumni_map_page.dart';
import 'package:busfa_app/views/activity_detail_page.dart';
import 'package:busfa_app/views/activity_page.dart';
import 'package:busfa_app/views/add_job_page.dart';
import 'package:busfa_app/auth/forget_password.dart';
import 'package:busfa_app/auth/login_page.dart';
import 'package:busfa_app/auth/sign_up.dart';
import 'package:busfa_app/views/edit_page.dart';
import 'package:busfa_app/views/group_chat_page.dart';
import 'package:busfa_app/views/job_page.dart';
import 'package:busfa_app/views/notifications_page.dart';
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

// Handler background untuk pesan FCM ketika aplikasi tidak aktif
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

// Entry point utama aplikasi, inisialisasi Firebase, notifikasi, dan jalankan app
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
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
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

// Widget root aplikasi, mengatur routing dan inisialisasi FCM
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

// State utama aplikasi, handle FCM, notifikasi, dan routing
class _MyAppState extends State<MyApp> {
  // Inisialisasi listener FCM dan cek pesan awal saat app dibuka
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

  // Setup FCM, permission notifikasi, dan listener pesan masuk
  Future<void> _setupFCM() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Izin notifikasi diberikan');
      _saveTokenToFirestore();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          // Tampilkan notifikasi lokal
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
            payload: message.data['screen'],
          );

          // Simpan notifikasi ke Firestore
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'title': notification.title,
              'body': notification.body,
              'timestamp': FieldValue.serverTimestamp(),
              'uid': user.uid,
              'screen': message.data['screen'] ?? '',
            });
          }
        }
      });
    } else {
      print('Izin notifikasi ditolak');
    }
  }

  // Fungsi ketika app dibuka dari notifikasi, arahkan ke screen sesuai payload
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

  // Simpan token FCM user ke Firestore agar bisa dikirimi notifikasi
  Future<void> _saveTokenToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User belum login, token tidak disimpan');
        return;
      }

      String? token;
      if (Theme.of(Get.context!).platform == TargetPlatform.iOS) {
        // Tunggu APNS token tersedia
        String? apnsToken;
        int retry = 0;
        do {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken == null)
            await Future.delayed(const Duration(milliseconds: 500));
          retry++;
        } while (apnsToken == null && retry < 10);
        if (apnsToken == null) {
          print('APNS token belum tersedia, token FCM tidak disimpan');
          return;
        }
      }
      token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));

        print('Token FCM berhasil disimpan di users: $token');
      }
    } catch (e) {
      print('Error menyimpan token FCM: $e');
    }
  }

  // Build root aplikasi dengan GetMaterialApp dan routing
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
        GetPage(name: '/notifications', page: () => NotificationPage()),
      ],
    );
  }
}
