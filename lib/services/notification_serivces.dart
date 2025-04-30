import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize settings for iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize notifications plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("Notification clicked: ${details.payload}");
        // Handle notification tap
      },
    );

    // Create notification channels for Android (required for Android 8.0+)
    await _createNotificationChannels();

    // Request permission for iOS
    await _requestPermissions();

    try {
      await _updateFCMToken();
    } catch (e) {
      print("FCM token update failed but continuing: $e");
      // Continue anyway
    }

    // Set up listeners for FCM
    _setupFCMListeners();

    _isInitialized = true;

    print("NotificationService initialized successfully");
  }

  // Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'card_expiry_channel',
      'Card Expiration Notifications',
      description: 'Notifications about expired and expiring loyalty cards',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print("Notification channel created");
  }

  // Request permissions
  static Future<void> _requestPermissions() async {
    // Request permissions for iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request permissions for Firebase Messaging
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("Notification permissions requested");
  }

  // Update FCM token in Firestore
  static Future<void> _updateFCMToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        try {
          // Use set with merge instead of update
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(
                  {
                'fcmToken': token,
                // Add any other fields you want to ensure exist
                'lastUpdated': DateTime.now(),
              },
                  SetOptions(
                      merge:
                          true) // This creates the document if it doesn't exist
                  );
          print("FCM Token updated: $token");
        } catch (e) {
          print("Error updating FCM token: $e");
        }
      }
    }

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Use set with merge here too
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'fcmToken': newToken,
            'lastUpdated': DateTime.now(),
          }, SetOptions(merge: true));
          print("FCM Token refreshed: $newToken");
        } catch (e) {
          print("Error refreshing FCM token: $e");
        }
      }
    });
  }

  // Set up FCM listeners
  static void _setupFCMListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          "FCM message received in foreground: ${message.notification?.title}");
      if (message.notification != null) {
        showLocalNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          payload: message.data['cardId'] ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App opened from notification: ${message.notification?.title}");
      // Handle notification tap when app was in background
    });
  }

  // Show local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String payload = '',
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'card_expiry_channel',
        'Card Expiration Notifications',
        channelDescription:
            'Notifications about expired and expiring loyalty cards',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
        color: Colors.red,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      int notificationId = DateTime.now().millisecond;
      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: payload,
      );

      print("Local notification displayed: ID=$notificationId, Title=$title");
      return Future.value();
    } catch (e) {
      print("Error showing notification: $e");
      return Future.value();
    }
  }

  // Check for expired cards
  static Future<void> checkExpiredCards() async {
    print("Checking for expired cards...");
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in");
      return;
    }

    try {
      // Ensure notifications are initialized
      await initialize();

      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      if (cardsSnapshot.docs.isEmpty) {
        print("No cards found");
        return;
      }

      // Current time for expiration check
      final now = DateTime.now();
      // Create a date for just today (removing time component)
      final today = DateTime(now.year, now.month, now.day);
      print("Current date for expiration check: $now");

      final List<Map<String, dynamic>> expiredCards = [];
      final List<Map<String, dynamic>> expiringTodayCards = [];

      for (var doc in cardsSnapshot.docs) {
        final cardData = doc.data();
        if (cardData['expirationDate'] != null) {
          final Timestamp expirationTimestamp = cardData['expirationDate'];
          final expirationDate = expirationTimestamp.toDate();

          // Convert to date only (removing time component)
          final expirationDateOnly = DateTime(
              expirationDate.year, expirationDate.month, expirationDate.day);

          print("\n---- DETAILED DATE COMPARISON ----");
          print("Today (no time): $today");
          print("Expiration (original): $expirationDate");
          print("Expiration (no time): $expirationDateOnly");
          print(
              "Is expiring today?: ${expirationDateOnly.isAtSameMomentAs(today)}");
          print(
              "Difference in days: ${expirationDateOnly.difference(today).inDays}");
          print("--------------------------------\n");

          print("Card: ${cardData['cardName']}, Expiration: $expirationDate");

          // Check if card is expired (strictly before today)
          if (expirationDateOnly.isBefore(today)) {
            print("Card ${cardData['cardName']} is expired!");
            expiredCards.add({
              'id': doc.id,
              'cardName': cardData['cardName'],
              'expirationDate': expirationDate,
            });

            await showLocalNotification(
              title: 'Card Expired',
              body: '${cardData['cardName']} has expired!',
              payload: doc.id,
            );
          }
          // Check if card is expiring today
          else if (expirationDateOnly.isAtSameMomentAs(today)) {
            print("Card ${cardData['cardName']} is expiring today!");
            expiringTodayCards.add({
              'id': doc.id,
              'cardName': cardData['cardName'],
              'expirationDate': expirationDate,
            });

            await showLocalNotification(
              title: 'Card Expiring Today',
              body: '${cardData['cardName']} expires today!',
              payload: doc.id,
            );
          }
        }
      }

      // Debug output
      if (expiredCards.isEmpty && expiringTodayCards.isEmpty) {
        print("No expired or expiring cards found");
      } else {
        if (expiredCards.isNotEmpty) {
          print("Found ${expiredCards.length} expired cards");
        }
        if (expiringTodayCards.isNotEmpty) {
          print("Found ${expiringTodayCards.length} cards expiring today");
        }
      }
    } catch (e) {
      print('Error checking for expired cards: $e');
      await showLocalNotification(
        title: 'Error Checking Cards',
        body: 'An error occurred while checking for expired cards.',
      );
    }
  }

  // Force a test notification - for debugging
  static Future<void> sendTestNotification() async {
    await initialize();
    await showLocalNotification(
      title: 'Test Notification',
      body:
          'This is a test notification. If you see this, notifications are working!',
      payload: 'test',
    );
    print("Test notification sent");
  }

  // Add this method to check and request permissions explicitly
  static Future<bool> checkAndRequestPermissions() async {
    await initialize();

    // Check platform-specific permissions
    bool permissionsGranted = false;

    if (GetPlatform.isIOS) {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      permissionsGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (GetPlatform.isAndroid) {
      permissionsGranted = true; // For Android, check is less straightforward
    }

    if (!permissionsGranted) {
      final result = await FirebaseMessaging.instance.requestPermission();
      permissionsGranted =
          result.authorizationStatus == AuthorizationStatus.authorized;
      print("Permission request result: ${result.authorizationStatus}");
    }

    return permissionsGranted;
  }

  static Future<void> checkCardsAfterLogin() async {
    print("Checking cards after login...");

    // Force initialization every time
    _isInitialized = false;
    await initialize();

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user logged in");
        return;
      }

      print("Checking cards for user: ${user.email}");

      // Get all cards for this user
      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .get();

      print("Found ${cardsSnapshot.docs.length} cards to check");

      if (cardsSnapshot.docs.isEmpty) {
        print("No cards found for login notification");
        return;
      }

      // Current date with time stripped
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int expiredCount = 0;
      int expiringTodayCount = 0;

      // Check each card
      for (var doc in cardsSnapshot.docs) {
        final cardData = doc.data();
        if (cardData['expirationDate'] != null) {
          final Timestamp expirationTimestamp = cardData['expirationDate'];
          final expirationDate = expirationTimestamp.toDate();
          final expirationDateOnly = DateTime(
              expirationDate.year, expirationDate.month, expirationDate.day);

          print(
              "Checking card: ${cardData['cardName']}, Expiry: $expirationDateOnly");

          // Check expired cards
          if (expirationDateOnly.isBefore(today)) {
            expiredCount++;
            print("Card expired: ${cardData['cardName']}");
          }
          // Check cards expiring today
          else if (expirationDateOnly.year == today.year &&
              expirationDateOnly.month == today.month &&
              expirationDateOnly.day == today.day) {
            expiringTodayCount++;
            print("Card expiring today: ${cardData['cardName']}");
          }
        }
      }

      // Send summary notifications
      if (expiredCount > 0) {
        await showLocalNotification(
          title: 'Cards Expired',
          body: 'You have $expiredCount expired loyalty card(s)',
        );
        print("Sent expired cards notification");
      }

      if (expiringTodayCount > 0) {
        await showLocalNotification(
          title: 'Cards Expiring Today',
          body: 'You have $expiringTodayCount card(s) expiring today',
        );
        print("Sent expiring today notification");
      }

      print(
          "Login card check completed: $expiredCount expired, $expiringTodayCount expiring today");
    } catch (e) {
      print("Error in checkCardsAfterLogin: $e");
      await showLocalNotification(
        title: 'Check Failed',
        body: 'Failed to check your cards after login',
      );
    }
  }
}
