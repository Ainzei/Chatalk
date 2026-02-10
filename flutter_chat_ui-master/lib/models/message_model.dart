import 'package:flutter_chat_ui/models/user_model.dart';

class Message {
  final User sender;
  final String
      time; // Would usually be type DateTime or Firebase Timestamp in production apps
  final String text;
  final bool isLiked;
  final bool unread;

  const Message({
    required this.sender,
    required this.time,
    required this.text,
    this.isLiked = false,
    this.unread = false,
  });
}

// YOU - current user
const User currentUser = User(
  id: 0,
  name: 'Current User',
  imageUrl: 'assets/images/greg.jpg',
);

// USERS (deprecated - use Firestore users instead)
const User greg = User(
  id: 1,
  name: 'Greg',
  imageUrl: 'assets/images/greg.jpg',
);
const User james = User(
  id: 2,
  name: 'James',
  imageUrl: 'assets/images/james.jpg',
);
const User john = User(
  id: 3,
  name: 'John',
  imageUrl: 'assets/images/john.jpg',
);
const User olivia = User(
  id: 4,
  name: 'Olivia',
  imageUrl: 'assets/images/olivia.jpg',
);
const User sam = User(
  id: 5,
  name: 'Sam',
  imageUrl: 'assets/images/sam.jpg',
);
const User sophia = User(
  id: 6,
  name: 'Sophia',
  imageUrl: 'assets/images/sophia.jpg',
);
const User steven = User(
  id: 7,
  name: 'Steven',
  imageUrl: 'assets/images/steven.jpg',
);

// DEPRECATED: Use Firestore instead
List<User> favorites = [];

// DEPRECATED: Use Firestore instead
List<Message> chats = [];

// DEPRECATED: Use Firestore instead
List<Message> messages = [];
