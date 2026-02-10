import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfilePhotoHelper {
  // Base path for profile pictures - relative to project root
  static const String profilePicturesPath = 'ProfilePictures';
  static const String defaultAsset = 'assets/images/profile.jpg';
  
  // User ID to profile picture name mapping
  static const Map<String, String> userIdPhotoMap = {
    'james123': 'JamesBerto',
  };
  
  // Available profile picture names (must match filenames in ProfilePictures/)
  static const List<String> availableProfiles = [
    'EnricoReprima',
    'FranzSalazar',
    'JamesBerto',
    'JianCeruelas',
    'NicoleAldea',
    'PaoloMartinez',
    'TrishaDudas',
  ];

  // Enhanced name mapping to handle various name formats
  static const Map<String, String> nameVariationMap = {
    'Nicole Aldea': 'NicoleAldea',
    'nicolealdea': 'NicoleAldea',
    'nicole aldea': 'NicoleAldea',
    'nicole.aldea': 'NicoleAldea',
    'Enrico Reprima': 'EnricoReprima',
    'enricoreprima': 'EnricoReprima',
    'enrico reprima': 'EnricoReprima',
    'enrico.reprima': 'EnricoReprima',
    'Franz Salazar': 'FranzSalazar',
    'franzsalazar': 'FranzSalazar',
    'franz salazar': 'FranzSalazar',
    'franz.salazar': 'FranzSalazar',
    'James Berto': 'JamesBerto',
    'jamesberto': 'JamesBerto',
    'james berto': 'JamesBerto',
    'james.berto': 'JamesBerto',
    'Jian Ceruelas': 'JianCeruelas',
    'jianceruelas': 'JianCeruelas',
    'jian ceruelas': 'JianCeruelas',
    'jian.ceruelas': 'JianCeruelas',
    'Paolo Martinez': 'PaoloMartinez',
    'paolomartinez': 'PaoloMartinez',
    'paolo martinez': 'PaoloMartinez',
    'paolo.martinez': 'PaoloMartinez',
    'Trisha Dudas': 'TrishaDudas',
    'trishadudas': 'TrishaDudas',
    'trisha dudas': 'TrishaDudas',
    'trisha.dudas': 'TrishaDudas',
  };
  
  /// Try to match a username to an available profile picture
  static String? _findMatchingProfile(String? userName) {
    if (userName == null || userName.isEmpty) return null;
    
    final trimmedName = userName.trim();
    
    // 1. Check direct variation map first (fastest)
    if (nameVariationMap.containsKey(trimmedName)) {
      return nameVariationMap[trimmedName];
    }
    
    // 2. Check case-insensitive variation map
    final lowerName = trimmedName.toLowerCase();
    for (final entry in nameVariationMap.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }
    
    // 3. Handle email-style names (e.g., "franz.salazar" -> "Franz Salazar")
    if (trimmedName.contains('.')) {
      final withSpaces = trimmedName.replaceAll('.', ' ');
      final titleCase = withSpaces.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
      
      // Check if this title case version matches
      if (nameVariationMap.containsKey(titleCase)) {
        return nameVariationMap[titleCase];
      }
      
      // Check without spaces
      final withoutSpaces = titleCase.replaceAll(' ', '');
      for (final profile in availableProfiles) {
        if (withoutSpaces.toLowerCase() == profile.toLowerCase()) {
          return profile;
        }
      }
    }
    
    // 4. Try direct exact match with available profiles (case-insensitive)
    for (final profile in availableProfiles) {
      if (trimmedName.toLowerCase().replaceAll(' ', '') == profile.toLowerCase()) {
        return profile;
      }
    }
    
    // 5. Try matching first and last name with profile names
    final nameParts = trimmedName.split(RegExp(r'[\s.]+'));
    if (nameParts.length >= 2) {
      final firstName = nameParts[0];
      final lastName = nameParts.last;
      final combinedName = firstName + lastName;
      
      for (final profile in availableProfiles) {
        if (combinedName.toLowerCase() == profile.toLowerCase()) {
          return profile;
        }
      }
    }
    
    return null;
  }
  
  /// Get ImageProvider for a user's profile photo
  /// This works consistently across web and native platforms
  static ImageProvider getProfileImage(
    String userId, {
    String? userName,
    String? filePath,
    String? photoUrl,
  }) {
    // Priority 1: Try to match by username to profile pictures folder
    if (userName != null && userName.isNotEmpty) {
      final matchedProfile = _findMatchingProfile(userName);
      if (matchedProfile != null && availableProfiles.contains(matchedProfile)) {
        // Return asset image that works across all platforms
        return AssetImage('$profilePicturesPath/$matchedProfile.jpg');
      }
    }
    
    // Priority 2: Check if there's a custom mapping for this userId
    if (userIdPhotoMap.containsKey(userId)) {
      final mappedProfile = userIdPhotoMap[userId]!;
      if (availableProfiles.contains(mappedProfile)) {
        return AssetImage('$profilePicturesPath/$mappedProfile.jpg');
      }
    }
    
    // Priority 3: Use photoUrl from Firestore if provided (native only)
    if (photoUrl != null && photoUrl.isNotEmpty && !kIsWeb) {
      final file = File(photoUrl);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    
    // Priority 4: If a specific file path is provided (for group pictures)
    if (filePath != null && filePath.isNotEmpty && !kIsWeb) {
      final extensions = ['jpg', 'jpeg', 'png'];
      
      // Try with exact path first
      final file = File(filePath);
      if (file.existsSync()) {
        return FileImage(file);
      }
      
      // Try with common extensions if no extension provided
      if (!filePath.contains('.')) {
        for (final ext in extensions) {
          final fileWithExt = '$filePath.$ext';
          final fileObj = File(fileWithExt);
          if (fileObj.existsSync()) {
            return FileImage(fileObj);
          }
        }
      }
    }
    
    // Default fallback
    return const AssetImage(defaultAsset);
  }
  
  /// Check if a user has a local profile photo
  static bool hasLocalPhoto(
    String userId, {
    String? userName,
  }) {
    if (userId.isEmpty) return false;
    
    // Check if username matches available profiles
    if (userName != null && userName.isNotEmpty) {
      final matchedProfile = _findMatchingProfile(userName);
      if (matchedProfile != null && availableProfiles.contains(matchedProfile)) {
        return true;
      }
    }
    
    // Check if there's a custom mapping for this userId
    if (userIdPhotoMap.containsKey(userId)) {
      final mappedProfile = userIdPhotoMap[userId]!;
      if (availableProfiles.contains(mappedProfile)) {
        return true;
      }
    }
    
    // On native, check for file existence
    if (!kIsWeb) {
      final extensions = ['jpg', 'jpeg', 'png'];
      
      // Check with mapped ID if available
      String lookupId = userIdPhotoMap[userId] ?? userId;
      for (final ext in extensions) {
        final filePath = '$profilePicturesPath/$lookupId.$ext';
        if (File(filePath).existsSync()) {
          return true;
        }
      }
    }
    
    return false;
  }
}
