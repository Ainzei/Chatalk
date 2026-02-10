import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:io';

/// Script to populate users and generate conversations
/// Run this from your app after signing in as an admin
class PopulateUsersAndChats {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  static final List<Map<String, String>> users = [
    {'email': 'sandovalchristianace3206@gmail.com', 'name': 'Christian Ace Sandoval', 'photo': ''},
    {'email': 'james.berto@gmail.com', 'name': 'James Berto', 'photo': 'ProfilePictures/JamesBerto.jpg'},
    {'email': 'franz.salazar@gmail.com', 'name': 'Franz Salazar', 'photo': 'ProfilePictures/FranzSalazar.jpg'},
    {'email': 'jerome.ruiz@gmail.com', 'name': 'Jerome Ruiz', 'photo': ''},
    {'email': 'michael.aquino@gmail.com', 'name': 'Michael Aquino', 'photo': ''},
    {'email': 'jian.ceruelas@gmail.com', 'name': 'Jian Ceruelas', 'photo': 'ProfilePictures/JianCeruelas.jpg'},
    {'email': 'paolo.martinez@gmail.com', 'name': 'Paolo Martinez', 'photo': 'ProfilePictures/PaoloMartinez.jpg'},
    {'email': 'enrico.reprima@gmail.com', 'name': 'Enrico Reprima', 'photo': 'ProfilePictures/EnricoReprima.jpg'},
    {'email': 'nicole.aldea@gmail.com', 'name': 'Nicole Aldea', 'photo': 'ProfilePictures/NicoleAldea.jpg'},
    {'email': 'allyxis.cortez@gmail.com', 'name': 'Allyxis Cortez', 'photo': ''},
    {'email': 'trisha.dudas@gmail.com', 'name': 'Trisha Dudas', 'photo': 'ProfilePictures/TrishaDudas.jpg'},
  ];

  // Friend groups (closer relationships, more casual conversations)
  static final Map<String, List<int>> relationshipTypes = {
    'close_friends': [0, 1, 2, 3], // Christian, James, Franz, Jerome
    'gaming_crew': [4, 5, 6], // Michael, Jian, Paolo
    'girls_squad': [8, 9, 10], // Allyxis, Trisha, Nicole
    'basketball': [0, 4, 5], // Christian, Michael, Jian
    'study_group': [1, 6, 3], // James, Paolo, Jerome
  };

  // Check if two people are close friends
  static bool _areCloseFriends(int idx1, int idx2) {
    for (var group in relationshipTypes.values) {
      if (group.contains(idx1) && group.contains(idx2)) {
        return true;
      }
    }
    return false;
  }

  static Future<void> addUsersToFirestore() async {
    debugPrint('📝 Adding users to Firestore...\n');
    
    // Get the base path for profile pictures
    final baseDir = Directory.current.path;
    
    for (var i = 0; i < users.length; i++) {
      final user = users[i];
      // Generate a fake UID (in real scenario, these would be created via Auth)
      final uid = 'user_${i}_${user['email']!.split('@')[0]}';
      
      // Construct full path for photo if it exists
      String? photoUrl;
      if (user['photo']!.isNotEmpty) {
        photoUrl = '$baseDir\\${user['photo']}';
        // Check if file exists
        final photoFile = File(photoUrl);
        if (!photoFile.existsSync()) {
          debugPrint("   ⚠️  Photo not found: ${user['photo']}");
          photoUrl = null;
        }
      }
      
      await _firestore.collection('users').doc(uid).set({
        'name': user['name'],
        'email': user['email'],
        'nickname': user['name']!.toLowerCase().split(' ')[0],
        'bio': _getRandomBio(user['name']!),
        'createdAt': FieldValue.serverTimestamp(),
        'online': _random.nextBool(),
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
      
      final photoStatus = photoUrl != null ? '📷' : '👤';
      debugPrint('✓ $photoStatus Added: ${user["name"]} (${user["email"]})');
    }
    
    debugPrint('\n✅ All users added!\n');
  }

  static Future<void> generateConversations() async {
    debugPrint('💬 Generating one-on-one conversations for everyone...\n');
    
    final userDocs = await _firestore.collection('users').get();
    final userIds = userDocs.docs.map((doc) => doc.id).toList();
    
    if (userIds.length < 2) {
      debugPrint('❌ Not enough users in database to create conversations');
      return;
    }

    int conversationCount = 0;
    int friendCount = 0;
    int classmateCount = 0;

    // Generate conversations between every pair of users
    for (int i = 0; i < users.length; i++) {
      for (int j = i + 1; j < users.length; j++) {
        if (i < userIds.length && j < userIds.length) {
          final areCloseFriends = _areCloseFriends(i, j);
          
          if (areCloseFriends) {
            await _createFriendConversation(
              userIds[i], 
              userIds[j], 
              users[i]['name']!, 
              users[j]['name']!
            );
            friendCount++;
          } else {
            await _createClassmateConversation(
              userIds[i], 
              userIds[j], 
              users[i]['name']!, 
              users[j]['name']!
            );
            classmateCount++;
          }
          conversationCount++;
        }
      }
    }

    debugPrint('\n✅ Generated $conversationCount total conversations!');
    debugPrint('   • $friendCount friend chats (casual)');
    debugPrint('   • $classmateCount classmate chats (formal)\n');
  }

  static Future<void> _createFriendConversation(
    String userId1, 
    String userId2, 
    String name1, 
    String name2
  ) async {
    final chatId = _getChatId(userId1, userId2);
    final messages = _getFriendMessages(name1, name2);
    
    // Create chat document
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [userId1, userId2],
      'lastMessage': messages.last['text'],
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add messages
    final batch = _firestore.batch();
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
      batch.set(msgRef, {
        'senderId': msg['sender'] == name1 ? userId1 : userId2,
        'text': msg['text'],
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(Duration(hours: messages.length - i, minutes: _random.nextInt(60)))
        ),
        'read': _random.nextBool(),
      });
    }
    await batch.commit();
    
    debugPrint('✓ Friend chat: $name1 ↔ $name2 (${messages.length} messages)');
  }

  static Future<void> _createClassmateConversation(
    String userId1, 
    String userId2, 
    String name1, 
    String name2
  ) async {
    final chatId = _getChatId(userId1, userId2);
    final messages = _getClassmateMessages(name1, name2);
    
    // Create chat document
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [userId1, userId2],
      'lastMessage': messages.last['text'],
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add messages
    final batch = _firestore.batch();
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
      batch.set(msgRef, {
        'senderId': msg['sender'] == name1 ? userId1 : userId2,
        'text': msg['text'],
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: _random.nextInt(3), hours: _random.nextInt(24)))
        ),
        'read': true,
      });
    }
    await batch.commit();
    
    debugPrint('✓ Classmate chat: $name1 ↔ $name2 (${messages.length} messages)');
  }

  static String _getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  static String _getRandomBio(String name) {
    final bios = [
      'Student | Coffee lover ☕',
      'CS Student 💻 | Gamer 🎮',
      'Just vibing ✨',
      'Living my best life 🌟',
      'Basketball enthusiast 🏀',
      'Music lover 🎵',
      'Foodie 🍕 | Traveler ✈️',
      'Dreamer 🌙',
      'Aspiring engineer 🔧',
      'Book worm 📚',
      'Fitness enthusiast 💪',
      'Photography 📸',
    ];
    return bios[_random.nextInt(bios.length)];
  }

  static List<Map<String, String>> _getFriendMessages(String name1, String name2) {
    final conversations = [
      [
        {'sender': name1, 'text': 'Yooo what\'s up bro?'},
        {'sender': name2, 'text': 'nm dude, just chilling. you?'},
        {'sender': name1, 'text': 'same haha. wanna play later?'},
        {'sender': name2, 'text': 'bet! what time?'},
        {'sender': name1, 'text': 'maybe around 7pm?'},
        {'sender': name2, 'text': 'cool see you then! 🎮'},
      ],
      [
        {'sender': name1, 'text': 'broooo did you see that game last night??'},
        {'sender': name2, 'text': 'YESSS insane right?!'},
        {'sender': name1, 'text': 'that last minute shot was CRAZY'},
        {'sender': name2, 'text': 'i was screaming the whole time lmao'},
        {'sender': name1, 'text': 'same hahahaha my neighbors probably hate me'},
      ],
      [
        {'sender': name2, 'text': 'hey you free this weekend?'},
        {'sender': name1, 'text': 'yeah why?'},
        {'sender': name2, 'text': 'wanna hang out? maybe mall or smth'},
        {'sender': name1, 'text': 'sounds good! let\'s go saturday'},
        {'sender': name2, 'text': 'perfect! i\'ll msg the others too'},
      ],
      [
        {'sender': name1, 'text': 'dude i\'m so tired 😭'},
        {'sender': name2, 'text': 'same bro, this week is rough'},
        {'sender': name1, 'text': 'need coffee asap'},
        {'sender': name2, 'text': 'let\'s grab some after class?'},
        {'sender': name1, 'text': 'yesss pls ☕'},
      ],
      [
        {'sender': name2, 'text': 'lol check this meme'},
        {'sender': name1, 'text': 'HAHAHAHA omg that\'s hilarious'},
        {'sender': name2, 'text': 'literally us yesterday 😂'},
        {'sender': name1, 'text': 'facts lmaooo'},
        {'sender': name2, 'text': 'sending this to the gc'},
      ],
      [
        {'sender': name1, 'text': 'yo you down for basketball later?'},
        {'sender': name2, 'text': 'yeah man! what time?'},
        {'sender': name1, 'text': '5pm at the usual spot'},
        {'sender': name2, 'text': 'bet, see you there 🏀'},
      ],
      [
        {'sender': name2, 'text': 'omg this lecture is so boring'},
        {'sender': name1, 'text': 'RIGHT?? i can barely stay awake'},
        {'sender': name2, 'text': 'let\'s get food after this'},
        {'sender': name1, 'text': 'yesss where to?'},
        {'sender': name2, 'text': 'idk maybe that new place near campus'},
      ],
      [
        {'sender': name1, 'text': 'bro did you finish the assignment?'},
        {'sender': name2, 'text': 'nah not yet, you?'},
        {'sender': name1, 'text': 'same lol procrastinating hard'},
        {'sender': name2, 'text': 'wanna work on it together?'},
        {'sender': name1, 'text': 'sure! your place or mine?'},
      ],
      [
        {'sender': name2, 'text': 'thanks for covering for me earlier'},
        {'sender': name1, 'text': 'no worries dude! you\'d do the same'},
        {'sender': name2, 'text': 'appreciate you bro'},
        {'sender': name1, 'text': 'always got your back 💪'},
      ],
      [
        {'sender': name1, 'text': 'DUDE guess what happened??'},
        {'sender': name2, 'text': 'what what tell me'},
        {'sender': name1, 'text': 'okay so you know that project...'},
        {'sender': name2, 'text': 'yeah?'},
        {'sender': name1, 'text': 'we got an A!! 🎉'},
        {'sender': name2, 'text': 'NO WAY!! that\'s awesome!!'},
      ],
      [
        {'sender': name2, 'text': 'party at mike\'s this friday'},
        {'sender': name1, 'text': 'ohh nice! you going?'},
        {'sender': name2, 'text': 'yeah for sure! you should come'},
        {'sender': name1, 'text': 'bet i\'ll be there'},
      ],
      [
        {'sender': name1, 'text': 'yo can i borrow your charger?'},
        {'sender': name2, 'text': 'yeah sure, where are you?'},
        {'sender': name1, 'text': 'library 2nd floor'},
        {'sender': name2, 'text': 'coming!'},
      ],
    ];
    return conversations[_random.nextInt(conversations.length)];
  }

  static List<Map<String, String>> _getClassmateMessages(String name1, String name2) {
    final conversations = [
      [
        {'sender': name1, 'text': 'Hi! Do you have the notes from yesterday?'},
        {'sender': name2, 'text': 'Yes, I can send them to you'},
        {'sender': name1, 'text': 'Thank you so much!'},
        {'sender': name2, 'text': 'No problem! Here you go'},
      ],
      [
        {'sender': name2, 'text': 'Hey, what time is our presentation tomorrow?'},
        {'sender': name1, 'text': 'It\'s at 10:30 AM'},
        {'sender': name2, 'text': 'Thanks! Are you ready?'},
        {'sender': name1, 'text': 'Almost done with my part. You?'},
        {'sender': name2, 'text': 'Same here. Good luck!'},
      ],
      [
        {'sender': name1, 'text': 'Do we have homework for tomorrow?'},
        {'sender': name2, 'text': 'Yes, pages 45-50 in the workbook'},
        {'sender': name1, 'text': 'Got it, thanks!'},
      ],
      [
        {'sender': name2, 'text': 'Are you joining the study group later?'},
        {'sender': name1, 'text': 'What time?'},
        {'sender': name2, 'text': '4 PM at the library'},
        {'sender': name1, 'text': 'I\'ll try to make it. Thanks for letting me know'},
      ],
      [
        {'sender': name1, 'text': 'Hi! Quick question about problem #5'},
        {'sender': name2, 'text': 'Sure, what\'s up?'},
        {'sender': name1, 'text': 'Did you get 42 as the answer?'},
        {'sender': name2, 'text': 'Yes! That\'s what I got too'},
        {'sender': name1, 'text': 'Perfect, thank you!'},
      ],
      [
        {'sender': name2, 'text': 'Did the prof mention anything about the exam?'},
        {'sender': name1, 'text': 'Yes, it will cover chapters 3-5'},
        {'sender': name2, 'text': 'Okay thanks. Multiple choice or essay?'},
        {'sender': name1, 'text': 'Mix of both apparently'},
      ],
      [
        {'sender': name1, 'text': 'Hey, do you know if class is cancelled tomorrow?'},
        {'sender': name2, 'text': 'I heard it might be, but not confirmed yet'},
        {'sender': name1, 'text': 'Alright, I\'ll check the announcement board'},
        {'sender': name2, 'text': 'Let me know if you find out!'},
      ],
      [
        {'sender': name2, 'text': 'Do you understand the assignment?'},
        {'sender': name1, 'text': 'Not really... it\'s confusing'},
        {'sender': name2, 'text': 'Same. Want to ask the professor together?'},
        {'sender': name1, 'text': 'Good idea. After class?'},
      ],
      [
        {'sender': name1, 'text': 'What did you get for number 3?'},
        {'sender': name2, 'text': 'I got 127'},
        {'sender': name1, 'text': 'Hmm I got something different'},
        {'sender': name2, 'text': 'Let me check my work again'},
      ],
      [
        {'sender': name2, 'text': 'Can you send me the assignment guidelines?'},
        {'sender': name1, 'text': 'Sure, give me a sec'},
        {'sender': name1, 'text': 'Just sent it'},
        {'sender': name2, 'text': 'Got it, thanks!'},
      ],
      [
        {'sender': name1, 'text': 'Are you done with part 2 of the project?'},
        {'sender': name2, 'text': 'Almost. Should be done by tonight'},
        {'sender': name1, 'text': 'Great, I\'m working on part 3'},
        {'sender': name2, 'text': 'Perfect. We\'re on track then'},
      ],
      [
        {'sender': name2, 'text': 'Did you submit the assignment?'},
        {'sender': name1, 'text': 'Yes, just submitted it'},
        {'sender': name2, 'text': 'Okay good, I\'m about to submit mine'},
      ],
      [
        {'sender': name1, 'text': 'What room is our next class in?'},
        {'sender': name2, 'text': 'Room 305 I think'},
        {'sender': name1, 'text': 'Thanks!'},
      ],
      [
        {'sender': name2, 'text': 'Did you hear about the field trip?'},
        {'sender': name1, 'text': 'No, when is it?'},
        {'sender': name2, 'text': 'Next Friday. We need to sign up by Wednesday'},
        {'sender': name1, 'text': 'Oh okay, I\'ll sign up tomorrow. Thanks!'},
      ],
      [
        {'sender': name1, 'text': 'Can I borrow your textbook after class?'},
        {'sender': name2, 'text': 'Sure! I\'m done with it for today'},
        {'sender': name1, 'text': 'Thanks, I left mine at home'},
      ],
    ];
    return conversations[_random.nextInt(conversations.length)];
  }

  static Future<void> run() async {
    // Skip on web - this script uses File I/O and other features not available on web
    if (kIsWeb) {
      debugPrint('⚠️ Database population skipped on web platform');
      return;
    }
    
    debugPrint('\n🚀 Starting database population...\n');
    await addUsersToFirestore();
    await generateConversations();
    debugPrint('🎉 Complete! Your database is now populated with users and conversations.\n');
  }
}
