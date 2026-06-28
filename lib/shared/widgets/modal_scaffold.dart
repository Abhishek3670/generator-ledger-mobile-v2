import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import 'backdrop_blur_overlay.dart';

/// A floating centered modal scaffold container.
///
/// Features a backdrop blur filter, a structured card body with a close button in the header,
/// and sticky footer buttons.
class ModalScaffold extends StatelessWidget {
  /// The title displayed in the modal header.
  final String title;

  /// The scrollable or main content of the modal.
  final Widget body;

  /// Optional footer widget (typically sticky actions like Save/Cancel).
  final Widget? footer;

  /// Callback triggered when the close button is pressed.
  final VoidCallback onClose;

  /// Controls the visibility of the modal layout.
  final bool isVisible;

  /// Creates a [ModalScaffold].
  const ModalScaffold({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    required this.onClose,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop overlay
        BackdropBlurOverlay(
          isVisible: isVisible,
          onTap: onClose,
        ),

        // Centered modal content card
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.mobileGutter),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.modalRadius),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(0, 10),
                      blurRadius: 30,
                      color: Color(0x260F172A),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                            ),
                          ),
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: body,
                      ),
                    ),

                    // Sticky Footer
                    if (footer != null)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                        ),
                        child: footer!,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
