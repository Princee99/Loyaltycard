import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:loyaltycard/Screens/addcard.dart';
import 'package:loyaltycard/Screens/authentication/login.dart';
import 'package:loyaltycard/Screens/card_details_screen.dart';
import 'package:loyaltycard/services/notification_serivces.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  
  // Primary brand colors - matching other screens
  final Color primaryBlue = Color(0xFF1976D2); // Material blue
  final Color lightBlue = Color(0xFF64B5F6);   // Lighter blue for accents
  final Color darkBlue = Color(0xFF0D47A1);    // Darker blue for text

  @override
  void initState() {
    super.initState();
    print("HomePage initialized - Current User: ${FirebaseAuth.instance.currentUser?.email}");

    // Check for expired cards when the home page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForExpiredCards();
    });
  }

  Future<void> _checkForExpiredCards() async {
    await NotificationService.checkExpiredCards();
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => Login());
      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: primaryBlue.withOpacity(0.7),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to log out: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference cardsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cards');
        
    // Current date for expiration check (using the provided date for context)
    final DateTime referenceDate = DateTime.parse("2025-04-30 10:18:05");

    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        backgroundColor: primaryBlue, // Blue app bar
        title: Text(
          'My Loyalty Cards',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 2, // Slight shadow for depth
        actions: [
          // Test notification icon
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            tooltip: 'Test Notification',
            onPressed: () async {
              // Show loading indicator
              Get.dialog(
                Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              // Check permissions first
              bool hasPermission = await NotificationService.checkAndRequestPermissions();

              if (!hasPermission) {
                Get.back(); // Close loading dialog
                Get.snackbar(
                  'Permission Issue',
                  'Notification permissions not granted',
                  backgroundColor: Colors.red.withOpacity(0.7),
                  colorText: Colors.white,
                );
                return;
              }

              // Send simple test notification
              await NotificationService.sendTestNotification();
              Get.back(); // Close loading dialog
            },
          ),
          
          // Logout button
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          
          // Menu button
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'check_expired',
                child: Row(
                  children: [
                    Icon(Icons.update, color: primaryBlue),
                    SizedBox(width: 8),
                    Text('Check Expired Cards'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'check_expired') {
                _checkForExpiredCards();
                Get.snackbar(
                  'Checking Cards',
                  'Checking for expired loyalty cards',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: primaryBlue.withOpacity(0.7),
                  colorText: Colors.white,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: cardsCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card_off,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No cards added',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click "+" to add your first loyalty card',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            List<DocumentSnapshot> cards = snapshot.data!.docs;

            return ListView.builder(
              itemCount: cards.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> cardData = cards[index].data() as Map<String, dynamic>;

                // Check if card is expired
                bool isExpired = false;
                String expiryDateText = "No expiration date";
                
                if (cardData['expirationDate'] != null) {
                  final Timestamp expirationTimestamp = cardData['expirationDate'];
                  final expirationDate = expirationTimestamp.toDate();
                  isExpired = expirationDate.isBefore(referenceDate);
                  
                  // Format expiry date
                  expiryDateText = "Expires: ${expirationDate.year}-${expirationDate.month.toString().padLeft(2, '0')}-${expirationDate.day.toString().padLeft(2, '0')}";
                  
                  if (isExpired) {
                    expiryDateText = "EXPIRED: ${expirationDate.year}-${expirationDate.month.toString().padLeft(2, '0')}-${expirationDate.day.toString().padLeft(2, '0')}";
                  }
                }

                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isExpired ? Colors.red : Colors.grey.withOpacity(0.2),
                      width: isExpired ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    title: Text(
                      cardData['cardName'] ?? "Unnamed Card",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isExpired ? Colors.red : darkBlue,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          cardData['notes'] ?? "No additional notes",
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          expiryDateText,
                          style: TextStyle(
                            color: isExpired ? Colors.red : Colors.grey[600],
                            fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.red.withOpacity(0.1) : primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        isExpired ? Icons.warning : Icons.qr_code,
                        color: isExpired ? Colors.red : primaryBlue,
                        size: 28,
                      ),
                    ),
                    onTap: () {
                      // Navigate to CardDetailsScreen
                      Get.to(
                        () => CardDetailsScreen(
                          cardId: cards[index].id,
                          userId: userId,
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => AddCardScreen(userId: userId));
        },
        backgroundColor: primaryBlue,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Card',
        elevation: 4,
      ),
    );
  }
}