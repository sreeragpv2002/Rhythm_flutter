import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:rhythm_flutter/core/extensions/context_extensions.dart';
import 'package:rhythm_flutter/core/widgets/app_button.dart';
import 'package:rhythm_flutter/core/widgets/app_text_field.dart';
import 'package:rhythm_flutter/core/widgets/gradient_background.dart';
import 'package:rhythm_flutter/features/profile/providers/profile_provider.dart';

class ProfileCreationScreen extends ConsumerStatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  ConsumerState<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends ConsumerState<ProfileCreationScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _listeningController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _listeningController.dispose();
    super.dispose();
  }

  void _onSave() {
    ref.read(profileProvider.notifier).saveProfile(
          _nameController.text,
          _bioController.text,
          _listeningController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (profileState) {
              // Listen for errors
              if (profileState.error != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(profileState.error!),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                });
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 600;
                  final double horizontalPadding = isWide ? constraints.maxWidth * 0.2 : 24.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        FadeInDown(
                          child: Text(
                            context.l10n.createProfile,
                            style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Avatar Section
                        FadeIn(
                          child: _buildAvatar(colorScheme),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Form Section
                        _buildForm(context, profileState),
                        
                        const SizedBox(height: 48),
                        
                        // Action Buttons
                        FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: AppButton(
                            text: context.l10n.saveProfile,
                            onPressed: _onSave,
                            isLoading: profileState.isSaving,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInUp(
                          delay: const Duration(milliseconds: 700),
                          child: TextButton(
                            onPressed: () => ref.read(profileProvider.notifier).markProfileDone(),
                            child: Text(
                              context.l10n.skipForNow,
                              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    return Stack(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: Icon(
            Icons.person_rounded,
            size: 80,
            color: colorScheme.primary.withValues(alpha: 0.4),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, ProfileState profileState) {
    return Column(
      children: [
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          child: AppTextField(
            controller: _nameController,
            labelText: context.l10n.displayName,
            prefixIcon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 24),
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: AppTextField(
            controller: _bioController,
            labelText: context.l10n.bio,
            prefixIcon: Icons.description_outlined,
            hintText: context.l10n.bioHint,
            maxLines: 3,
          ),
        ),
        const SizedBox(height: 24),
        FadeInUp(
          delay: const Duration(milliseconds: 300),
          child: AppTextField(
            controller: _listeningController,
            labelText: "Listening Preferences",
            prefixIcon: Icons.headphones_outlined,
            hintText: "Genres, moods, or artists you love",
          ),
        ),
        const SizedBox(height: 32),
        
        // Language Selection
        FadeInUp(
          delay: const Duration(milliseconds: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Preferred Language", style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: profileState.selectedLanguageCode,
                items: profileState.languages.map((lang) {
                  return DropdownMenuItem(
                    value: lang.code,
                    child: Text(lang.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(profileProvider.notifier).setLanguage(val);
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.colorScheme.surface.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Artist Selection
        FadeInUp(
          delay: const Duration(milliseconds: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Favorite Artists", style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: profileState.artists.map((artist) {
                  final isSelected = profileState.selectedArtistIds.contains(artist.id);
                  return FilterChip(
                    label: Text(artist.name),
                    selected: isSelected,
                    onSelected: (_) => ref.read(profileProvider.notifier).toggleArtist(artist.id),
                    selectedColor: context.colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: context.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
