import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Helper function to load images from asset or file path
ImageProvider getImageProvider(String path) {
  if (path.trim().isEmpty) {
    return const AssetImage('assets/images/1.png');
  }

  // On web, local file paths are not supported.
  if (kIsWeb) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return AssetImage(path);
  }

  // On mobile/desktop, try file first if it looks like a local path.
  if (path.contains('facebook-') || File(path).existsSync()) {
    try {
      return FileImage(File(path));
    } catch (_) {
      return AssetImage(path);
    }
  }

  return AssetImage(path);
}
