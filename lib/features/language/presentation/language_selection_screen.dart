import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_flutter/core/theme/app_colors.dart';
import 'package:rhythm_flutter/features/home/providers/home_provider.dart';
import 'package:rhythm_flutter/features/language/data/models/language_model.dart';
import 'package:rhythm_flutter/features/language/providers/language_provider.dart';

/// Fullscreen Music Languages Selection Screen replacing the old dialog.
/// Eliminates all modal freeze/stuck issues and provides a modern,
/// fluid language preference configuration experience.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  final bool isFirstTime;

  const LanguageSelectionScreen({
    super.key,
    this.isFirstTime = false,
  });

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  late Set<String> _selected;
  final _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    final current = ref.read(languageProvider).selectedLanguages;
    _selected = Set<String>.from(current);
    if (_selected.isEmpty) {
      _selected = {'malayalam', 'tamil', 'english'};
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _handleSave() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 language'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final success = await ref
        .read(languageProvider.notifier)
        .savePreferences(_selected.toList());

    if (success && mounted) {
      // Refresh Home Feed immediately so new language preferences reflect
      ref.read(homeProvider.notifier).fetchHomeFeed();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Music language preferences saved!'),
          duration: Duration(seconds: 2),
        ),
      );

      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langState = ref.watch(languageProvider);
    final isSaving = langState.isSaving;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    final allLanguages = langState.availableLanguages.isNotEmpty
        ? langState.availableLanguages
        : LanguageModel.defaultSupportedLanguages();

    final filteredLanguages = _filterQuery.isEmpty
        ? allLanguages
        : allLanguages.where((l) {
            final q = _filterQuery.toLowerCase();
            return l.name.toLowerCase().contains(q) ||
                (l.nativeTitle?.toLowerCase().contains(q) ?? false) ||
                l.id.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0B14) : const Color(0xFFF7F7FC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0C0B14) : const Color(0xFFF7F7FC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Music Languages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (_selected.length == allLanguages.length) {
                  _selected = {'malayalam', 'tamil', 'english'};
                } else {
                  _selected = allLanguages.map((l) => l.id.toLowerCase()).toSet();
                }
              });
            },
            child: Text(
              _selected.length == allLanguages.length ? 'Reset' : 'Select All',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // ── Search & Header Section ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What music languages do you listen to?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select languages to customize your home feed, playlists, and recommendations.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Search input
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B192A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _filterQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search language...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark ? Colors.white54 : Colors.black45,
                            size: 20,
                          ),
                          suffixIcon: _filterQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _filterQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Language Cards Grid ──
              Expanded(
                child: filteredLanguages.isEmpty
                    ? Center(
                        child: Text(
                          'No languages found for "$_filterQuery"',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 4 : (width >= 600 ? 3 : 2),
                          mainAxisExtent: 88,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredLanguages.length,
                        itemBuilder: (context, index) {
                          final lang = filteredLanguages[index];
                          final isSelected =
                              _selected.contains(lang.id.toLowerCase());

                          return _ModernLanguageCard(
                            language: lang,
                            isSelected: isSelected,
                            isDark: isDark,
                            onTap: () => _toggle(lang.id),
                          );
                        },
                      ),
              ),

              // ── Bottom Floating Action Bar ──
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141324) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Selected Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selected.length} selected',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Apply / Save Button
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark
                                  .withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: isSaving ? null : _handleSave,
                            child: Center(
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Save & Apply',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
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
    );
  }
}

class _ModernLanguageCard extends StatelessWidget {
  final LanguageModel language;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ModernLanguageCard({
    required this.language,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF261D42)
                  : const Color(0xFFF1EDFC))
              : (isDark
                  ? const Color(0xFF181628)
                  : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryDark
                      .withValues(alpha: isDark ? 0.35 : 0.15)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Language artwork / thumbnail if available
            if (language.displayImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl: language.displayImage!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _initialsBox(),
                    errorWidget: (_, __, ___) => _initialsBox(),
                  ),
                ),
              )
            else
              _initialsBox(),

            const SizedBox(width: 12),

            // Titles Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    language.nativeTitle ?? language.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    language.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Selection Checkmark Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06)),
              ),
              child: isSelected
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
    );
  }

  Widget _initialsBox() {
    final initial = language.name.isNotEmpty ? language.name[0].toUpperCase() : 'L';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
      ),
    );
  }
}
