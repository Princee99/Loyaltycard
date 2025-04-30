import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loyaltycard/Screens/authentication/login.dart';
import 'package:loyaltycard/Screens/home.dart';
import 'package:loyaltycard/wrapper.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passcontroller = TextEditingController();
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool obscureText = true;

  // Primary brand colors - matching login page
  final Color primaryBlue = Color(0xFF1976D2); // Material blue
  final Color lightBlue = Color(0xFF64B5F6); // Lighter blue for accents
  final Color darkBlue = Color(0xFF0D47A1); // Darker blue for text

  // Method to save user data to Firestore
  Future<void> _saveUserDataToFirestore(User user) async {
    try {
      // Get FCM token for push notifications
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // Store user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'fcmToken': fcmToken,
      });

      print('User data saved to Firestore successfully');
    } catch (e) {
      print('Error saving user data to Firestore: $e');
      Get.snackbar(
        'Warning',
        'Your account was created but profile data could not be saved. Some features might be limited.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.7),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 5),
      );
    }
  }

  Future<void> signup() async {
    if (emailcontroller.text.isEmpty || passcontroller.text.isEmpty) {
      Get.snackbar(
        'No data',
        'Please enter both email and password',
        snackPosition: SnackPosition.TOP,
        backgroundColor: primaryBlue.withOpacity(0.7),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      );
      return;
    }

    if (passcontroller.text.length < 6) {
      setState(() {
        isLoading = false;
      });
      Get.snackbar(
        'Weak Password',
        'Password must be at least 6 characters long',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      // Create user with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailcontroller.text.trim(),
        password: passcontroller.text.trim(),
      );

      // Save user data to Firestore
      if (userCredential.user != null) {
        await _saveUserDataToFirestore(userCredential.user!);
      }

      Get.snackbar(
        'Success',
        'Account created successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: primaryBlue.withOpacity(0.7),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      );
      Get.offAll(Wrapper());
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address';
      }
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  login() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          isGoogleLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Save user data to Firestore for Google sign-in as well
      if (userCredential.user != null) {
        await _saveUserDataToFirestore(userCredential.user!);
      }

      Get.offAll(() => HomePage());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Google sign-in failed: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      );
    } finally {
      setState(() {
        isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white, // Changed to white to match login page
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkBlue, // Changed to dark blue to match login page
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Sign up to get started",
                style: TextStyle(
                    fontSize: 16,
                    color:
                        Colors.grey[700]), // Darker grey for white background
              ),
              SizedBox(height: 20),
              TextField(
                controller: emailcontroller,
                style: TextStyle(
                    color: Colors.black87), // Changed text color to match login
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: Icon(Icons.email,
                      color: primaryBlue), // Changed to primary blue
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: primaryBlue), // Changed to primary blue
                  ),
                  filled: true,
                  fillColor:
                      Colors.grey[100], // Light grey background for fields
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15),
              TextField(
                controller: passcontroller,
                obscureText: obscureText,
                style: TextStyle(
                    color: Colors.black87), // Changed text color to match login
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: Icon(Icons.lock,
                      color: primaryBlue), // Changed to primary blue
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: primaryBlue, // Changed to primary blue
                    ),
                    onPressed: () => setState(() => obscureText = !obscureText),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: primaryBlue), // Changed to primary blue
                  ),
                  filled: true,
                  fillColor:
                      Colors.grey[100], // Light grey background for fields
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue, // Changed to primary blue
                  foregroundColor: Colors.white, // White text
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey,
                  elevation: 3, // Added elevation for depth
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Sign Up", style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: Colors.grey[300]!), // Add border
                    elevation: 2, // Lower elevation for secondary button
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google.webp',
                        height: 24,
                        width: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Sign in with Google",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(
                        color: Colors.grey[700]), // Changed to darker grey
                  ),
                  TextButton(
                    onPressed: () => Get.to(Login()),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryBlue, // Changed to primary blue
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
