import 'dart:io';

import 'package:cementdeliverytracker/core/constants/app_constants.dart';
import 'package:cementdeliverytracker/core/errors/failures.dart';
import 'package:cementdeliverytracker/features/auth/domain/entities/auth_entities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cementdeliverytracker/features/auth/domain/usecases/change_password_params.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUser> login(LoginParams params);
  Future<AuthUser> signup(SignupParams params);
  Future<void> logout();
  Future<void> changePassword(ChangePasswordParams params);
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.storage,
  });

  @override
  Future<AuthUser> login(LoginParams params) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: params.email,
        password: params.password,
      );
      return AuthUser(
        id: userCredential.user!.uid,
        email: userCredential.user!.email!,
        displayName: userCredential.user!.displayName,
      );
    } on FirebaseAuthException catch (e) {
      rethrow; // Let the UI handle this
    } catch (e) {
      throw ServerFailure('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<AuthUser> signup(SignupParams params) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: params.email,
        password: params.password,
      );

      // Upload image if provided
      String? imageUrl;
      if (params.imagePath != null) {
        final storageRef = storage
            .ref()
            .child(AppConstants.userImagesPath)
            .child('${userCredential.user!.uid}.jpg');

        await storageRef.putFile(File(params.imagePath!));
        imageUrl = await storageRef.getDownloadURL();
      }

      // Create user document in Firestore
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .set({
            'username': params.username,
            'email': params.email,
            'phone': params.phone,
            'image_url': imageUrl,
            'userType': AppConstants.userTypePending,
            'created_at': DateTime.now().toIso8601String(),
          });

      return AuthUser(
        id: userCredential.user!.uid,
        email: userCredential.user!.email!,
        displayName: params.username,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('Signup failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw ServerFailure('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<void> changePassword(ChangePasswordParams params) async {
    try {
      final user = firebaseAuth.currentUser;

      // Check if user is signed in
      if (user == null) {
        throw AuthFailure('No user is currently signed in.');
      }

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: params.currentPassword,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          throw AuthFailure('The current password is incorrect.');
        } else if (e.code == 'user-mismatch') {
          throw AuthFailure('The credential does not match the current user.');
        }
        throw _mapFirebaseAuthExceptionToFailure(e);
      }

      // Update password
      await user.updatePassword(params.newPassword);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthExceptionToFailure(e);
    } catch (e) {
      throw ServerFailure('Failed to change password: ${e.toString()}');
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return AuthUser(
        id: user.uid,
        email: user.email!,
        displayName: user.displayName,
      );
    });
  }

  @override
  AuthUser? get currentUser {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return AuthUser(
      id: user.uid,
      email: user.email!,
      displayName: user.displayName,
    );
  }

  Failure _mapFirebaseAuthExceptionToFailure(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure('No user found with this email.');
      case 'wrong-password':
        return AuthFailure('Wrong password provided.');
      case 'email-already-in-use':
        return AuthFailure('An account already exists with this email.');
      case 'weak-password':
        return AuthFailure('The password provided is too weak.');
      case 'invalid-email':
        return AuthFailure('The email address is not valid.');
      case 'user-disabled':
        return AuthFailure('This user account has been disabled.');
      case 'requires-recent-login':
        return AuthFailure(
          'Please sign in again before changing your password.',
        );
      default:
        return AuthFailure('Authentication failed: ${e.message}');
    }
  }
}
