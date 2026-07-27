import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get userStream => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

Future<UserCredential> createAccount({
  required String email,
  required String password,
}) async {
  return await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password.trim(),
  );
}

Future<void> signOut() async {
  await firebaseAuth.signOut();
}
Future<void> resetPassword(String email) async {
  await firebaseAuth.sendPasswordResetEmail(email: email.trim());

}
Future<void> updateUsername({
  required String username,

})async{
  await currentUser!.updateDisplayName(username.trim());
}

Future<void> deleteAccount({
  required String email,
  required String password,
}) async {
  AuthCredential credential = EmailAuthProvider.credential(
    email: email.trim(),
    password: password.trim(),
  );
  await currentUser!.reauthenticateWithCredential(credential);
  await currentUser!.delete();
  await firebaseAuth.signOut();
}
Future<void> resetPasswordFromCurrentPassword({
  required String currentPassword,
  required String newPassword,
required String email,
}) async {
  AuthCredential credential = EmailAuthProvider.credential(
    email: email.trim(),
    password: currentPassword.trim(),
  );
  await currentUser!.reauthenticateWithCredential(credential);
  await currentUser!.updatePassword(newPassword.trim());
}
}



