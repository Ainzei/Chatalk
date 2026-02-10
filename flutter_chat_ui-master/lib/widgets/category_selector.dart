import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CategorySelector(
      {Key? key, required this.selectedIndex, required this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Widget is not currently used - categories list is empty
    // To enable: populate categories list and uncomment rendering logic
    return const SizedBox.shrink();
  }
}
