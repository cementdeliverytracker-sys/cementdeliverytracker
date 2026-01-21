import 'dart:io';
import 'dart:math';

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
  Future<UserProfile?> fetchUserProfile(String userId);
  Future<UserProfile> ensureEmployeeId(String userId);
  Future<String> submitEmployeeJoinRequest(String userId, String adminCode);
  Future<void> submitAdminRequest(String userId, String companyName);
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
    } on FirebaseAuthException {
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
            'uid': userCredential.user!.uid,
            'username': params.username,
            'email': params.email,
            'phone': params.phone,
            'image_url': imageUrl,
            'userType': AppConstants.userTypeTempEmployee,
            'adminId': null,
            'createdAt': FieldValue.serverTimestamp(),
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

  @override
  Future<UserProfile?> fetchUserProfile(String userId) async {
    try {
      final doc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return _mapDocumentToProfile(doc.data(), userId);
    } catch (e) {
      throw ServerFailure('Failed to load profile: ${e.toString()}');
    }
  }

  @override
  Future<UserProfile> ensureEmployeeId(String userId) async {
    try {
      final profile = await fetchUserProfile(userId);
      if (profile == null) {
        throw ServerFailure('User profile not found');
      }

      final isEmployee = profile.userType == AppConstants.userTypeEmployee;
      final hasId = (profile.employeeId ?? '').trim().isNotEmpty;
      if (!isEmployee || hasId) return profile;

      final newId = await _generateUniqueEmployeeId();
      await firestore.collection(AppConstants.usersCollection).doc(userId).set({
        'employeeId': newId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return profile.copyWith(employeeId: newId);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Failed to ensure employee ID: ${e.toString()}');
    }
  }

  UserProfile _mapDocumentToProfile(Map<String, dynamic>? data, String userId) {
    final safe = data ?? <String, dynamic>{};

    return UserProfile(
      id: userId,
      email: (safe['email'] ?? '') as String,
      username: (safe['username'] ?? '') as String,
      userType: (safe['userType'] ?? AppConstants.userTypePending) as String,
      adminId: safe['adminId'] as String?,
      employeeId: safe['employeeId'] as String?,
      phone: safe['phone'] as String?,
      imageUrl: safe['image_url'] as String?,
    );
  }

  Future<String> _generateUniqueEmployeeId() async {
    const min = 100000;
    const max = 999999;
    final rand = Random.secure();

    for (int i = 0; i < 10; i++) {
      final candidate = (min + rand.nextInt(max - min + 1)).toString();
      final clash = await firestore
          .collection(AppConstants.usersCollection)
          .where('employeeId', isEqualTo: candidate)
          .limit(1)
          .get();
      if (clash.docs.isEmpty) return candidate;
    }

    return (min + rand.nextInt(max - min + 1)).toString();
  }

  @override
  Future<String> submitEmployeeJoinRequest(
    String userId,
    String adminCode,
  ) async {
    try {
      // Verify admin code exists
      final enterpriseSnapshot = await firestore
          .collection(AppConstants.enterprisesCollection)
          .where('adminCode', isEqualTo: adminCode)
          .limit(1)
          .get();

      if (enterpriseSnapshot.docs.isEmpty) {
        throw ValidationFailure('Invalid admin code');
      }

      final adminId = enterpriseSnapshot.docs.first.id;

      // Update user with pending employee request
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'adminId': adminId,
            'userType': AppConstants.userTypePendingEmployee,
            'employeeRequestData': {
              'status': 'pending',
              'requestedAt': FieldValue.serverTimestamp(),
              'adminCode': adminCode,
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return adminId;
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(
        'Failed to submit employee join request: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> submitAdminRequest(String userId, String companyName) async {
    try {
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'userType': AppConstants.userTypePending,
            'adminRequestData': {
              'companyName': companyName,
              'requestedAt': FieldValue.serverTimestamp(),
              'status': 'pending',
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw ServerFailure('Failed to submit admin request: ${e.toString()}');
    }
  }
}
