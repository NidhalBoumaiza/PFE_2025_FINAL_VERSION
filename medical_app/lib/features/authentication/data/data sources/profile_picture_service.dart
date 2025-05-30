import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

abstract class ProfilePictureService {
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  });

  Future<void> deleteProfilePicture({
    required String userId,
    required String imageUrl,
  });

  Future<void> updateUserProfilePicture({
    required String userId,
    required String profilePictureUrl,
  });
}

class ProfilePictureServiceImpl implements ProfilePictureService {
  final FirebaseStorage storage;
  final FirebaseFirestore firestore;
  final Uuid uuid = Uuid();

  ProfilePictureServiceImpl({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : this.storage = storage ?? FirebaseStorage.instance,
       this.firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Validate file
      if (!imageFile.existsSync()) {
        throw ServerException('Image file does not exist');
      }

      // Check file size (max 5MB)
      final fileSize = imageFile.lengthSync();
      if (fileSize > 5 * 1024 * 1024) {
        throw ServerException('Image file is too large. Maximum size is 5MB');
      }

      // Check file extension
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(fileExtension.replaceAll('.', ''))) {
        throw ServerException(
          'Invalid file format. Only JPG, JPEG, and PNG are allowed',
        );
      }

      // Generate unique filename
      final imageId = uuid.v4();
      final fileName = '$imageId$fileExtension';
      final originalName = path.basename(imageFile.path);

      // Create storage reference
      final storageRef = storage.ref().child(
        'profile_pictures/$userId/$fileName',
      );

      // Set metadata
      final metadata = SettableMetadata(
        contentType: _getMimeType(fileExtension.replaceAll('.', '')),
        customMetadata: {
          'originalName': originalName,
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file
      final uploadTask = storageRef.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('Profile picture uploaded successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw ServerException('Firebase Storage error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to upload profile picture: $e');
    }
  }

  @override
  Future<void> deleteProfilePicture({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the profile_pictures segment and construct the path
      final profilePicturesIndex = pathSegments.indexOf('profile_pictures');
      if (profilePicturesIndex == -1) {
        throw ServerException('Invalid profile picture URL');
      }

      final filePath = pathSegments.sublist(profilePicturesIndex).join('/');
      final storageRef = storage.ref().child(filePath);

      // Delete file from storage
      await storageRef.delete();
      print('Profile picture deleted successfully from storage');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        print('Profile picture file not found in storage, continuing...');
      } else {
        throw ServerException('Firebase Storage error: ${e.message}');
      }
    } catch (e) {
      throw ServerException('Failed to delete profile picture: $e');
    }
  }

  @override
  Future<void> updateUserProfilePicture({
    required String userId,
    required String profilePictureUrl,
  }) async {
    try {
      // Update user document in Firestore
      await firestore.collection('users').doc(userId).update({
        'profilePictureUrl': profilePictureUrl,
      });
      print('User profile picture URL updated in Firestore');
    } on FirebaseException catch (e) {
      throw ServerException('Firestore error: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to update user profile picture: $e');
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }
}
