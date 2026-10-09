import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import 'account_required_password_change_screen.dart';
import 'change_teacher_password_screen.dart';
import '../utils/role_workspace_navigation.dart';
import '../models/app_role.dart';
import '../utils/secretary_navigation.dart';
import '../utils/parent_navigation.dart';
import '../utils/student_navigation.dart';
import '../utils/teacher_navigation.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_language_button.dart';
import 'home/design_login_layout.dart';
import 'home/home_brand_panel.dart';
import 'home/login_hero_layout.dart';
import 'admin_portal/admin_bootstrap_screen.dart';

/// MyEduApp giriş ekranı — tüm roller için tek giriş kartı.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Sol bilgi paneli + görsel arka planın sığdığı en dar genişlik.
  static const double _heroLayoutMinWidth = 840;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = AppSpacing.isMobile(width);
    final isTablet = AppSpacing.isTablet(width);

    if (width >= _heroLayoutMinWidth) {
      return const Scaffold(
        body: LoginHeroLayout(
          onSubmit: _submitDesignLogin,
          onMessage: _showMessage,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: isMobile
                  ? DesignLoginLayout(
                      onSubmit: _submitDesignLogin,
                      onMessage: _showMessage,
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: isTablet ? 38 : 34,
                          child: const HomeBrandPanel(),
                        ),
                        Expanded(
                          flex: isTablet ? 62 : 66,
                          child: ColoredBox(
                            color: AppColors.background,
                            child: Center(
                              child: SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 480,
                                  ),
                                  child: DesignLoginLayout(
                                    desktopSplit: true,
                                    onSubmit: _submitDesignLogin,
                                    onMessage: _showMessage,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            PositionedDirectional(
              top: AppSpacing.xs,
              end: AppSpacing.xs,
              child: Material(
                color: AppColors.surface.withValues(alpha: 0.9),
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: const AppLanguageButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showMessage(BuildContext context, String messageKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).t(messageKey))),
    );
  }

  /// Single sign-in entry point; [role] comes from the card's role tabs.
  static Future<void> _submitDesignLogin(
    BuildContext context,
    AppRole role,
    String username,
    String password,
  ) async {
    switch (role) {
      case AppRole.teacher:
        await _loginTeacher(context, username, password);
      case AppRole.student:
        await _loginStudent(context, username, password);
      case AppRole.parent:
        await _loginParent(context, username, password);
      case AppRole.secretary:
        await _loginSecretary(context, username, password);
      case AppRole.admin:
        await _loginAdmin(context, username, password);
    }
  }

  static Future<void> _loginTeacher(
    BuildContext context,
    String username,
    String password,
  ) async {
    final state = context.read<AppState>();
    if (username.isNotEmpty) {
      await _loginWithAccount(context, AppRole.teacher, username, password);
      return;
    }
    final result = await state.verifyTeacherPassword(password);
    if (!context.mounted) return;
    if (!result.success) {
      _showMessage(context, 'wrongPassword');
      return;
    }
    if (result.needsPasswordChange) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChangeTeacherPasswordScreen()),
      );
      return;
    }
    state.setUnlocked(true, role: AppRole.teacher);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TeacherTabWorkspace()),
    );
  }

  static Future<void> _loginStudent(
    BuildContext context,
    String username,
    String password,
  ) async {
    final state = context.read<AppState>();
    final number = int.tryParse(username);
    final login = number == null
        ? (success: false, ambiguous: false, studentId: null, classId: null)
        : await state.loginStudent(studentNumber: number, password: password);
    if (!context.mounted) return;
    if (!login.success && !login.ambiguous && username.isNotEmpty) {
      final account = await state.loginStudentAccount(
        login: username,
        password: password,
      );
      if (!context.mounted) return;
      if (account.success) {
        state.setStudentSession(
          classId: account.classId!,
          studentId: account.studentId!,
        );
        await _afterAccountLogin(
          context,
          role: AppRole.student,
          mustChangePassword: account.mustChangePassword,
        );
        return;
      }
    }
    if (!login.success) {
      _showMessage(
        context,
        login.ambiguous ? 'studentLoginAmbiguous' : 'wrongPassword',
      );
      return;
    }
    state.setStudentSession(
      classId: login.classId!,
      studentId: login.studentId!,
    );
    state.setUnlocked(true, role: AppRole.student);
    openStudentPortal(context);
  }

  static Future<void> _loginParent(
    BuildContext context,
    String username,
    String password,
  ) async {
    final state = context.read<AppState>();
    final login = await state.loginParent(email: username, password: password);
    if (!context.mounted) return;
    if (!login.success) {
      _showMessage(
        context,
        login.noLinkedStudents ? 'parentLoginNoStudents' : 'wrongPassword',
      );
      return;
    }
    final links = await state.db.listStudentsForParent(login.parentId!);
    if (!context.mounted) return;
    final firstStudentId = links.first['ogrenci_id'] as int;
    state.setParentSession(
      parentId: login.parentId!,
      selectedStudentId: firstStudentId,
    );
    state.setUnlocked(true, role: AppRole.parent);
    openParentPortal(context);
  }

  static Future<void> _loginSecretary(
    BuildContext context,
    String username,
    String password,
  ) async {
    final state = context.read<AppState>();
    if (username.isNotEmpty) {
      await _loginWithAccount(context, AppRole.secretary, username, password);
      return;
    }
    if (!state.verifySecretaryPassword(password)) {
      _showMessage(context, 'wrongPassword');
      return;
    }
    state.setUnlocked(true, role: AppRole.secretary);
    openSecretaryPortal(context);
  }

  static Future<void> _loginAdmin(
    BuildContext context,
    String username,
    String password,
  ) async {
    final state = context.read<AppState>();
    if (!await state.hasActiveAdminAccount()) {
      if (!context.mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AdminBootstrapScreen()));
      return;
    }
    if (!context.mounted) return;
    if (username.isEmpty || password.isEmpty) {
      _showMessage(context, 'wrongPassword');
      return;
    }
    await _loginWithAccount(context, AppRole.admin, username, password);
  }

  static Future<void> _loginWithAccount(
    BuildContext context,
    AppRole role,
    String username,
    String password,
  ) async {
    final login = await context.read<AppState>().loginRoleAccount(
      role: role,
      login: username,
      password: password,
    );
    if (!context.mounted) return;
    if (!login.success) {
      _showMessage(context, 'wrongPassword');
      return;
    }
    await _afterAccountLogin(
      context,
      role: role,
      mustChangePassword: login.mustChangePassword,
    );
  }

  static Future<void> _afterAccountLogin(
    BuildContext context, {
    required AppRole role,
    required bool mustChangePassword,
  }) async {
    if (!context.mounted) return;
    if (mustChangePassword) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AccountRequiredPasswordChangeScreen(role: role),
        ),
      );
      return;
    }
    context.read<AppState>().setUnlocked(true, role: role);
    openRolePrimaryWorkspace(context, role);
  }
}
