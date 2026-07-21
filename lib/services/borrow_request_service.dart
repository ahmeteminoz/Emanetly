import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/borrow_request.dart';

abstract class BorrowRequestService {
  Future<void> addBorrowRequest(BorrowRequestModel request);
  Future<void> updateBorrowRequestStatus(String requestId, BorrowRequestStatus status);
  Future<void> updateMeetingDetails(String requestId, String location, String note);
  Stream<List<BorrowRequestModel>> listenToBorrowRequests(String userId);
}

class MockBorrowRequestService implements BorrowRequestService {
  final _controller = StreamController<List<BorrowRequestModel>>.broadcast();
  final List<BorrowRequestModel> _requests = [];

  List<BorrowRequestModel> get requests => _requests;

  MockBorrowRequestService();

  @override
  Future<void> addBorrowRequest(BorrowRequestModel request) async {
    _requests.add(request);
    _controller.add(List.from(_requests));
  }

  @override
  Future<void> updateBorrowRequestStatus(String requestId, BorrowRequestStatus status) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: status);
      _controller.add(List.from(_requests));
    }
  }

  @override
  Future<void> updateMeetingDetails(String requestId, String location, String note) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(
        meetingLocation: location,
        meetingNote: note,
        meetingUpdatedAt: DateTime.now(),
      );
      _controller.add(List.from(_requests));
    }
  }

  @override
  Stream<List<BorrowRequestModel>> listenToBorrowRequests(String userId) {
    // Generate initial stream filter
    final userController = StreamController<List<BorrowRequestModel>>.broadcast();
    
    // Initial fetch helper
    List<BorrowRequestModel> getUserRequests() {
      return _requests.where((r) => r.ownerId == userId || r.requesterId == userId).toList();
    }

    userController.add(getUserRequests());

    final subscription = _controller.stream.listen((_) {
      if (!userController.isClosed) {
        userController.add(getUserRequests());
      }
    });

    userController.onCancel = () {
      subscription.cancel();
      userController.close();
    };

    return userController.stream;
  }
}

class FirestoreBorrowRequestService implements BorrowRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> addBorrowRequest(BorrowRequestModel request) async {
    try {
      await _firestore
          .collection('borrowRequests')
          .doc(request.id)
          .set(request.toMap());
    } catch (e) {
      print('Emanetly: Firestore addBorrowRequest error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateBorrowRequestStatus(String requestId, BorrowRequestStatus status) async {
    try {
      await _firestore
          .collection('borrowRequests')
          .doc(requestId)
          .update({'status': status.name});
    } catch (e) {
      print('Emanetly: Firestore updateBorrowRequestStatus error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMeetingDetails(String requestId, String location, String note) async {
    try {
      await _firestore
          .collection('borrowRequests')
          .doc(requestId)
          .update({
            'meetingLocation': location,
            'meetingNote': note,
            'meetingUpdatedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Emanetly: Firestore updateMeetingDetails error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<BorrowRequestModel>> listenToBorrowRequests(String userId) {
    return _firestore
        .collection('borrowRequests')
        .where(Filter.or(
          Filter('ownerId', isEqualTo: userId),
          Filter('requesterId', isEqualTo: userId),
        ))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => BorrowRequestModel.fromMap(doc.data())).toList();
        });
  }
}
