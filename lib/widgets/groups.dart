import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/models/user_model.dart';
import 'package:flutter_chat_ui/models/group_model.dart';
import 'package:flutter_chat_ui/screens/group_chat_screen.dart';
import 'package:flutter_chat_ui/utils/image_loader.dart';
import 'package:flutter_chat_ui/data/facebook_export_groups.dart';

// Global groups list so groups persist across screens
final List<Group> globalGroups = facebookExportGroups;

// Reusable dialog that returns the created Group (or null if cancelled)
Future<Group?> showCreateGroupDialog(BuildContext context) async {
  String groupName = '';
  List<User> selected = [];

  final Group? result = await showDialog<Group?>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('Create Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: const InputDecoration(labelText: 'Group name'),
                  onChanged: (v) => groupName = v,
                ),
                const SizedBox(height: 12),
                const Text('Select members:'),
                const SizedBox(height: 8),
                ...facebookExportUsers.map((user) {
                  final alreadySelected = selected.contains(user);
                  return CheckboxListTile(
                    value: alreadySelected,
                    onChanged: (val) {
                      setStateDialog(() {
                        if (val == true) {
                          selected.add(user);
                        } else {
                          selected.remove(user);
                        }
                      });
                    },
                    title: Text(user.name),
                    secondary: CircleAvatar(
                        backgroundImage: getImageProvider(user.imageUrl)),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (groupName.trim().isEmpty || selected.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter a name and select members')));
                  return;
                }
                final newGroup = Group(
                    name: groupName.trim(),
                    members: List.from(selected),
                    messages: []);
                Navigator.pop(context, newGroup);
              },
              child: const Text('Create'),
            ),
          ],
        );
      });
    },
  );

  return result;
}

class GroupsSection extends StatefulWidget {
  const GroupsSection({Key? key}) : super(key: key);

  @override
  GroupsSectionState createState() => GroupsSectionState();
}

class GroupsSectionState extends State<GroupsSection> {
  final List<Group> _groups = globalGroups;

  void _createGroup() async {
    final Group? newGroup = await showCreateGroupDialog(context);
    if (newGroup != null) {
      setState(() => _groups.insert(0, newGroup));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: _groups.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('No groups yet',
                      style: TextStyle(
                          fontSize: 20.0, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Create a group to get started'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _createGroup,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Create Group'),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _createGroup,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Create Group'),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(_groups.length, (index) {
                  final g = _groups[index];
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                        leading: SizedBox(
                          width: 70,
                          height: 40,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: List.generate(
                              g.members.length > 3 ? 3 : g.members.length,
                              (i) {
                                final user = g.members[i];
                                return Positioned(
                                  left: i * 18.0,
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundImage: getImageProvider(user.imageUrl),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        title: Text(g.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(g.messages.isNotEmpty
                            ? g.messages.last.text
                            : '${g.members.length} members'),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => GroupChatScreen(group: g)));
                        },
                      ),
                      if (index != _groups.length - 1) const Divider(height: 1),
                    ],
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
    );
  }
}
