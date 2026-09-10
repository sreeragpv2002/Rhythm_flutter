import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/features/language/data/models/language_model.dart';
import 'package:rhythm_flutter/features/language/providers/language_provider.dart';

/// Senior-styled dialog for selecting music languages.
class LanguageSelectionDialog extends ConsumerStatefulWidget {
  final bool isFirstTime;

  const LanguageSelectionDialog({
    super.key,
    this.isFirstTime = false,
  });

  /// Navigates directly to the full LanguageSelectionScreen
  static Future<bool?> show(
    BuildContext context, {
    bool isFirstTime = false,
  }) {
    return context.push<bool>('/languages', extra: isFirstTime);
  }

  @override
  ConsumerState<LanguageSelectionDialog> createState() =>
      _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState
    extends ConsumerState<LanguageSelectionDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final current = ref.read(languageProvider).selectedLanguages;
    _selected = Set<String>.from(current);
    if (_selected.isEmpty) {
      _selected = {'malayalam', 'tamil', 'english'};
    }
  }

  void _toggle(String code) {
    final lower = code.toLowerCase().trim();
    setState(() {
      if (_selected.contains(lower)) {
        if (_selected.length > 1) {
          _selected.remove(lower);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please keep at least 1 language selected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _selected.add(lower);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langState = ref.watch(languageProvider);
    final isSaving = langState.isSaving;

    final languages = langState.availableLanguages.isNotEmpty
        ? langState.availableLanguages
        : LanguageModel.defaultSupportedLanguages();

    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width > 560 ? 520.0 : (size.width - 32);
    final dialogMaxHeight = math.min(size.height * 0.85, 600.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: dialogMaxHeight,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161628) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header Banner (Fixed Height) ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryLight
                              .withValues(alpha: isDark ? 0.18 : 0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.language_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Music Languages',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select languages to customize your feed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close Button (Always present to prevent trapping)
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // ── Language Grid (Scrollable Body) ──
                  Flexible(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shrinkWrap: true,
                      itemCount: languages.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: dialogWidth >= 460 ? 2 : 1,
                        mainAxisExtent: 76,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final lang = languages[index];
                        final isSelected =
                            _selected.contains(lang.id.toLowerCase());

                        return _LanguageCard(
                          language: lang,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () => _toggle(lang.id),
                        );
                      },
                    ),
                  ),

                  // ── Footer with Save Button (Fixed Height) ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.28)
                          : Colors.black.withValues(alpha: 0.03),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Selected count badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_selected.length} selected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Skip / Later button
                        TextButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(
                            widget.isFirstTime ? 'Skip' : 'Cancel',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Save button
                        Container(
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            onPressed: isSaving ? null : _saveAndClose,
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Save & Continue',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndClose() async {
    final success = await ref
        .read(languageProvider.notifier)
        .savePreferences(_selected.toList());

    if (mounted) {
      Navigator.of(context).pop(success);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Music languages updated successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _LanguageCard extends StatefulWidget {
  final LanguageModel language;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? activeColor.withValues(alpha: widget.isDark ? 0.2 : 0.12)
                : (_isHovered
                    ? (widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04))
                    : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.02))),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? activeColor
                  : (_isHovered
                      ? (widget.isDark ? Colors.white24 : Colors.black26)
                      : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05))),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Language Image / Icon (Safe without memCacheWidth)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: widget.language.displayImage != null &&
                          widget.language.displayImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.language.displayImage!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholder(),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),

              const SizedBox(width: 10),

              // Title and Native Script
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.language.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: widget.isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: widget.isSelected
                            ? (widget.isDark ? Colors.white : activeColor)
                            : (widget.isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight),
                      ),
                    ),
                    if (widget.language.nativeTitle != null &&
                        widget.language.nativeTitle !=
                            widget.language.displayTitle)
                      Text(
                        widget.language.nativeTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isDark
                              ? Colors.white54
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
              ),

              // Checkbox indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected ? activeColor : Colors.transparent,
                  border: Border.all(
                    color: widget.isSelected
                        ? activeColor
                        : (widget.isDark ? Colors.white30 : Colors.black26),
                    width: 1.5,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: widget.isDark ? const Color(0xFF232338) : const Color(0xFFEBE8F3),
      child: const Center(
        child: Icon(Icons.music_note_rounded, size: 18, color: Colors.white38),
      ),
    );
  }
}
