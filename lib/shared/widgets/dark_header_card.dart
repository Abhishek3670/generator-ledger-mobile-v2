import 'package:flutter/material.dart';
import 'directory_card.dart';

/// A standard card layout featuring a solid dark navy header bar and white title text.
///
/// Under the hood, this extends/uses the configuration settings of [DirectoryCard].
class DarkHeaderCard extends StatelessWidget {
  /// The title text displayed in the dark header bar.
  final String title;

  /// Optional action widget displayed on the right of the header bar.
  final Widget? action;

  /// The body contents of the card.
  final Widget child;

  /// Creates a [DarkHeaderCard].
  const DarkHeaderCard({
    super.key,
    required this.title,
    this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DirectoryCard(
      headerTitle: title,
      headerAction: action,
      hasDarkHeader: true,
      child: child,
    );
  }
}
