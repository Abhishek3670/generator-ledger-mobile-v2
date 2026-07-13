import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AutocompleteField<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) displayStringForOption;
  final List<String> Function(T) searchFields;
  final void Function(T?) onSelected;
  final String hintText;
  final String labelText;
  final T? initialValue;
  final String? errorText;

  const AutocompleteField({
    super.key,
    required this.items,
    required this.displayStringForOption,
    required this.searchFields,
    required this.onSelected,
    required this.hintText,
    required this.labelText,
    this.initialValue,
    this.errorText,
  });

  @override
  State<AutocompleteField<T>> createState() => _AutocompleteFieldState<T>();
}

class _AutocompleteFieldState<T> extends State<AutocompleteField<T>> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  List<T> _filteredItems = [];
  int _highlightedIndex = -1;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.displayStringForOption(widget.initialValue as T);
    }

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AutocompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      if (widget.initialValue != null) {
        _controller.text = widget.displayStringForOption(widget.initialValue as T);
      } else {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _updateSuggestions(_controller.text);
      _showOverlay();
    } else {
      // Delay hiding the overlay to allow tap events on suggestions to fire first
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus && mounted) {
          _hideOverlay();
          // If the user unfocused and didn't select an item, revert text to matching the current value if any, or clear
          if (widget.initialValue != null) {
            _controller.text = widget.displayStringForOption(widget.initialValue as T);
          } else if (_controller.text.isNotEmpty) {
            // Check if current text matches a selected item before clearing
            final hasMatch = widget.items.any(
              (item) => widget.displayStringForOption(item) == _controller.text,
            );
            if (!hasMatch) {
              _controller.clear();
            }
          }
        }
      });
    }
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = widget.items.take(10).toList();
        _highlightedIndex = -1;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    final List<T> exactMatches = [];
    final List<T> startsWithMatches = [];
    final List<T> containsMatches = [];

    for (final item in widget.items) {
      final fields = widget.searchFields(item);
      bool isMatch = false;
      int matchType = 3; // 1: exact match, 2: starts with, 3: contains

      for (final field in fields) {
        final lowerField = field.toLowerCase();
        if (lowerField == lowercaseQuery) {
          matchType = 1;
          isMatch = true;
          break;
        } else if (lowerField.startsWith(lowercaseQuery)) {
          if (matchType > 2) matchType = 2;
          isMatch = true;
        } else if (lowerField.contains(lowercaseQuery)) {
          isMatch = true;
        }
      }

      if (isMatch) {
        if (matchType == 1) {
          exactMatches.add(item);
        } else if (matchType == 2) {
          startsWithMatches.add(item);
        } else {
          containsMatches.add(item);
        }
      }
    }

    final combined = [...exactMatches, ...startsWithMatches, ...containsMatches];

    setState(() {
      _filteredItems = combined.take(10).toList();
      _highlightedIndex = _filteredItems.isNotEmpty ? 0 : -1;
    });

    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    if (_isOpen) return;

    final overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: _layerLink.leaderSize?.width ?? 280,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 44 + 4), // Directly below input container (height 44 + 4 padding)
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant, width: 1),
                ),
                constraints: const BoxConstraints(maxHeight: 250),
                child: _filteredItems.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'No matches found',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isHighlighted = index == _highlightedIndex;
                          final displayString = widget.displayStringForOption(item);

                          return InkWell(
                            onTap: () => _selectItem(item),
                            child: Container(
                              color: isHighlighted
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: _buildHighlightText(
                                displayString,
                                _controller.text,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _hideOverlay() {
    if (!_isOpen) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  void _selectItem(T item) {
    _controller.text = widget.displayStringForOption(item);
    widget.onSelected(item);
    _hideOverlay();
    _focusNode.unfocus();
  }

  Widget _buildHighlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(text, style: AppTypography.bodyMedium);
    }

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final index = lowercaseText.indexOf(lowercaseQuery);

    if (index == -1) {
      return Text(text, style: AppTypography.bodyMedium);
    }

    return RichText(
      text: TextSpan(
        style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
        children: [
          if (index > 0)
            TextSpan(
              text: text.substring(0, index),
            ),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (index + query.length < text.length)
            TextSpan(
              text: text.substring(index + query.length),
            ),
        ],
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_filteredItems.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1) % _filteredItems.length;
        });
        _overlayEntry?.markNeedsBuild();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_filteredItems.isNotEmpty) {
        setState(() {
          _highlightedIndex =
              (_highlightedIndex - 1 + _filteredItems.length) %
                  _filteredItems.length;
        });
        _overlayEntry?.markNeedsBuild();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _filteredItems.length) {
        _selectItem(_filteredItems[_highlightedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _hideOverlay();
      _focusNode.unfocus();
    } else if (event.logicalKey == LogicalKeyboardKey.tab) {
      if (_filteredItems.isNotEmpty) {
        _selectItem(_filteredItems[0]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;

    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.labelText,
            style: AppTypography.labelCaps.copyWith(
              color: widget.errorText != null
                  ? AppColors.error
                  : (hasFocus ? AppColors.primary : AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          CompositedTransformTarget(
            link: _layerLink,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.errorText != null
                      ? AppColors.error
                      : (hasFocus ? AppColors.primary : AppColors.border),
                  width: hasFocus ? 1.5 : 1.0,
                ),
                boxShadow: [
                  if (hasFocus && widget.errorText == null)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (val) {
                    _updateSuggestions(val);
                    if (!_isOpen) {
                      _showOverlay();
                    } else {
                      _overlayEntry?.markNeedsBuild();
                    }
                  },
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _controller.clear();
                              _updateSuggestions('');
                              widget.onSelected(null);
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
            if (widget.errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.errorText!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      );
  }
}
