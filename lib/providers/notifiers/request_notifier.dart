import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/borrow_request.dart';
import '../../models/chat_message.dart';
import '../../models/meeting_point_proposal.dart';
import '../../models/user_profile.dart';
import '../../services/borrow_request_service.dart';
import '../../services/chat_message_service.dart';
import '../../services/analytics_service.dart';

/// RequestNotifier - Ödünç talepleri, sohbet mesajları ve buluşma noktası
/// tekliflerini yönetir. AppState facade tarafından orkestra edilir.
class RequestNotifier extends ChangeNotifier {
  final BorrowRequestService _borrowRequestService;
  final ChatMessageService _chatMessageService;
  final AnalyticsService _analyticsService;

  /// Cross-cutting: Mevcut kullanıcıyı döner (AppState'ten callback)
  final UserProfile? Function() _currentUser;

  /// Cross-cutting: Kullanıcının engellenip engellenmediğini kontrol eder
  final bool Function(String uid) _isUserBlocked;

  // ─── State ───────────────────────────────────────────────────────────────
  final List<BorrowRequestModel> _borrowRequests = [];
  final List<ChatMessageModel> _chatMessages = [];
  final List<MeetingPointProposalModel> _meetingPointProposals = [];

  String? _activeChatRequestId;

  StreamSubscription<List<BorrowRequestModel>>? _requestsSubscription;
  StreamSubscription<List<ChatMessageModel>>? _chatSubscription;

  // ─── Activity log callback ────────────────────────────────────────────────
  void Function(String log)? onLog;

  // ─── Public service getters (AppState iç erişimi için) ───────────────────
  BorrowRequestService get borrowRequestService => _borrowRequestService;
  ChatMessageService get chatMessageService => _chatMessageService;

  /// AppState'in doğrudan erişmesi gereken mutable list (confirmHandoverAction gibi)
  List<BorrowRequestModel> get mutableBorrowRequests => _borrowRequests;
  List<MeetingPointProposalModel> get mutableMeetingPointProposals =>
      _meetingPointProposals;

  RequestNotifier({
    required BorrowRequestService borrowRequestService,
    required ChatMessageService chatMessageService,
    required UserProfile? Function() currentUser,
    required bool Function(String uid) isUserBlocked,
    AnalyticsService? analyticsService,
  })  : _borrowRequestService = borrowRequestService,
        _chatMessageService = chatMessageService,
        _currentUser = currentUser,
        _isUserBlocked = isUserBlocked,
        _analyticsService = analyticsService ?? AnalyticsService();

  void _addLog(String log) => onLog?.call(log);

  // ─── Getters ─────────────────────────────────────────────────────────────
  List<BorrowRequestModel> get borrowRequests => _borrowRequests;

  List<ChatMessageModel> getChatMessagesForRequest(String requestId) {
    final user = _currentUser();
    final list = _chatMessages
        .where((msg) =>
            msg.requestId == requestId &&
            (msg.senderId == user?.uid ||
                msg.senderId == 'system' ||
                !_isUserBlocked(msg.senderId)))
        .toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  int getUnreadCountForRequest(String requestId) {
    final user = _currentUser();
    if (user == null) return 0;
    return _chatMessages
        .where((msg) =>
            msg.requestId == requestId &&
            msg.senderId != user.uid &&
            !_isUserBlocked(msg.senderId) &&
            !msg.isRead)
        .length;
  }

  int get totalUnreadCount {
    final user = _currentUser();
    if (user == null) return 0;
    final myRequestIds = _borrowRequests.map((r) => r.id).toSet();
    return _chatMessages
        .where((msg) =>
            myRequestIds.contains(msg.requestId) &&
            msg.senderId != user.uid &&
            !_isUserBlocked(msg.senderId) &&
            !msg.isRead)
        .length;
  }

  MeetingPointProposalModel? getProposal(String proposalId) {
    try {
      return _meetingPointProposals.firstWhere((p) => p.id == proposalId);
    } catch (_) {
      return null;
    }
  }

  BorrowRequestModel? getRequestForActiveItem(String itemId) {
    try {
      return _borrowRequests.firstWhere(
        (req) =>
            req.itemId == itemId &&
            req.status != BorrowRequestStatus.rejected &&
            req.status != BorrowRequestStatus.cancelled &&
            req.status != BorrowRequestStatus.expired &&
            req.status != BorrowRequestStatus.completed,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Active Chat Room ─────────────────────────────────────────────────────
  void setActiveChatRoom(String? requestId) {
    if (_activeChatRequestId == requestId && _chatSubscription != null) return;
    _activeChatRequestId = requestId;
    _chatSubscription?.cancel();
    _chatSubscription = null;

    if (requestId != null && requestId.isNotEmpty) {
      _chatSubscription =
          _chatMessageService.listenToChatMessages(requestId).listen(
        (newMessages) {
          _chatMessages.removeWhere((msg) => msg.requestId == requestId);
          _chatMessages.addAll(newMessages);
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Emanetly: Chat stream error: $e');
        },
      );
    }
  }

  // ─── Actions ─────────────────────────────────────────────────────────────
  Future<void> sendChatMessage(
    String requestId,
    String text, {
    String? customPayload,
  }) async {
    final user = _currentUser();
    if (user == null) return;

    String senderName = user.name.trim();
    if (senderName.isEmpty && user.email.isNotEmpty) {
      senderName = user.email.split('@').first;
    }
    if (senderName.isEmpty) senderName = 'Öğrenci';

    final message = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      senderId: user.uid,
      senderName: senderName,
      text: text,
      type: ChatMessageType.text,
      createdAt: DateTime.now().toUtc(),
      customPayload: customPayload,
    );
    await _chatMessageService.sendChatMessage(message);
    _analyticsService.logChatMessageSent(messageType: 'text');
    _addLog('Mesaj gönderildi: "$text"');
  }

  Future<void> markMessagesAsRead(String requestId) async {
    final user = _currentUser();
    if (user == null) return;

    var localUpdated = false;
    for (var i = 0; i < _chatMessages.length; i++) {
      final msg = _chatMessages[i];
      if (msg.requestId == requestId &&
          msg.senderId != user.uid &&
          !msg.isRead) {
        _chatMessages[i] = ChatMessageModel(
          id: msg.id,
          requestId: msg.requestId,
          senderId: msg.senderId,
          senderName: msg.senderName,
          text: msg.text,
          type: msg.type,
          createdAt: msg.createdAt,
          customPayload: msg.customPayload,
          isRead: true,
        );
        localUpdated = true;
      }
    }
    if (localUpdated) notifyListeners();

    await _chatMessageService.markMessagesAsRead(requestId, user.uid);
  }

  Future<void> upgradeToOfficialRequest(String requestId) async {
    final index = _borrowRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    await _borrowRequestService.updateBorrowRequestStatus(
      requestId,
      BorrowRequestStatus.pendingDiscussion,
    );

    await _chatMessageService.sendChatMessage(ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Ödünç talebi gönderildi. İlan sahibinin yanıtı bekleniyor.',
      type: ChatMessageType.system,
      createdAt: DateTime.now(),
    ));

    _addLog('Ödünç talebi resmiyete döküldü.');
    notifyListeners();
  }

  Future<void> proposeMeetingPoint(
    String requestId,
    String title,
    String addressText,
    String timeText,
  ) async {
    final user = _currentUser();
    if (user == null) return;

    final proposalId = 'prop_${DateTime.now().millisecondsSinceEpoch}';
    final requestIndex = _borrowRequests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return;
    final request = _borrowRequests[requestIndex];

    final isOwner = user.uid == request.ownerId;

    final proposal = MeetingPointProposalModel(
      id: proposalId,
      requestId: requestId,
      proposedByUserId: user.uid,
      title: title,
      addressText: addressText,
      proposedTimeText: timeText,
      status: MeetingPointStatus.pending,
      acceptedByOwner: isOwner,
      acceptedByRequester: !isOwner,
    );

    _meetingPointProposals.add(proposal);
    _borrowRequests[requestIndex] =
        request.copyWith(proposedMeetingPointId: proposalId);

    final message = ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Buluşma noktası önerildi: $title ($timeText)',
      type: ChatMessageType.meetingPointProposal,
      createdAt: DateTime.now(),
      customPayload: proposalId,
    );
    await _chatMessageService.sendChatMessage(message);

    _addLog('Yeni buluşma noktası önerildi: $title');
    notifyListeners();
  }

  Future<void> acceptMeetingPoint(String proposalId) async {
    final propIndex =
        _meetingPointProposals.indexWhere((p) => p.id == proposalId);
    if (propIndex == -1) return;
    final proposal = _meetingPointProposals[propIndex];

    _meetingPointProposals[propIndex] = proposal.copyWith(
      acceptedByOwner: true,
      acceptedByRequester: true,
      status: MeetingPointStatus.accepted,
    );

    final message = ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: proposal.requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Buluşma noktası onaylandı: ${proposal.title}',
      type: ChatMessageType.system,
      createdAt: DateTime.now(),
    );
    await _chatMessageService.sendChatMessage(message);

    _addLog('Buluşma noktası onaylandı: ${proposal.title}');
    notifyListeners();
  }

  Future<void> rejectMeetingPoint(String proposalId) async {
    final propIndex =
        _meetingPointProposals.indexWhere((p) => p.id == proposalId);
    if (propIndex == -1) return;
    final proposal = _meetingPointProposals[propIndex];

    _meetingPointProposals[propIndex] = proposal.copyWith(
      status: MeetingPointStatus.rejected,
    );

    final message = ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: proposal.requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Buluşma noktası reddedildi: ${proposal.title}',
      type: ChatMessageType.system,
      createdAt: DateTime.now(),
    );
    await _chatMessageService.sendChatMessage(message);

    _addLog('Buluşma noktası reddedildi: ${proposal.title}');
    notifyListeners();
  }

  Future<void> rejectBorrowRequest(String requestId) async {
    final reqIndex = _borrowRequests.indexWhere((r) => r.id == requestId);
    if (reqIndex == -1) return;

    await _borrowRequestService.updateBorrowRequestStatus(
        requestId, BorrowRequestStatus.rejected);

    final message = ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Talep reddedildi. Görüşme sonlandırıldı.',
      type: ChatMessageType.requestStatusUpdate,
      createdAt: DateTime.now(),
    );
    await _chatMessageService.sendChatMessage(message);

    _addLog('Ödünç talebi reddedildi.');
  }

  // ─── Subscription Management ─────────────────────────────────────────────
  void startRequestsSubscription(String userId) {
    _requestsSubscription?.cancel();
    _requestsSubscription =
        _borrowRequestService.listenToBorrowRequests(userId).listen(
      (newRequests) {
        _borrowRequests.clear();
        _borrowRequests.addAll(newRequests);
        notifyListeners();
      },
      onError: (e) {
        _addLog('Talep verisi dinleme hatası: $e');
      },
    );
  }

  void cancelRequestsSubscription() {
    _requestsSubscription?.cancel();
    _requestsSubscription = null;
    _chatSubscription?.cancel();
    _chatSubscription = null;
    _activeChatRequestId = null;
    _borrowRequests.clear();
    _chatMessages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _chatSubscription?.cancel();
    super.dispose();
  }
}
