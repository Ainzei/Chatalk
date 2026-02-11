import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/utils/profile_photo_helper.dart';

/// A composite profile avatar that displays multiple member photos in a grid layout
/// similar to Facebook Messenger group profile pictures (up to 4 small circles)
class CompositeProfileAvatar extends StatelessWidget {
  final List<String> memberNames;
  final double radius;
  final Color backgroundColor;

  const CompositeProfileAvatar({
    Key? key,
    required this.memberNames,
    this.radius = 30.0,
    this.backgroundColor = Colors.orange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (memberNames.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: const Icon(Icons.group, color: Colors.white),
      );
    }

    // Show up to 4 members
    final displayMembers = memberNames.take(4).toList();

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: displayMembers.length == 1
          ? _buildSingleAvatar(displayMembers[0])
          : displayMembers.length == 2
              ? _buildDualAvatar(displayMembers[0], displayMembers[1])
              : displayMembers.length == 3
                  ? _buildTripleAvatar(
                      displayMembers[0], displayMembers[1], displayMembers[2])
                  : _buildQuadAvatar(displayMembers[0], displayMembers[1],
                      displayMembers[2], displayMembers[3]),
    );
  }

  Widget _buildSingleAvatar(String name) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: ProfilePhotoHelper.getProfileImage(
        '',
        userName: name,
      ),
      child: _getInitial(name),
    );
  }

  Widget _buildDualAvatar(String name1, String name2) {
    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 0,
          left: 0,
          child: CircleAvatar(
            radius: radius * 0.6,
            backgroundColor: backgroundColor,
            backgroundImage: ProfilePhotoHelper.getProfileImage('', userName: name1),
            child: _getSmallInitial(name1),
          ),
        ),
        // Bottom-right
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: radius * 0.6,
            backgroundColor: backgroundColor,
            backgroundImage: ProfilePhotoHelper.getProfileImage('', userName: name2),
            child: _getSmallInitial(name2),
          ),
        ),
      ],
    );
  }

  Widget _buildTripleAvatar(String name1, String name2, String name3) {
    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 0,
          left: 0,
          child: CircleAvatar(
            radius: radius * 0.55,
            backgroundColor: backgroundColor,
            backgroundImage: ProfilePhotoHelper.getProfileImage('', userName: name1),
            child: _getSmallInitial(name1),
          ),
        ),
        // Top-right
        Positioned(
          top: 0,
          right: 0,
          child: CircleAvatar(
            radius: radius * 0.55,
            backgroundColor: backgroundColor,
            backgroundImage: ProfilePhotoHelper.getProfileImage('', userName: name2),
            child: _getSmallInitial(name2),
          ),
        ),
        // Bottom-center
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: CircleAvatar(
              radius: radius * 0.55,
              backgroundColor: backgroundColor,
              backgroundImage: ProfilePhotoHelper.getProfileImage('', userName: name3),
              child: _getSmallInitial(name3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuadAvatar(
      String name1, String name2, String name3, String name4) {
    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 0,
          left: 0,
          child: CircleAvatar(
            radius: radius * 0.5,
            backgroundColor: backgroundColor,
            backgroundImage: ProfilePhotoHelper.getProfileImage('', userName: name1),
            child: _getSmallInitial(name1),
          ),
        ),
        // Top-right
        Positioned(
          top: 0,
          right: 0,
          child: CircleAvatar(
            radius: radius * 0.5,
            backgroundColor: backgroundColor,
            backgroundImage: ProfilePhotoHelper.getProfileImage('', userName: name2),
            child: _getSmallInitial(name2),
          ),
        ),
        // Bottom-left
        Positioned(
          bottom: 0,
          left: 0,
          child: CircleAvatar(
            radius: radius * 0.5,
            backgroundColor: backgroundColor,
            backgroundImage: ProfilePhotoHelper.getProfileImage('', userName: name3),
            child: _getSmallInitial(name3),
          ),
        ),
        // Bottom-right
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: radius * 0.5,
            backgroundColor: backgroundColor,
            backgroundImage: ProfilePhotoHelper.getProfileImage('', userName: name4),
            child: _getSmallInitial(name4),
          ),
        ),
      ],
    );
  }

  Widget? _getInitial(String name) {
    if (name.isEmpty) return null;
    final photo = ProfilePhotoHelper.getProfileImage('', userName: name);
    if (photo is FileImage || photo is NetworkImage) {
      return null; // Image loaded successfully, no initial needed
    }
    return Text(
      name[0].toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget? _getSmallInitial(String name) {
    if (name.isEmpty) return null;
    final photo = ProfilePhotoHelper.getProfileImage('', userName: name);
    if (photo is FileImage || photo is NetworkImage) {
      return null; // Image loaded successfully, no initial needed
    }
    return Text(
      name[0].toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    );
  }
}
