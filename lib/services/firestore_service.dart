import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_input.dart';
import '../utils/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> saveCropInput(CropInput input) async {
    try {
      final docRef = await _db
          .collection(AppConstants.cropInputsCollection)
          .add(input.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save crop data: $e');
    }
  }

  Future<List<CropInput>> getUserHistory(String userId) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.cropInputsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map(CropInput.fromFirestore).toList();
    } catch (e) {
      throw Exception('Failed to fetch history: $e');
    }
  }

  Stream<List<CropInput>> getUserHistoryStream(String userId) {
    return _db
        .collection(AppConstants.cropInputsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CropInput.fromFirestore).toList());
  }

  Future<void> deleteCropInput(String docId) async {
    try {
      await _db
          .collection(AppConstants.cropInputsCollection)
          .doc(docId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete record: $e');
    }
  }
}
