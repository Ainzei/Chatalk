import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/models/chat_preview.dart';
import 'package:flutter_chat_ui/data/facebook_export_groups.dart';

class ChatService {
  // Singleton pattern for better performance
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Performance caches
  final Map<String, AppUser> _userCache = {};
  AppUser? _currentUserCache;
  DateTime? _currentUserCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Helper to get timestamp that works on both web and native
  dynamic get serverTimestamp {
    if (kIsWeb) {
      return Timestamp.now();
    }
    return FieldValue.serverTimestamp();
  }

  int uidForUser(String userId) {
    if (userId.isEmpty) return 1;
    final hash = userId.hashCode;
    final positive = hash < 0 ? -hash : hash;
    // Agora UID must be 32-bit unsigned int, avoid 0
    return (positive % 2147483647) + 1;
  }

  Future<void> ensureUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // For web, use a simpler approach due to some Firestore limitations
      if (kIsWeb) {
        try {
          final ref = _firestore.collection('users').doc(user.uid);
          final snap = await ref.get().timeout(
                const Duration(seconds: 5),
                onTimeout: () => throw Exception('Firestore timeout'),
              );
          if (!snap.exists) {
            final shortId = user.uid.substring(0, 6).toUpperCase();
            final displayName = user.displayName?.trim();
            final email = user.email?.trim();
            final nameFromEmail = (email != null && email.isNotEmpty)
                ? email.split('@').first
                : null;
            final resolvedName = (displayName != null && displayName.isNotEmpty)
                ? displayName
                : (nameFromEmail != null && nameFromEmail.isNotEmpty)
                    ? nameFromEmail
                    : 'Anonymous $shortId';
            
            // Use DateTime.now() instead of serverTimestamp on web
            await ref.set({
              'name': resolvedName,
              'photoUrl': '',
              'email': email ?? '',
              'createdAt': DateTime.now().toIso8601String(),
              'friends': <String>[],
              'stories': <String>[],
              'friendRequests': <String>[],
              'isOnline': false,
            }).timeout(
              const Duration(seconds: 5),
              onTimeout: () => throw Exception('Firestore timeout'),
            );
            
            // Create private conversations with other users
            await _createRealUserConversations(user.uid);
          }
        } catch (e) {
          debugPrint('Web Firestore operation skipped: $e');
          // Don't crash on web - it might just be missing data
          return;
        }
        return;
      }
      
      final ref = _firestore.collection('users').doc(user.uid);
      final snap = await ref.get().timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Firestore timeout'),
          );
      if (!snap.exists) {
        final shortId = user.uid.substring(0, 6).toUpperCase();
        final displayName = user.displayName?.trim();
        final email = user.email?.trim();
        final nameFromEmail = (email != null && email.isNotEmpty)
            ? email.split('@').first
            : null;
        final resolvedName = (displayName != null && displayName.isNotEmpty)
            ? displayName
            : (nameFromEmail != null && nameFromEmail.isNotEmpty)
                ? nameFromEmail
                : 'Anonymous $shortId';
        await ref.set({
          'name': resolvedName,
          'photoUrl': '',
          'email': email ?? '',
          'createdAt': serverTimestamp,
          'friends': <String>[],
          'stories': <String>[],
          'friendRequests': <String>[],
          'isOnline': false,
        }).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('Firestore timeout'),
        );
        
        // Create private conversations with other users
        await _createRealUserConversations(user.uid);
      } else {
        final data = snap.data() ?? {};
        final currentName = (data['name'] ?? '').toString().trim();
        final currentEmail = (data['email'] ?? '').toString().trim();
        final updates = <String, dynamic>{};

        if (!data.containsKey('stories')) {
          updates['stories'] = <String>[];
        }

        if (!data.containsKey('friendRequests')) {
          updates['friendRequests'] = <String>[];
        }

        if (!data.containsKey('isOnline')) {
          updates['isOnline'] = false;
        }

        if (currentName.isEmpty) {
          final displayName = user.displayName?.trim();
          final email = user.email?.trim();
          final nameFromEmail = (email != null && email.isNotEmpty)
              ? email.split('@').first
              : null;
          final resolvedName = (displayName != null && displayName.isNotEmpty)
              ? displayName
              : (nameFromEmail != null && nameFromEmail.isNotEmpty)
                  ? nameFromEmail
                  : 'Anonymous ${user.uid.substring(0, 6).toUpperCase()}';
          updates['name'] = resolvedName;
        }

        if (currentEmail.isEmpty && (user.email ?? '').isNotEmpty) {
          updates['email'] = user.email;
        }

        if (updates.isNotEmpty) {
          await ref.update(updates).timeout(
                const Duration(seconds: 5),
                onTimeout: () => throw Exception('Firestore timeout'),
              );
        }
      }
      
      // Import Facebook data in background (silently)
      _importFacebookDataInBackground(user.uid);
    } catch (e) {
      debugPrint('Firestore error (will retry): $e');
      // Don't rethrow on unsupported operations - just log and continue
      if (e.toString().contains('Unsupported operation')) {
        debugPrint('Unsupported Firestore operation on this platform');
        return;
      }
      rethrow;
    }
  }

  /// Import Facebook data in background without blocking or showing UI
  void _importFacebookDataInBackground(String userId) {
    // Skip on web or if not the specific test account
    if (kIsWeb) return;
    
    // Run import in background without awaiting
    Future(() async {
      try {
        // Check if data already imported (look for a flag in user doc)
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await userRef.get();
        final alreadyImported = userDoc.data()?['facebookDataImported'] ?? false;
        
        if (alreadyImported) return;

        // Only import if this is the specific account
        final user = _auth.currentUser;
        if (user?.email != 'sandovalchristianace3206@gmail.com') return;

        await _importFacebookUsersAndGroups();
        await userRef.update({'facebookDataImported': true});
      } catch (e) {
        debugPrint('Error creating user (non-critical): $e');
      }
    });
  }

  String _slugifyName(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'user' : normalized;
  }

  int _stableHash(String input) {
    // Simple deterministic hash (djb2)
    var hash = 5381;
    for (final codeUnit in input.codeUnits) {
      hash = ((hash << 5) + hash) + codeUnit;
      hash &= 0x7fffffff;
    }
    return hash;
  }

  String _facebookUserId(String name) {
    final slug = _slugifyName(name);
    final hash = _stableHash(name).toString();
    return 'fb_${slug}_$hash';
  }

  String _facebookGroupId(String name) {
    final slug = _slugifyName(name);
    final hash = _stableHash(name).toString();
    return 'fb_group_${slug}_$hash';
  }

  Future<void> _importFacebookUsersAndGroups() async {
    // Create/ensure users
    final usersRef = _firestore.collection('users');
    final allUsers = facebookExportUsers;

    WriteBatch batch = _firestore.batch();
    var batchCount = 0;

    Future<void> commitBatchIfNeeded() async {
      if (batchCount >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
    }

    for (final user in allUsers) {
      final userId = _facebookUserId(user.name);
      final docRef = usersRef.doc(userId);
      batch.set(
        docRef,
        {
          'name': user.name,
          'photoUrl': '',
          'email': '',
          'createdAt': serverTimestamp,
          'friends': <String>[],
          'stories': <String>[],
          'friendRequests': <String>[],
          'isOnline': false,
          'source': 'facebook_export',
        },
        SetOptions(merge: true),
      );
      batchCount++;
      await commitBatchIfNeeded();
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    // Create/ensure group chats
    final groupsRef = _firestore.collection('group_chats');
    WriteBatch groupBatch = _firestore.batch();
    var groupBatchCount = 0;

    Future<void> commitGroupBatchIfNeeded() async {
      if (groupBatchCount >= 400) {
        await groupBatch.commit();
        groupBatch = _firestore.batch();
        groupBatchCount = 0;
      }
    }

    for (final group in facebookExportGroups) {
      final groupId = _facebookGroupId(group.name);
      final memberIds = group.members
          .map((m) => _facebookUserId(m.name))
          .toList(growable: false);
      final memberNames = group.members.map((m) => m.name).toList(growable: false);

      final docRef = groupsRef.doc(groupId);
      groupBatch.set(
        docRef,
        {
          'name': group.name,
          'members': memberIds,
          'memberNames': memberNames,
          'isGroup': true,
          'lastMessage': '',
          'lastMessageAt': serverTimestamp,
          'createdAt': serverTimestamp,
          'source': 'facebook_export',
        },
        SetOptions(merge: true),
      );
      groupBatchCount++;
      await commitGroupBatchIfNeeded();
    }

    if (groupBatchCount > 0) {
      await groupBatch.commit();
    }

    // Create private conversations with all Facebook users
    await _createPrivateConversations(currentUserId, allUsers);
  }

  /// Create private one-on-one conversations with all Facebook export users
  Future<void> _createPrivateConversations(String currentUserId, List<dynamic> facebookUsers) async {
    if (currentUserId.isEmpty) return;

    final chatsRef = _firestore.collection('chats');
    WriteBatch batch = _firestore.batch();
    var batchCount = 0;

    Future<void> commitBatchIfNeeded() async {
      if (batchCount >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
    }

    for (final user in facebookUsers) {
      final fbUserId = _facebookUserId(user.name);
      final chatId = chatIdFor(currentUserId, fbUserId);
      final chatRef = chatsRef.doc(chatId);

      batch.set(
        chatRef,
        {
          'participants': [currentUserId, fbUserId],
          'members': [currentUserId, fbUserId],
          'roomType': 'Private',
          'lastMessage': '',
          'lastMessageType': 'text',
          'lastMessageAt': serverTimestamp,
          'lastSenderId': '',
          'lastSenderName': '',
          'updatedAt': serverTimestamp,
          'isFriendChat': true,
          'source': 'facebook_export',
        },
        SetOptions(merge: true),
      );

      batchCount++;
      await commitBatchIfNeeded();
    }

    if (batchCount > 0) {
      await batch.commit();
    }
  }

  /// Create private conversations for a real Firebase user with all other real users
  Future<void> _createRealUserConversations(String currentUserId) async {
    if (currentUserId.isEmpty) return;
    
    try {
      debugPrint('🔄 Creating real user conversations for $currentUserId...');
      
      // Get all users except current user
      final usersSnap = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .get()
          .timeout(const Duration(seconds: 10));
      
      debugPrint('📋 Found ${usersSnap.docs.length} other users');
      
      final chatsRef = _firestore.collection('chats');
      WriteBatch batch = _firestore.batch();
      var batchCount = 0;
      var createdCount = 0;

      for (final userDoc in usersSnap.docs) {
        final otherUserId = userDoc.id;
        final chatId = chatIdFor(currentUserId, otherUserId);
        final chatRef = chatsRef.doc(chatId);

        // Check if chat already exists
        final existing = await chatRef.get();
        if (!existing.exists) {
          debugPrint('  ➕ Creating chat: $chatId');
          batch.set(
            chatRef,
            {
              'participants': [currentUserId, otherUserId],
              'members': [currentUserId, otherUserId],
              'roomType': 'Private',
              'lastMessage': '',
              'lastMessageType': 'text',
              'lastMessageAt': serverTimestamp, // Use compatible getter
              'lastSenderId': '',
              'lastSenderName': '',
              'updatedAt': serverTimestamp,
              'isFriendChat': true,
              'source': 'real_users',
            },
            SetOptions(merge: true),
          );

          createdCount++;
          batchCount++;
          if (batchCount >= 100) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
            debugPrint('  ✅ Committed $createdCount chats so far...');
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }
      
      debugPrint('✅ Real user conversations created: $createdCount new chats for $currentUserId');
    } catch (e) {
      debugPrint('❌ Error creating real user conversations: $e');
      // Don't fail - this is optional
    }
  }

  /// Public method to ensure all conversations exist for current user
  /// Can be called from UI, especially on web where PopulateUsersAndChats.run() skips
  Future<void> ensureAllConversations() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId.isEmpty) {
      debugPrint('⚠️ Cannot ensure conversations: No user logged in');
      return;
    }
    
    debugPrint('🔄 Ensuring all conversations exist for current user: $currentUserId');
    await _createRealUserConversations(currentUserId);
    debugPrint('✅ Conversation generation complete!');
  }

  String chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<AppUser>> usersStream() {
    return _firestore
        .collection('users')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromDoc(doc))
            .toList());
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> currentUserDocStream() {
    final uid = currentUserId;
    if (uid.isEmpty) {
      return const Stream.empty();
    }
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Stream<List<ChatPreview>> chatPreviewsStream() {
    final uid = currentUserId;
    if (uid.isEmpty) {
      return const Stream.empty();
    }
    // Note: This query requires a Firestore composite index on (participants, lastMessageAt DESC)
    // If you see "FAILED_PRECONDITION" errors, create the index via the Firebase Console link
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          // Sort on client side to avoid requiring a composite index
          final chats = snapshot.docs
              .map((doc) => ChatPreview.fromDoc(doc, uid))
              .where((chat) => !(chat.isMessageRequest && chat.requestTo == uid))
              .toList();
          chats.sort((a, b) {
            final aTime = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime); // descending order
          });
          return chats;
        });
  }

  Stream<List<ChatPreview>> messageRequestsStream() {
    final uid = currentUserId;
    if (uid.isEmpty) {
      return const Stream.empty();
    }
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ChatPreview.fromDoc(doc, uid))
              .where((chat) => chat.isMessageRequest && chat.requestTo == uid)
              .toList();
          requests.sort((a, b) {
            final aTime = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });
          return requests;
        });
  }

  Stream<List<ChatPreview>> archivedChatsStream() {
    final uid = currentUserId;
    if (uid.isEmpty) {
      return const Stream.empty();
    }
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final archived = snapshot.docs
              .map((doc) => ChatPreview.fromDoc(doc, uid))
              .where((chat) => chat.isArchived)
              .toList();
          archived.sort((a, b) {
            final aTime = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
            final bTime = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;
            return bTime.compareTo(aTime);
          });
          return archived;
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(
      String otherUserId, {int limit = 50}) {
    final chatId = chatIdFor(currentUserId, otherUserId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<AppUser?> fetchUser(String uid) async {
    if (uid.isEmpty) return null;
    
    // Check cache first
    if (_userCache.containsKey(uid)) {
      return _userCache[uid];
    }
    
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    
    final user = AppUser.fromDoc(doc);
    _userCache[uid] = user;
    return user;
  }
  
  // Batch fetch users for better performance
  Future<Map<String, AppUser>> fetchUsers(List<String> uids) async {
    final result = <String, AppUser>{};
    final toFetch = <String>[];
    
    // Check cache first
    for (final uid in uids) {
      if (uid.isEmpty) continue;
      if (_userCache.containsKey(uid)) {
        result[uid] = _userCache[uid]!;
      } else {
        toFetch.add(uid);
      }
    }
    
    // Fetch remaining in batches of 10 (Firestore 'in' query limit)
    for (var i = 0; i < toFetch.length; i += 10) {
      final batch = toFetch.skip(i).take(10).toList();
      final docs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      for (final doc in docs.docs) {
        if (doc.exists) {
          final user = AppUser.fromDoc(doc);
          _userCache[doc.id] = user;
          result[doc.id] = user;
        }
      }
    }
    
    return result;
  }

  Future<AppUser?> getCurrentUser() async {
    final uid = currentUserId;
    if (uid.isEmpty) return null;
    
    // Check cache
    final now = DateTime.now();
    if (_currentUserCache != null && _currentUserCacheTime != null) {
      if (now.difference(_currentUserCacheTime!) < _cacheDuration) {
        return _currentUserCache;
      }
    }
    
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    
    _currentUserCache = AppUser.fromDoc(doc);
    _currentUserCacheTime = now;
    return _currentUserCache;
  }
  
  // Clear caches (call when user logs out)
  void clearCache() {
    _userCache.clear();
    _currentUserCache = null;
    _currentUserCacheTime = null;
  }

  Future<void> sendMessage(String otherUserId, String text, {String? senderName}) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final now = serverTimestamp;
    String? name = senderName;
    if (name == null || name.isEmpty) {
      final me = await getCurrentUser();
      name = me?.name ?? '';
    }

    // Check if users are friends
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final isFriend = (userDoc.data()?['friends'] as List<dynamic>?)?.contains(otherUserId) ?? false;
    final isMessageRequest = !isFriend;
    final requestTo = isMessageRequest ? otherUserId : '';
    final requestFrom = isMessageRequest ? uid : '';

    await chatRef.set({
      'participants': [uid, otherUserId],
      'members': [uid, otherUserId],
      'roomType': 'Private',
      'lastMessage': text,
      'lastMessageType': 'text',
      'lastMessageAt': now,
      'lastSenderId': uid,
      'lastSenderName': name,
      'updatedAt': now,
      'isFriendChat': isFriend,
      'isMessageRequest': isMessageRequest,
      'requestTo': requestTo,
      'requestFrom': requestFrom,
    }, SetOptions(merge: true));

    if (isMessageRequest) {
      await sendFriendRequest(otherUserId);
    }

    await chatRef.collection('messages').add({
      'senderId': uid,
      'senderName': name,
      'text': text,
      'type': 'text',
      'messageType': 'text',
      'readStatus': false,
      'deliveredStatus': true,
      'unreadMembers': [otherUserId],
      'undeliveredMembers': [otherUserId],
      'timeSent': now,
      'createdAt': now,
    });
  }

  Future<String?> uploadFile({
    required File file,
    required String folder,
    required String fileName,
  }) async {
    try {
      if (!await file.exists()) {
        debugPrint('Upload failed: File does not exist at ${file.path}');
        return null;
      }
      final fileSize = await file.length();
      debugPrint('Uploading $folder/$fileName (size: $fileSize bytes)');

      // Upload to Firebase Storage if needed
      debugPrint('File upload not configured - use Firebase Storage');
      return null;
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  Future<void> sendMediaMessage({
    required String otherUserId,
    required String type,
    required String mediaUrl,
    String? fileName,
    int? fileSize,
    int? durationMs,
    String? mimeType,
    String? text,
    String? senderName,
  }) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final now = serverTimestamp;
    String? name = senderName;
    if (name == null || name.isEmpty) {
      final me = await getCurrentUser();
      name = me?.name ?? '';
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final isFriend = (userDoc.data()?['friends'] as List<dynamic>?)?.contains(otherUserId) ?? false;
    final isMessageRequest = !isFriend;
    final requestTo = isMessageRequest ? otherUserId : '';
    final requestFrom = isMessageRequest ? uid : '';

    final lastMessageLabel = switch (type) {
      'image' => 'Photo',
      'video' => 'Video',
      'audio' => 'Voice message',
      'file' => fileName ?? 'File',
      'profile' => 'Profile photo',
      _ => 'Message',
    };

    await chatRef.set({
      'participants': [uid, otherUserId],
      'members': [uid, otherUserId],
      'roomType': 'Private',
      'lastMessage': lastMessageLabel,
      'lastMessageType': type,
      'lastMessageAt': now,
      'lastSenderId': uid,
      'lastSenderName': name,
      'updatedAt': now,
      'isFriendChat': isFriend,
      'isMessageRequest': isMessageRequest,
      'requestTo': requestTo,
      'requestFrom': requestFrom,
    }, SetOptions(merge: true));

    if (isMessageRequest) {
      await sendFriendRequest(otherUserId);
    }

    await chatRef.collection('messages').add({
      'senderId': uid,
      'senderName': name,
      'text': text ?? '',
      'type': type,
      'messageType': type,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'durationMs': durationMs,
      'mimeType': mimeType,
      'readStatus': false,
      'deliveredStatus': true,
      'unreadMembers': [otherUserId],
      'undeliveredMembers': [otherUserId],
      'timeSent': now,
      'createdAt': now,
    });
  }

  // Mark the last message in a chat as read by the current user
  Future<void> markLastMessageAsRead(String otherUserId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.update({
      'readBy': FieldValue.arrayUnion([uid]),
    });
  }

  // Add a friend to current user's friends list
  Future<void> addFriend(String friendUserId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    final userRef = _firestore.collection('users').doc(uid);
    await userRef.update({
      'friends': FieldValue.arrayUnion([friendUserId]),
    });

    // Optionally add current user to friend's list too (mutual friendship)
    final friendRef = _firestore.collection('users').doc(friendUserId);
    await friendRef.update({
      'friends': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> sendFriendRequest(String toUserId) async {
    final uid = currentUserId;
    if (uid.isEmpty || toUserId.isEmpty) return;

    final toUserRef = _firestore.collection('users').doc(toUserId);
    await toUserRef.update({
      'friendRequests': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> acceptFriendRequest(String fromUserId) async {
    final uid = currentUserId;
    if (uid.isEmpty || fromUserId.isEmpty) return;

    await addFriend(fromUserId);

    final userRef = _firestore.collection('users').doc(uid);
    await userRef.update({
      'friendRequests': FieldValue.arrayRemove([fromUserId]),
    });

    final chatRef = _firestore.collection('chats').doc(chatIdFor(uid, fromUserId));
    await chatRef.set({
      'isFriendChat': true,
      'isMessageRequest': false,
      'requestTo': '',
      'requestFrom': '',
      'updatedAt': serverTimestamp,
    }, SetOptions(merge: true));
  }

  Future<void> declineFriendRequest(String fromUserId) async {
    final uid = currentUserId;
    if (uid.isEmpty || fromUserId.isEmpty) return;

    final userRef = _firestore.collection('users').doc(uid);
    await userRef.update({
      'friendRequests': FieldValue.arrayRemove([fromUserId]),
    });

    final chatRef = _firestore.collection('chats').doc(chatIdFor(uid, fromUserId));
    try {
      await chatRef.delete();
    } catch (e) {
      debugPrint('❌ Failed to delete declined request chat: $e');
    }
  }

  // Create a new user profile (for adding friends manually)
  Future<String> createUserProfile({
    required String name,
    String email = '',
    String photoUrl = '',
  }) async {
    final docRef = _firestore.collection('users').doc();
    
    await docRef.set({
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': serverTimestamp,
      'friends': <String>[],
      'stories': <String>[],
      'friendRequests': <String>[],
      'isOnline': false,
    });

    return docRef.id;
  }

  // Update current user's profile
  Future<void> updateProfile({
    String? name,
    String? photoUrl,
    String? nickname,
  }) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (nickname != null) updates['nickname'] = nickname;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  // Toggle story status for a user
  Future<void> toggleStory(String userId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();
    final data = doc.data();
    final stories = List<String>.from(data?['stories'] ?? []);

    if (stories.contains(userId)) {
      await userRef.update({
        'stories': FieldValue.arrayRemove([userId]),
      });
    } else {
      await userRef.update({
        'stories': FieldValue.arrayUnion([userId]),
      });
    }
  }

  // Toggle favorite status for a user
  Future<void> toggleFavorite(String userId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();
    final data = doc.data();
    final favorites = List<String>.from(data?['favorites'] ?? []);

    if (favorites.contains(userId)) {
      await userRef.update({
        'favorites': FieldValue.arrayRemove([userId]),
      });
    } else {
      await userRef.update({
        'favorites': FieldValue.arrayUnion([userId]),
      });
    }
  }

  // Archive a chat
  Future<void> archiveChat(String chatId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({'isArchived': true});
  }

  // Unarchive a chat
  Future<void> unarchiveChat(String chatId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({'isArchived': false});
  }

  // Repair chats missing lastMessageAt field
  Future<void> repairChatsTimestamps() async {
    final uid = currentUserId;
    if (uid.isEmpty) {
      debugPrint('Cannot repair chats: no current user');
      return;
    }

    try {
      debugPrint('Starting chat repair for user: $uid');
      
      // First, get all chats without the orderBy constraint
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: uid)
          .get();

      debugPrint('Found ${chatsSnapshot.docs.length} chats to check');

      for (final chatDoc in chatsSnapshot.docs) {
        final data = chatDoc.data();
        debugPrint('Checking chat ${chatDoc.id}: lastMessageAt = ${data['lastMessageAt']}');
        
        if (data['lastMessageAt'] == null) {
          debugPrint('Chat ${chatDoc.id} missing lastMessageAt, fetching from messages...');
          
          // Get the latest message timestamp
          final messagesSnapshot = await chatDoc.reference
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

          if (messagesSnapshot.docs.isNotEmpty) {
            final lastMessageData = messagesSnapshot.docs.first.data();
            final lastMessageAt = lastMessageData['createdAt'];
            
            debugPrint('Updating chat ${chatDoc.id} with lastMessageAt: $lastMessageAt');
            
            await chatDoc.reference.update({
              'lastMessageAt': lastMessageAt,
            });
          } else {
            debugPrint('Chat ${chatDoc.id} has no messages, skipping');
          }
        }
      }
      
      debugPrint('Chat repair completed');
    } catch (e) {
      debugPrint('Error repairing chat timestamps: $e');
    }
  }

  // ==================== CALL MANAGEMENT ====================
  
  /// Initiate a call and store it in Firestore
  /// Returns a map with callId and channelName
  Future<Map<String, String>?> initiateCall({
    required String recipientId,
    required bool isVideo,
  }) async {
    try {
      final callId = _firestore.collection('calls').doc().id;
      final channelName = 'call_$callId';
      await _firestore.collection('calls').doc(callId).set({
        'callId': callId,
        'callerId': currentUserId,
        'recipientId': recipientId,
        'isVideo': isVideo,
        'status': 'ringing', // ringing, accepted, declined, ended
        'createdAt': serverTimestamp,
        'channelName': channelName,
      });
      return {
        'callId': callId,
        'channelName': channelName,
      };
    } catch (e) {
      debugPrint('Error initiating call: $e');
      return null;
    }
  }

  /// Listen for incoming calls
  Stream<DocumentSnapshot?> listenForIncomingCalls() {
    return _firestore
        .collection('calls')
        .where('recipientId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return snapshot.docs.first;
        });
  }

  /// Accept a call
  Future<void> acceptCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': 'accepted',
      });
    } catch (e) {
      debugPrint('Error accepting call: $e');
    }
  }

  /// Decline a call
  Future<void> declineCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': 'declined',
      });
      // Delete the call after a short delay
      await Future.delayed(const Duration(seconds: 1));
      await _firestore.collection('calls').doc(callId).delete();
    } catch (e) {
      debugPrint('Error declining call: $e');
    }
  }

  /// End a call
  Future<void> endCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': 'ended',
        'endedAt': serverTimestamp,
      });
      // Delete the call after a short delay
      await Future.delayed(const Duration(seconds: 1));
      await _firestore.collection('calls').doc(callId).delete();
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  /// Get active call details
  Future<Map<String, dynamic>?> getCallDetails(String callId) async {
    try {
      final doc = await _firestore.collection('calls').doc(callId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting call details: $e');
      return null;
    }
  }

  // ==================== ADVANCED MESSAGING FEATURES ====================

  /// Send message with reply-to support
  Future<void> sendMessageWithReply(
    String otherUserId,
    String text, {
    String? senderName,
    String? replyToMessageId,
    Map<String, dynamic>? replyToData,
  }) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final now = serverTimestamp;
    String? name = senderName;
    if (name == null || name.isEmpty) {
      final me = await getCurrentUser();
      name = me?.name ?? '';
    }

    await chatRef.set({
      'participants': [uid, otherUserId],
      'members': [uid, otherUserId],
      'roomType': 'Private',
      'lastMessage': text,
      'lastMessageType': 'text',
      'lastMessageAt': now,
      'lastSenderId': uid,
      'lastSenderName': name,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final messageData = {
      'senderId': uid,
      'senderName': name,
      'text': text,
      'type': 'text',
      'messageType': 'text',
      'readStatus': false,
      'deliveredStatus': true,
      'unreadMembers': [otherUserId],
      'timeSent': now,
      'createdAt': now,
      'reactions': <String, dynamic>{}, // {userId: emoji}
      'isEdited': false,
    };

    if (replyToMessageId != null && replyToData != null) {
      messageData['replyTo'] = {
        'messageId': replyToMessageId,
        'senderId': replyToData['senderId'] ?? '',
        'senderName': replyToData['senderName'] ?? '',
        'text': replyToData['text'] ?? '',
        'type': replyToData['type'] ?? 'text',
      };
    }

    await chatRef.collection('messages').add(messageData);
  }

  /// Add reaction to a message (like Messenger)
  Future<void> addReaction(
    String otherUserId,
    String messageId,
    String emoji,
  ) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$uid': emoji,
    });
  }

  /// Remove reaction from a message
  Future<void> removeReaction(
    String otherUserId,
    String messageId,
  ) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$uid': FieldValue.delete(),
    });
  }

  /// Edit a message
  Future<void> editMessage(
    String otherUserId,
    String messageId,
    String newText,
  ) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText,
      'isEdited': true,
      'editedAt': serverTimestamp,
    });

    // Update last message if this was the last one
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data();
    if (chatData != null) {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (messages.docs.isNotEmpty) {
        final lastMsg = messages.docs.first;
        if (lastMsg.id == messageId) {
          await _firestore.collection('chats').doc(chatId).update({
            'lastMessage': newText,
          });
        }
      }
    }
  }

  /// Delete a message (for everyone or just for me)
  Future<void> deleteMessage(
    String otherUserId,
    String messageId, {
    bool forEveryone = false,
  }) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    if (forEveryone) {
      await msgRef.delete();
    } else {
      // Soft delete - mark as deleted for this user
      await msgRef.update({
        'deletedFor.$uid': true,
      });
    }
  }

  /// Forward a message to another user
  Future<void> forwardMessage(
    String fromUserId,
    String toUserId,
    Map<String, dynamic> messageData,
  ) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    
    final me = await getCurrentUser();
    final name = me?.name ?? '';

    // Create new message in target chat
    final chatId = chatIdFor(uid, toUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final now = serverTimestamp;

    await chatRef.set({
      'participants': [uid, toUserId],
      'members': [uid, toUserId],
      'roomType': 'Private',
      'lastMessage': messageData['text'] ?? 'Forwarded message',
      'lastMessageType': messageData['type'] ?? 'text',
      'lastMessageAt': now,
      'lastSenderId': uid,
      'lastSenderName': name,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': uid,
      'senderName': name,
      'text': messageData['text'] ?? '',
      'type': messageData['type'] ?? 'text',
      'messageType': messageData['type'] ?? 'text',
      'mediaUrl': messageData['mediaUrl'],
      'fileName': messageData['fileName'],
      'isForwarded': true,
      'originalSenderId': messageData['senderId'],
      'originalSenderName': messageData['senderName'],
      'readStatus': false,
      'deliveredStatus': true,
      'unreadMembers': [toUserId],
      'timeSent': now,
      'createdAt': now,
      'reactions': <String, dynamic>{},
    });
  }

  /// Set typing status
  Future<void> setTyping(String otherUserId, bool isTyping) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    
    await _firestore.collection('chats').doc(chatId).update({
      'typing.$uid': isTyping,
      'typingTimestamp.$uid': serverTimestamp,
    });
  }

  /// Listen to typing status
  Stream<bool> typingStatusStream(String otherUserId) {
    final uid = currentUserId;
    if (uid.isEmpty) return const Stream.empty();
    final chatId = chatIdFor(uid, otherUserId);
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return false;
      final typing = data['typing'] as Map<String, dynamic>?;
      return typing?[otherUserId] == true;
    });
  }

  /// Pin a message
  Future<void> pinMessage(String otherUserId, String messageId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    
    await _firestore.collection('chats').doc(chatId).update({
      'pinnedMessageId': messageId,
      'pinnedAt': serverTimestamp,
      'pinnedBy': uid,
    });
  }

  /// Unpin message
  Future<void> unpinMessage(String otherUserId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;
    final chatId = chatIdFor(uid, otherUserId);
    
    await _firestore.collection('chats').doc(chatId).update({
      'pinnedMessageId': FieldValue.delete(),
      'pinnedAt': FieldValue.delete(),
      'pinnedBy': FieldValue.delete(),
    });
  }

  /// Get pinned message
  Future<DocumentSnapshot?> getPinnedMessage(String otherUserId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return null;
    final chatId = chatIdFor(uid, otherUserId);
    
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final pinnedId = chatDoc.data()?['pinnedMessageId'];
    
    if (pinnedId == null) return null;
    
    return await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(pinnedId)
        .get();
  }

  /// Search messages in a chat
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> searchMessages(
    String otherUserId,
    String query,
  ) async {
    final uid = currentUserId;
    if (uid.isEmpty) return [];
    final chatId = chatIdFor(uid, otherUserId);
    
    // Note: This is a simple client-side search
    // For better performance, consider using Algolia or similar
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();
    
    final queryLower = query.toLowerCase();
    return messages.docs.where((doc) {
      final text = (doc.data()['text'] ?? '').toString().toLowerCase();
      return text.contains(queryLower);
    }).toList();
  }

  /// Send a group message and update group metadata with timestamp
  Future<void> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
    String? type = 'text',
  }) async {
    if (groupId.isEmpty || senderId.isEmpty) return;
    
    final now = serverTimestamp;
    final groupRef = _firestore.collection('group_chats').doc(groupId);
    
    // Add message to group messages subcollection
    await groupRef.collection('messages').add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type ?? 'text',
      'messageType': type ?? 'text',
      'createdAt': now,
      'timeSent': now,
      'readStatus': false,
    });
    
    // Update group metadata with last message and timestamp
    await groupRef.set({
      'lastMessage': text,
      'lastMessageType': type ?? 'text',
      'lastMessageAt': now,
      'lastSenderId': senderId,
      'lastSenderName': senderName,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  /// Create a new group chat
  Future<String> createGroupChat({
    required String groupName,
    required List<String> memberIds,
  }) async {
    try {
      if (groupName.trim().isEmpty || memberIds.isEmpty) {
        throw Exception('Group name and members are required');
      }

      // Ensure current user is included
      final currentUserId = this.currentUserId;
      final allMembers = {...memberIds, currentUserId}.toList();

      if (allMembers.length < 2) {
        throw Exception('A group must have at least 2 members');
      }

      // Create document with auto ID
      final docRef = _firestore.collection('group_chats').doc();
      final groupId = docRef.id;

      await docRef.set({
        'name': groupName.trim(),
        'members': allMembers,
        'createdBy': currentUserId,
        'createdAt': serverTimestamp,
        'lastMessage': '',
        'lastMessageAt': serverTimestamp,
        'lastSenderId': '',
        'lastSenderName': '',
        'description': '',
      });

      return groupId;
    } catch (e) {
      debugPrint('Error creating group: $e');
      rethrow;
    }
  }

  /// Add a member to a group
  Future<void> addGroupMember(String groupId, String userId) async {
    try {
      await _firestore.collection('group_chats').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error adding member: $e');
      rethrow;
    }
  }

  /// Remove a member from a group
  Future<void> removeGroupMember(String groupId, String userId) async {
    try {
      await _firestore.collection('group_chats').doc(groupId).update({
        'members': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('Error removing member: $e');
      rethrow;
    }
  }

  /// Get a single group
  Future<DocumentSnapshot<Map<String, dynamic>>> getGroupChat(String groupId) {
    return _firestore.collection('group_chats').doc(groupId).get();
  }

  /// Get all group chats
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllGroupChats() {
    return _firestore
        .collection('group_chats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  /// Get messages stream for a group
  Stream<QuerySnapshot<Map<String, dynamic>>> groupMessagesStream(
    String groupId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('group_chats')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Get all group chats for a user
  Stream<QuerySnapshot<Map<String, dynamic>>> userGroupChatsStream(String userId) {
    if (userId.isEmpty) {
      return const Stream.empty();
    }
    // Query without orderBy to avoid requiring composite index
    // Sorting will be done in the GroupsSection widget
    return _firestore
        .collection('group_chats')
        .where('members', arrayContains: userId)
        .snapshots();
  }

  /// Set user as online
  Future<void> setUserOnline() async {
    try {
      final userId = currentUserId;
      if (userId.isEmpty) return;
      
      await _firestore.collection('users').doc(userId).update({
        'isOnline': true,
      });
    } catch (e) {
      debugPrint('Error setting user online: $e');
    }
  }

  /// Set user as offline
  Future<void> setUserOffline() async {
    try {
      final userId = currentUserId;
      if (userId.isEmpty) return;
      
      await _firestore.collection('users').doc(userId).update({
        'isOnline': false,
      });
    } catch (e) {
      debugPrint('Error setting user offline: $e');
    }
  }

  /// Update user profile information
  Future<void> updateUserProfile({
    String? nickname,
    String? photoUrl,
  }) async {
    try {
      final userId = currentUserId;
      if (userId.isEmpty) return;
      
      final updates = <String, dynamic>{};
      if (nickname != null) updates['nickname'] = nickname;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
        _currentUserCache = null; // Clear cache to force reload
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }
}

