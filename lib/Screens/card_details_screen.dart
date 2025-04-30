import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CardDetailsScreen extends StatelessWidget {
  final String cardId;
  final String userId;

  CardDetailsScreen({required this.cardId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cards')
            .doc(cardId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Card not found'));
          }

          Map<String, dynamic> cardData =
              snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Name
                Text(
                  'Card Name: ${cardData['cardName']}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),

                // Barcode Type
                Text(
                  'Barcode Type: ${cardData['barcodeType']}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8.0),

                // Notes
                if (cardData['notes'] != null && cardData['notes'].isNotEmpty)
                  Text(
                    'Notes: ${cardData['notes']}',
                    style: TextStyle(fontSize: 16),
                  ),
                SizedBox(height: 16.0),

                // QR Code
                Center(
                  child: QrImageView(
                    data: cardData['barcodeValue'] ?? '',
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                SizedBox(height: 16.0),

                // Expiration Date
                if (cardData['expirationDate'] != null)
                  Text(
                    'Expiration Date: ${DateTime.fromMillisecondsSinceEpoch(cardData['expirationDate'].seconds * 1000)}',
                    style: TextStyle(fontSize: 16),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
