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

  Future<void> signup() async {
    if (emailcontroller.text.isEmpty || passcontroller.text.isEmpty) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Please enter both email and password')),
      // );
      Get.snackbar(
        'No data',
        'Please enter both email and password',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.7),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      );
      return;
    }

    if (passcontroller.text.length < 6) {
      // Logger.warning(Logger.USER, "Password too short",
      // {"length": passcontroller.text.length.toString()});

      setState(() {
        isLoading = false;
      });
      Get.snackbar(
        'Weak Password',
        'Password must be at least 6 characters long',
        snackPosition: SnackPosition.TOP,
        backgroundColor:
            const Color.fromARGB(255, 209, 46, 46).withOpacity(0.7),
        colorText: Colors.white,
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailcontroller.text.trim(),
        password: passcontroller.text.trim(),
      );
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Account created successfully'),
      //     behavior: SnackBarBehavior.floating,
      //     margin: EdgeInsets.only(top: 20, left: 20, right: 20),
      //   ),
      // );
      Get.snackbar(
        'Success',
        'Account created successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.7),
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
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(SnackBar(content: Text(message)));
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor:
            const Color.fromARGB(255, 222, 15, 15).withOpacity(0.7),
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

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      Get.offAll(() => Homepage());
    } catch (e) {
      setState(() {
        var errorMessage = 'Google sign-in failed: $e';
      });
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
      backgroundColor: Colors.black,
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
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Sign up to get started",
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
              SizedBox(height: 20),
              TextField(
                controller: emailcontroller,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.email, color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15),
              TextField(
                controller: passcontroller,
                obscureText: obscureText,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.lock, color: Colors.white),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white,
                    ),
                    onPressed: () => setState(() => obscureText = !obscureText),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.black)
                    : Text("Sign Up", style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double
                    .infinity, // Ensures the button fills the width of the container
                child: ElevatedButton(
                  onPressed:
                      login, // Replace 'login' with your Google sign-in logic
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Button background color
                    foregroundColor: Colors.black, // Text and icon color
                    padding: EdgeInsets.symmetric(
                        vertical: 16), // Match Login button's height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Rounded corners for consistency
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center the content
                    children: [
                      Image.asset(
                        'assets/images/google.webp',
                        height: 24, // Adjust the icon size
                        width: 24,
                      ),
                      SizedBox(
                          width:
                              8), // Add spacing between the icon and the text
                      Text(
                        "Sign in with Google",
                        style: TextStyle(
                            fontSize:
                                16), // Match text size with the Login button
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
                    style: TextStyle(color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () => Get.to(Login()),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
