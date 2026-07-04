import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/vendor_provider.dart';
import '../../data/mock/mock_vendors.dart';

/// A search input field for finding and selecting a vendor by name or ID.
///
/// Displays an autocomplete list of matching vendors underneath the input.
class VendorSearchInput extends ConsumerStatefulWidget {
  /// The initial selected vendor ID, if any.
  final String? initialVendorId;

  /// Callback triggered when a vendor is selected.
  final ValueChanged<MockVendor?> onVendorSelected;

  /// Creates a [VendorSearchInput].
  const VendorSearchInput({
    super.key,
    this.initialVendorId,
    required this.onVendorSelected,
  });

  @override
  ConsumerState<VendorSearchInput> createState() => _VendorSearchInputState();
}

class _VendorSearchInputState extends ConsumerState<VendorSearchInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<MockVendor> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialVendorId != null) {
      final vendors = ref.read(vendorProvider);
      final match = vendors.firstWhere(
        (v) => v.id == widget.initialVendorId,
        orElse: () => vendors.first,
      );
      _controller.text = match.name;
    }

    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      widget.onVendorSelected(null);
      return;
    }

    final query = text.toLowerCase();
    final vendors = ref.read(vendorProvider);
    final matches = vendors.where((v) {
      return v.name.toLowerCase().contains(query) || v.id.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _suggestions = matches;
      _showSuggestions = _focusNode.hasFocus && matches.isNotEmpty;
    });
  }

  void _selectVendor(MockVendor vendor) {
    setState(() {
      _controller.text = vendor.name;
      _showSuggestions = false;
    });
    _focusNode.unfocus();
    widget.onVendorSelected(vendor);
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasFocus ? AppColors.primary : AppColors.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              if (hasFocus)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onTextChanged,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search by vendor name or ID',
                hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _onTextChanged('');
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
        if (_showSuggestions) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final vendor = _suggestions[index];
                return ListTile(
                  title: Text(vendor.name, style: AppTypography.bodyMedium),
                  subtitle: Text('ID: ${vendor.id}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  dense: true,
                  onTap: () => _selectVendor(vendor),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
