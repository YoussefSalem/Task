import 'package:customer/l10n/app_localizations.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

import '../matching/matching_screen.dart';
import 'marketplace_providers.dart';

class JobCreateStubScreen extends ConsumerStatefulWidget {
  const JobCreateStubScreen({super.key});

  static const String routePath = '/job/create';
  static const String routeName = 'job-create';

  @override
  ConsumerState<JobCreateStubScreen> createState() =>
      _JobCreateStubScreenState();
}

class _JobCreateStubScreenState extends ConsumerState<JobCreateStubScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<_MediaItem> _media = [];
  bool _publishing = false;
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, {bool video = false}) async {
    try {
      if (video) {
        final XFile? file = await _picker.pickVideo(source: source);
        if (file == null) return;
        final bytes = await file.readAsBytes();
        setState(() => _media.add(_MediaItem(
              path: file.path,
              name: file.name,
              bytes: bytes,
              isVideo: true,
            )));
      } else {
        final List<XFile> files = await _picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1920,
        );
        for (final file in files) {
          final bytes = await file.readAsBytes();
          if (!mounted) return;
          setState(() => _media.add(_MediaItem(
                path: file.path,
                name: file.name,
                bytes: bytes,
                isVideo: false,
              )));
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).couldNotAccessMedia)));
    }
  }

  void _showMediaPicker() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surface : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : const Color(0x22000000),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose photos',
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.gallery);
                },
              ),
              _SheetOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take a photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.camera);
                },
              ),
              _SheetOption(
                icon: Icons.videocam_rounded,
                label: 'Record a video',
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.camera, video: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publish(JobCategory category) async {
    final int price = int.tryParse(_price.text.trim()) ?? 0;
    ref.read(jobDraftProvider.notifier).setTitle(_title.text.trim());
    ref.read(jobDraftProvider.notifier).setPrice(price);
    ref
        .read(jobDraftProvider.notifier)
        .setPhotos(_media.map((m) => m.path).toList());
    final JobRequestDraft draft = ref.read(jobDraftProvider);
    if (!draft.isValid) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text(AppLocalizations.of(context).addAShortDescription),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    setState(() => _publishing = true);
    final job = await ref.read(jobMarketplaceRepositoryProvider).publish(draft);
    if (!mounted) return;
    context.go('${MatchingScreen.routePath}?jobId=${job.id}');
  }

  @override
  Widget build(BuildContext context) {
    final JobCategory category =
        ref.watch(jobDraftProvider).category ?? JobCategory.plumbing;
    final TextTheme text = Theme.of(context).textTheme;
    final Color tint = categoryTint(category);
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientBackground(intensity: 0.10),
          CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Builder(builder: (ctx) {
                    final bool isDark = Theme.of(ctx).brightness == Brightness.dark;
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.surface.withValues(alpha: 0.6)
                            : const Color(0xFFF0EEFF),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0x14000000),
                        ),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          size: 18),
                    );
                  }),
                  onPressed: () => context.pop(),
                ),
                title: Text(AppLocalizations.of(context).postAJob,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                centerTitle: true,
              ),

              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, mq.padding.bottom + 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Category badge
                    _StaggerIn(
                      controller: _staggerCtrl,
                      delay: 0.0,
                      child: _CategoryBadge(
                          category: category, tint: tint, text: text),
                    ),

                    const SizedBox(height: AppSpacing.xl + 4),

                    // Problem description
                    _StaggerIn(
                      controller: _staggerCtrl,
                      delay: 0.1,
                      child: _FormSection(
                        icon: Icons.edit_note_rounded,
                        label: AppLocalizations.of(context).describeTheProblem,
                        child: TextField(
                          controller: _title,
                          maxLines: 3,
                          minLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          style: text.bodyMedium,
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Living-room lights keep flickering when I turn on the AC...',
                            hintStyle: text.bodyMedium?.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                                  : AppColors.textSecondaryLight.withValues(alpha: 0.6),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.surface.withValues(alpha: 0.45)
                                : const Color(0xFFE9E5FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0x28000000),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0x28000000),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Media upload
                    _StaggerIn(
                      controller: _staggerCtrl,
                      delay: 0.2,
                      child: _FormSection(
                        icon: Icons.attach_file_rounded,
                        label: AppLocalizations.of(context).addPhotosOrVideo,
                        optional: true,
                        child: _MediaGrid(
                          media: _media,
                          onAdd: _showMediaPicker,
                          onRemove: (i) => setState(() => _media.removeAt(i)),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Price
                    _StaggerIn(
                      controller: _staggerCtrl,
                      delay: 0.3,
                      child: _FormSection(
                        icon: Icons.payments_rounded,
                        label: AppLocalizations.of(context).yourBudget,
                        child: _PriceInput(
                            controller: _price, text: text, tint: tint),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Fixed bottom CTA
          Positioned(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: mq.padding.bottom + AppSpacing.lg,
            child: GlowButton(
              label: 'Publish job',
              icon: Icons.rocket_launch_rounded,
              loading: _publishing,
              onPressed: () => _publish(category),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media item model
// ---------------------------------------------------------------------------
class _MediaItem {
  const _MediaItem({
    required this.path,
    required this.name,
    required this.bytes,
    required this.isVideo,
  });
  final String path;
  final String name;
  final Uint8List bytes;
  final bool isVideo;
}

// ---------------------------------------------------------------------------
// Stagger-in animation wrapper
// ---------------------------------------------------------------------------
class _StaggerIn extends StatelessWidget {
  const _StaggerIn({
    required this.controller,
    required this.delay,
    required this.child,
  });
  final AnimationController controller;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(delay, (delay + 0.4).clamp(0, 1),
          curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category badge
// ---------------------------------------------------------------------------
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.category,
    required this.tint,
    required this.text,
  });
  final JobCategory category;
  final Color tint;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(categoryIcon(category), color: tint, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).category,
                    style: text.labelSmall?.copyWith(
                      color: tint.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    )),
                const SizedBox(height: 2),
                Text(category.displayLabel,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: tint.withValues(alpha: 0.4), size: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form section with label + icon
// ---------------------------------------------------------------------------
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.label,
    required this.child,
    this.optional = false,
  });
  final IconData icon;
  final String label;
  final Widget child;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            if (optional) ...[
              const SizedBox(width: 8),
              Builder(builder: (context) {
                final bool isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surface.withValues(alpha: 0.5)
                        : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(AppLocalizations.of(context).optional,
                      style: text.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondary.withValues(alpha: 0.5)
                            : AppColors.textSecondaryLight,
                        fontSize: 10,
                      )),
                );
              }),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Media grid
// ---------------------------------------------------------------------------
class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.media,
    required this.onAdd,
    required this.onRemove,
  });
  final List<_MediaItem> media;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: media.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == media.length) return _AddMediaTile(onTap: onAdd, text: text);
          return _MediaTile(
            item: media[i],
            onRemove: () => onRemove(i),
          );
        },
      ),
    );
  }
}

class _AddMediaTile extends StatelessWidget {
  const _AddMediaTile({required this.onTap, required this.text});
  final VoidCallback onTap;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text('Add',
                style: text.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                )),
          ],
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.item, required this.onRemove});
  final _MediaItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0x12000000),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.isVideo
              ? Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(Icons.play_circle_fill_rounded,
                        color: AppColors.primary, size: 36),
                  ),
                )
              : Image.memory(item.bytes, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Price input with currency badge
// ---------------------------------------------------------------------------
class _PriceInput extends StatelessWidget {
  const _PriceInput({
    required this.controller,
    required this.text,
    required this.tint,
  });
  final TextEditingController controller;
  final TextTheme text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface.withValues(alpha: 0.45) : const Color(0xFFE9E5FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0x28000000),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('EGP',
                style: text.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                )),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: '400',
                hintStyle: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.25)
                      : AppColors.textSecondaryLight.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet option row
// ---------------------------------------------------------------------------
class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
