import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deneme/show_error.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:deneme/pages/home_page.dart';

class AuthService {
  final userCollection = FirebaseFirestore.instance.collection("users");
  final firebaseAuth = FirebaseAuth.instance;

  Future<void> signUp(BuildContext context,
      {required String email,
      required String password,
      required String username}) async {
    final navigator = Navigator.of(context);
    try {
      final UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await _registerUser(userCredential.user!,
            email: email, username: username);

        navigator.push(MaterialPageRoute(
          builder: (context) => HomePage(),
        ));
      }
    } on FirebaseAuthException catch (e) {
      showFlashError(context, e.message ?? "Tekrar Deneyin");
    }
  }

  Future<void> signIn(BuildContext context,
      {required String email, required String password}) async {
    final navigator = Navigator.of(context);
    try {
      final UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        navigator.push(MaterialPageRoute(
          builder: (context) => HomePage(),
        ));
      }
    } on FirebaseAuthException catch (e) {
      showFlashError(context, e.message ?? "Tekrar Deneyin");
    }
  }

  Future<void> _registerUser(User user,
      {required String email, required String username}) async {
    try {
      await userCollection.doc(user.uid).set({
        "email": email,
        "username": username,
        "userId": user.uid,
        "createdAt": FieldValue.serverTimestamp(),
      });
      print('User registered in Firestore successfully!');
    } catch (e) {
      print('Error registering user in Firestore: $e');
    }
  }
}
