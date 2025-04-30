import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCardScreen extends StatefulWidget {
  final String userId;

  AddCardScreen({required this.userId});

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  String? cardName;
  String? barcodeType;
  String? barcodeValue;
  String? notes;
  DateTime? expirationDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Card Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a card name';
                  }
                  return null;
                },
                onSaved: (value) {
                  cardName = value;
                },
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Barcode Type',
                  border: OutlineInputBorder(),
                ),
                items: ['qr', 'barcode']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  barcodeType = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a barcode type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Barcode Value',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a barcode value';
                  }
                  return null;
                },
                onSaved: (value) {
                  barcodeValue = value;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) {
                  notes = value;
                },
              ),
              SizedBox(height: 16.0),
              TextButton(
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate != null) {
                    setState(() {
                      expirationDate = pickedDate;
                    });
                  }
                },
                child: Text(
                  expirationDate == null
                      ? 'Pick Expiration Date'
                      : 'Expiration: ${expirationDate!.toLocal()}',
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    CollectionReference cardsCollection = FirebaseFirestore
                        .instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('cards');

                    await cardsCollection.add({
                      'cardName': cardName,
                      'barcodeType': barcodeType,
                      'barcodeValue': barcodeValue,
                      'notes': notes,
                      'expirationDate': expirationDate,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                  }
                },
                child: Text('Add Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
