import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_role.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_system.dart';
import 'home_brand_panel.dart';

typedef DesignLoginSubmit =
    Future<void> Function(
      BuildContext context,
      AppRole role,
      String username,
      String password,
    );

typedef LoginMessageCallback =
    void Function(BuildContext context, String messageKey);

/// Roles selectable in the unified sign-in card, in display order.
const loginRoles = [
  AppRole.student,
  AppRole.parent,
  AppRole.teacher,
  AppRole.admin,
  AppRole.secretary,
];

/// Tasarım: `01_giris_ekrani.png` — tüm roller için tek giriş kartı.
class DesignLoginLayout extends StatefulWidget {
  const DesignLoginLayout({
    super.key,
    required this.onSubmit,
    required this.onMessage,
    this.desktopSplit = false,
    this.glass = false,
  });

  final DesignLoginSubmit onSubmit;

  /// Shows an informational message (forgot password, sign-up hints).
  final LoginMessageCallback onMessage;

  /// Windows split layout: marka sol panelde, sağda yalnızca giriş kartı.
  final bool desktopSplit;

  /// Görsel arka plan üzerinde yarısaydam (buzlu cam) kart.
  final bool glass;

  @override
  State<DesignLoginLayout> createState() => _DesignLoginLayoutState();
}

class _DesignLoginLayoutState extends State<DesignLoginLayout> {
  AppRole _tab = AppRole.student;
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _remember = false;
  bool _loading = false;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Admin goes through even when empty so first-run setup stays reachable.
    if (_passController.text.isEmpty && _tab != AppRole.admin) return;
    setState(() => _loading = true);
    try {
      await widget.onSubmit(
        context,
        _tab,
        _userController.text.trim(),
        _passController.text,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final glass = widget.glass;

    InputDecoration fieldDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: glass ? null : label,
        hintText: glass ? label : null,
        prefixIcon: Icon(icon),
        filled: glass ? true : null,
        fillColor: glass ? Colors.white.withValues(alpha: 0.92) : null,
      );
    }

    final form = Padding(
      padding: EdgeInsets.all(glass ? AppSpacing.xl : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoleTabs(
            selected: _tab,
            onChanged: (r) => setState(() => _tab = r),
            strings: strings,
            glass: glass,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _userController,
            decoration: fieldDecoration(
              strings.t('designLoginUsername'),
              Icons.person_outline,
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _passController,
            obscureText: true,
            decoration: fieldDecoration(
              strings.t('password'),
              Icons.lock_outline,
            ),
            onSubmitted: (_) => _login(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Checkbox(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
              ),
              Text(strings.t('designLoginRememberMe')),
              TextButton(
                onPressed: () =>
                    widget.onMessage(context, 'designForgotPasswordHint'),
                child: Text(strings.t('designForgotPassword')),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            button: true,
            label: strings.t('designLoginButton'),
            child: FilledButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.t('designLoginButton')),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => widget.onMessage(context, 'designSignUpHint'),
            child: Text(strings.t('designNoAccountSignUp')),
          ),
        ],
      ),
    );

    if (glass) return _GlassSurface(child: form);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.desktopSplit) const HomeBrandPanel(compact: true),
          Padding(
            padding: AppSpacing.pagePadding(width),
            child: Material(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignSystem.cardRadius),
              ),
              child: DecoratedBox(
                decoration: DesignSystem.surfaceCardDecoration(),
                child: form,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DesignSystem.cardRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadows.elevated,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            ),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}

class _RoleTabs extends StatelessWidget {
  const _RoleTabs({
    required this.selected,
    required this.onChanged,
    required this.strings,
    this.glass = false,
  });

  final AppRole selected;
  final ValueChanged<AppRole> onChanged;
  final AppLocalizations strings;
  final bool glass;

  static const _titleKeys = {
    AppRole.student: 'homeRoleStudentTitle',
    AppRole.parent: 'homeRoleParentTitle',
    AppRole.teacher: 'homeRoleTeacherTitle',
    AppRole.admin: 'homeRoleAdminTitle',
    AppRole.secretary: 'homeRoleSecretaryTitle',
  };

  @override
  Widget build(BuildContext context) {
    final tabs = [
      for (final role in loginRoles) (role, strings.t(_titleKeys[role]!)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: glass
            ? Colors.white.withValues(alpha: 0.55)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final (role, label) in tabs)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Semantics(
                  button: true,
                  selected: selected == role,
                  child: Material(
                    color: selected == role
                        ? AppColors.primaryBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onChanged(role),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppSpacing.minTouchTarget,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: selected == role
                                      ? Colors.white
                                      : AppColors.navy,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
