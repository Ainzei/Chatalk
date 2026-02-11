// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_ui/models/app_user.dart';
import 'package:flutter_chat_ui/screens/group_chat_screen.dart';
import 'package:flutter_chat_ui/services/chat_service.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';

// Show create group dialog with real Firestore users
Future<Map<String, dynamic>?> showCreateGroupDialog(BuildContext context) async {
  final chatService = ChatService();

  return await showDialog<Map<String, dynamic>?>(
    context: context,
    builder: (context) {
      // Use a StatefulBuilder to maintain state across rebuilds
      String groupName = '';
      final selectedMemberIds = <String>{};

      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('Create Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    hintText: 'Enter group name',
                  ),
                  onChanged: (v) => groupName = v,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select members (at least 1):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<AppUser>>(
                  stream: chatService.usersStream(),
                  builder: (context, snapshot) {
                    final allUsers = snapshot.data ?? [];
                    final currentUserId = chatService.currentUserId;
                    
                    // Filter out current user
                    final otherUsers = allUsers
                        .where((u) => u.id != currentUserId)
                        .toList();

                    if (otherUsers.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No other users available'),
                      );
                    }

                    return SizedBox(
                      height: 300,
                      width: double.maxFinite,
                      child: ListView.builder(
                        itemCount: otherUsers.length,
                        itemBuilder: (context, index) {
                          final user = otherUsers[index];
                          final isSelected = selectedMemberIds.contains(user.id);
                          
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  selectedMemberIds.add(user.id);
                                } else {
                                  selectedMemberIds.remove(user.id);
                                }
                              });
                            },
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            secondary: CircleAvatar(
                              backgroundImage: ProfilePhotoHelper.getProfileImage(
                                user.id,
                                userName: user.name,
                                photoUrl: user.photoUrl,
                              ),
                              child: !ProfilePhotoHelper.hasProfilePhoto(
                                user.id,
                                userName: user.name,
                                photoUrl: user.photoUrl,
                              )
                                  ? Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?',
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (groupName.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a group name')),
                  );
                  return;
                }
                if (selectedMemberIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least 1 member'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'name': groupName.trim(),
                  'memberIds': selectedMemberIds.toList(),
                });
              },
              child: const Text('Create'),
            ),
          ],
        );
      });
    },
  );
}

class GroupsSection extends StatefulWidget {
  const GroupsSection({Key? key}) : super(key: key);

  @override
  GroupsSectionState createState() => GroupsSectionState();
}

class GroupsSectionState extends State<GroupsSection> {
  final ChatService _chatService = ChatService();
  bool _isCreating = false;

  void _createGroup() async {
    final result = await showCreateGroupDialog(context);
    if (result != null) {
      setState(() => _isCreating = true);
      try {
        final groupId = await _chatService.createGroupChat(
          groupName: result['name'],
          memberIds: List<String>.from(result['memberIds']),
        );
        
        if (mounted) {
          // Wait a brief moment for Firestore to sync
          await Future.delayed(const Duration(milliseconds: 500));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Group "${result['name']}" created successfully!'),
              duration: const Duration(seconds: 2),
            ),
          );
          
          setState(() => _isCreating = false);
          
          // Navigate to the new group
          if (mounted) {
            final members = List<String>.from(result['memberIds'])
              ..add(_chatService.currentUserId);
            
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                  groupId: groupId,
                  groupName: result['name'],
                  memberIds: members,
                ),
              ),
            );
            
            // Refresh the groups list after returning from group chat
            if (mounted) {
              setState(() {});
            }
          }
        }
      } catch (e) {
        if (mounted) {
          debugPrint('Error creating group: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating group: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
          setState(() => _isCreating = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _chatService.userGroupChatsStream(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              debugPrint('Groups Stream Error: ${snapshot.error}');
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Error loading groups'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isCreating ? null : _createGroup,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Create Group'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final groups = snapshot.data?.docs ?? [];
            
            // Sort groups by lastMessageAt (most recent first)
            groups.sort((a, b) {
              final aTime = a.data()['lastMessageAt'] as Timestamp?;
              final bTime = b.data()['lastMessageAt'] as Timestamp?;
              
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              
              return bTime.compareTo(aTime); // descending order
            });
            
            debugPrint('Groups found: ${groups.length}');
            for (var group in groups) {
              debugPrint('Group: ${group.data()['name']}');
            }

            if (groups.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.group,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No groups yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a group to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isCreating ? null : _createGroup,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Create Group'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final groupDoc = groups[index];
                final groupData = groupDoc.data();
                final groupId = groupDoc.id;
                final groupName = groupData['name'] ?? 'Unnamed Group';
                final members = List<String>.from(groupData['members'] ?? []);
                final lastMessage = groupData['lastMessage'] ?? '';
                final lastSenderName = groupData['lastSenderName'] ?? '';

                return _buildGroupItem(
                  context: context,
                  groupId: groupId,
                  groupName: groupName,
                  members: members,
                  lastMessage: lastMessage,
                  lastSenderName: lastSenderName,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGroupItem({
    required BuildContext context,
    required String groupId,
    required String groupName,
    required List<String> members,
    required String lastMessage,
    required String lastSenderName,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              groupId: groupId,
              groupName: groupName,
              memberIds: members,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            // Group avatar with initials
            CircleAvatar(
              radius: 30.0,
              backgroundColor: Colors.blueGrey[100],
              child: Text(
                groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            // Group name, member count, and last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Text(
                        '${members.length} members',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12.0,
                        ),
                      ),
                      if (lastMessage.isNotEmpty) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(color: Colors.grey, fontSize: 12.0),
                        ),
                        Expanded(
                          child: Text(
                            '${lastSenderName.isNotEmpty ? '$lastSenderName: ' : ''}$lastMessage',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            // Create group button (visible if no members display)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
