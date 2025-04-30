import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:loyaltycard/Screens/authentication/forgot_pass.dart';
import 'package:loyaltycard/Screens/authentication/signup.dart';
import 'package:loyaltycard/Screens/home.dart';
import 'package:loyaltycard/wrapper.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  bool isLoading = false;
  bool obscureText = true;
  bool isGoogleLoading = false;
  String? errorMessage;

  // Primary brand colors
  final Color primaryBlue = Color(0xFF1976D2); // Material blue
  final Color lightBlue = Color(0xFF64B5F6); // Lighter blue for accents
  final Color darkBlue = Color(0xFF0D47A1); // Darker blue for text

  Future<void> signIn() async {
    if (emailController.text.isEmpty || passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: primaryBlue,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passController.text.trim(),
      );
      Get.to(Wrapper());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful'),
          backgroundColor: primaryBlue,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
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

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      Get.offAll(() => HomePage());
    } catch (e) {
      setState(() {
        errorMessage = 'Google sign-in failed: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage ?? 'Sign-in failed'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevents keyboard from pushing the UI
      backgroundColor: Colors.white, // Changed from black to white
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkBlue, // Changed from white to dark blue
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Login to your account",
                style: TextStyle(
                    fontSize: 16,
                    color:
                        Colors.grey[700]), // Darker grey for white background
              ),
              SizedBox(height: 20),
              TextField(
                controller: emailController,
                style: TextStyle(color: Colors.black87), // Changed text color
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: Icon(Icons.email,
                      color: primaryBlue), // Changed icon color
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: primaryBlue), // Changed to blue
                  ),
                  filled: true,
                  fillColor:
                      Colors.grey[100], // Light grey background for fields
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: passController,
                obscureText: obscureText,
                style: TextStyle(color: Colors.black87), // Changed text color
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: Icon(Icons.lock,
                      color: primaryBlue), // Changed icon color
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: primaryBlue, // Changed icon color
                    ),
                    onPressed: () => setState(() => obscureText = !obscureText),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: primaryBlue), // Changed to blue
                  ),
                  filled: true,
                  fillColor:
                      Colors.grey[100], // Light grey background for fields
                ),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.to(ForgotPass()),
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold), // Changed to blue
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue, // Changed to blue
                  foregroundColor: Colors.white, // White text on blue
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey,
                  elevation: 3, // Added elevation for depth
                ),
                child: isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white) // Changed to white
                    : Text("Login", style: TextStyle(fontSize: 18)),
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
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                        color: Colors.grey[700]), // Changed to dark grey
                  ),
                  TextButton(
                    onPressed: () => Get.to(Signup()),
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryBlue, // Changed to blue
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
