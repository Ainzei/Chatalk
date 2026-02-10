import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/screens/group_chat_screen.dart';
import 'package:flutter_chat_ui/widgets/groups.dart';

class GroupsSection extends StatelessWidget {
  const GroupsSection({Key? key}) : super(key: key);

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'G' : trimmed[0].toUpperCase();
  }

  String _formatTime(BuildContext context, DateTime? time) {
    if (time == null) return '';
    return TimeOfDay.fromDateTime(time).format(context);
  }

  @override
  Widget build(BuildContext context) {
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
        child: globalGroups.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No groups yet',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: globalGroups.length,
                itemBuilder: (context, index) {
                  final group = globalGroups[index];
                  String lastMessageText = group.messages.isNotEmpty
                      ? group.messages.last.text
                      : 'No messages yet';

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(group: group),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        children: <Widget>[
                          _buildGroupAvatar(group),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  group.name,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  lastMessageText,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          _buildGroupStatus(context, group),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildGroupAvatar(dynamic group) {
    String initial = group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G';

    return Stack(
      children: [
        CircleAvatar(
          radius: 30.0,
          backgroundColor: Colors.orange.withValues(alpha: 0.2),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 18.0,
            height: 18.0,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
            ),
            child: const Icon(
              Icons.group,
              color: Colors.white,
              size: 10.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupStatus(BuildContext context, dynamic group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          _formatTime(context, group.lastMessageAt),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            '${group.members.length}',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
