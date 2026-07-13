/// Centralized Spacing scale and layout patterns.
abstract final class AppSpacing {
  /// Extra small spacing (4.0) - tight spacing within components (e.g. icon to text)
  static const xs = 4.0;

  /// Small spacing (8.0) - related elements (e.g. list item vertical padding)
  static const sm = 8.0;

  /// Medium spacing (16.0) - section padding, card internal spacing, screen edges
  static const md = 16.0;

  /// Large spacing (24.0) - between sections (e.g. after headers)
  static const lg = 24.0;

  /// Extra large spacing (32.0) - major sections (e.g. between top cards and content)
  static const xl = 32.0;

  /// Double extra large spacing (48.0) - hero spacing
  static const xxl = 48.0;

  // --- Common Layout Patterns ---
  
  /// Standard padding inside cards (16.0)
  static const cardPadding = md;

  /// Vertical padding for list items (8.0)
  static const listItemVertical = sm;

  /// Horizontal padding for list items (16.0)
  static const listItemHorizontal = md;

  /// Gap between sections (24.0)
  static const sectionGap = lg;

  /// Mobile edge gutter padding (16.0)
  static const screenEdge = md;

  /// Gap between cards (16.0)
  static const cardGap = md;
}
