import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../services/authorization_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_design_tokens.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/app_navigation.dart';
import '../utils/admin_navigation.dart';
import '../utils/parent_navigation.dart';
import '../utils/secretary_navigation.dart';
import '../utils/student_navigation.dart';
import '../models/app_role.dart';
import '../utils/academic_plans_navigation.dart';
import '../utils/teacher_nav_section.dart';
import '../utils/teacher_navigation.dart';
import 'app_language_button.dart';
import 'app_sidebar_profile.dart';
import 'app_workspace_background.dart';
import 'app_mobile_bottom_nav.dart';
import 'notification_bell_button.dart';
import 'page_header.dart';
import '../utils/settings_navigation.dart';

export '../utils/secretary_navigation.dart'
    show
        SecretaryNavSection,
        secretaryMainMenuOrder,
        secretaryStudentsMenuOrder,
        secretaryClassesMenuOrder,
        secretaryParentsMenuOrder,
        secretaryAttendanceMenuOrder,
        secretaryAnnouncementsMenuOrder,
        secretaryDocumentsMenuOrder;
export '../utils/admin_navigation.dart'
    show AdminNavSection, adminSidebarMenuOrder;
export '../utils/parent_navigation.dart'
    show ParentNavSection, parentSidebarMenuOrder;
export '../utils/student_navigation.dart'
    show StudentNavSection, studentSidebarMenuOrder;
export '../utils/teacher_nav_section.dart' show TeacherNavSection;
export '../utils/academic_plans_navigation.dart'
    show AcademicPlansSidebarSection, academicPlansSidebarMenuOrder;
export '../utils/teacher_navigation.dart'
    show LessonPlatformSidebarSection, TeacherTabWorkspace, navigateTeacherSection;

/// Shared App Shell — navy sidebar + page header + content area.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.showSearch = false,
    this.searchHint,
    this.onSearchChanged,
    required this.child,
    this.teacherSection,
    this.studentSection,
    this.secretarySection,
    this.parentSection,
    this.adminSection,
    this.lessonPlatformSection,
    this.onLessonPlatformSectionChanged,
    this.academicPlansSection,
    this.onAcademicPlansSectionChanged,
    this.compactHeader = false,
    this.showLogout = true,
    this.constrainContent = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showSearch;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final Widget child;
  final TeacherNavSection? teacherSection;
  final StudentNavSection? studentSection;
  final SecretaryNavSection? secretarySection;
  final ParentNavSection? parentSection;
  final AdminNavSection? adminSection;
  final LessonPlatformSidebarSection? lessonPlatformSection;
  final ValueChanged<LessonPlatformSidebarSection>? onLessonPlatformSectionChanged;
  final AcademicPlansSidebarSection? academicPlansSection;
  final ValueChanged<AcademicPlansSidebarSection>? onAcademicPlansSectionChanged;
  final bool compactHeader;
  final bool showLogout;

  /// Centers content with [AppSpacing.contentMaxWidth] on large desktop
  /// (>= 1440 px). Set to false for full-bleed screens (viewer, builder).
  final bool constrainContent;

  Widget _contentArea(double shellWidth) {
    return AppWorkspaceBackground(
      child: constrainContent &&
              AppSpacing.breakpoint(shellWidth) == AppBreakpoint.largeDesktop
          ? LayoutBuilder(
              builder: (context, box) {
                final extra = box.maxWidth - AppSpacing.contentMaxWidth;
                if (!extra.isFinite || extra <= 0) return child;
                // Padding (not Align) keeps the full, tight height for the child.
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: extra / 2),
                  child: child,
                );
              },
            )
          : child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerActions = [
      const AppLanguageButton(),
      const NotificationBellButton(),
      ...actions,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = AppSpacing.isMobile(width);
        if (!isMobile) {
          return Scaffold(
            body: Row(
              children: [
                _AppSidebar(
                  teacherSection: teacherSection,
                  studentSection: studentSection,
                  secretarySection: secretarySection,
                  parentSection: parentSection,
                  adminSection: adminSection,
                  lessonPlatformSection: lessonPlatformSection,
                  onLessonPlatformSectionChanged: onLessonPlatformSectionChanged,
                  academicPlansSection: academicPlansSection,
                  onAcademicPlansSectionChanged: onAcademicPlansSectionChanged,
                  showLogout: showLogout,
                ),
                Expanded(
                  child: Column(
                    children: [
                      PageHeader(
                        title: title,
                        subtitle: subtitle,
                        leading: leading,
                        actions: headerActions,
                        showSearch: showSearch,
                        searchHint: searchHint,
                        onSearchChanged: onSearchChanged,
                        compact: compactHeader,
                      ),
                      if (teacherSection != null)
                        const _TeacherNavTabBar(),
                      Expanded(child: _contentArea(width)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          drawer: Drawer(
            backgroundColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.large),
                child: _AppSidebar(
              teacherSection: teacherSection,
              studentSection: studentSection,
              secretarySection: secretarySection,
              parentSection: parentSection,
              adminSection: adminSection,
              lessonPlatformSection: lessonPlatformSection,
              onLessonPlatformSectionChanged: onLessonPlatformSectionChanged,
              academicPlansSection: academicPlansSection,
              onAcademicPlansSectionChanged: onAcademicPlansSectionChanged,
              showLogout: showLogout,
              inDrawer: true,
                ),
              ),
            ),
          ),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.tokens.textSecondary,
                        ),
                  ),
              ],
            ),
            leading: leading ??
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: MaterialLocalizations.of(ctx).openAppDrawerTooltip,
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
            actions: [
              ...headerActions,
              if (leading != null)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: MaterialLocalizations.of(ctx).openAppDrawerTooltip,
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
            ],
          ),
          body: AppWorkspaceBackground(child: child),
          bottomNavigationBar: AppMobileBottomNav(
            teacherSection: teacherSection,
            studentSection: studentSection,
            secretarySection: secretarySection,
            parentSection: parentSection,
            adminSection: adminSection,
          ),
        );
      },
    );
  }
}

class _AppSidebar extends StatefulWidget {
  const _AppSidebar({
    this.teacherSection,
    this.studentSection,
    this.secretarySection,
    this.parentSection,
    this.adminSection,
    this.lessonPlatformSection,
    this.onLessonPlatformSectionChanged,
    this.academicPlansSection,
    this.onAcademicPlansSectionChanged,
    this.showLogout = true,
    this.inDrawer = false,
  });

  final TeacherNavSection? teacherSection;
  final StudentNavSection? studentSection;
  final SecretaryNavSection? secretarySection;
  final ParentNavSection? parentSection;
  final AdminNavSection? adminSection;
  final LessonPlatformSidebarSection? lessonPlatformSection;
  final ValueChanged<LessonPlatformSidebarSection>? onLessonPlatformSectionChanged;
  final AcademicPlansSidebarSection? academicPlansSection;
  final ValueChanged<AcademicPlansSidebarSection>? onAcademicPlansSectionChanged;
  final bool showLogout;
  final bool inDrawer;

  @override
  State<_AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<_AppSidebar> {
  bool _hoverExpanded = false;
  bool _tapExpanded = false;
  bool _lessonPlatformExpanded = true;
  bool _academicPlansExpanded = true;
  Timer? _hoverCollapseTimer;

  bool get _expanded =>
      widget.inDrawer || _hoverExpanded || _tapExpanded;

  @override
  void dispose() {
    _hoverCollapseTimer?.cancel();
    super.dispose();
  }

  /// Avoid setState during [MouseTracker] device updates (Windows debug).
  void _setHoverExpanded(bool expanded) {
    if (widget.inDrawer || _hoverExpanded == expanded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hoverExpanded == expanded) return;
      setState(() => _hoverExpanded = expanded);
    });
  }

  void _onSidebarPointerEnter(_) {
    _hoverCollapseTimer?.cancel();
    _setHoverExpanded(true);
  }

  void _onSidebarPointerExit(_) {
    _hoverCollapseTimer?.cancel();
    _hoverCollapseTimer = Timer(const Duration(milliseconds: 150), () {
      _setHoverExpanded(false);
    });
  }

  bool get _onLessonPlatform =>
      widget.teacherSection == TeacherNavSection.lessonPlatform ||
      widget.studentSection == StudentNavSection.lessonPlatform;

  bool get _onAcademicPlans =>
      widget.teacherSection == TeacherNavSection.academicPlans;

  void _collapse() {
    setState(() {
      _hoverExpanded = false;
      _tapExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final role = state.currentRole;
    final width = _expanded
        ? AppSpacing.sidebarWidth
        : AppSpacing.sidebarCollapsed;

    return MouseRegion(
      onEnter: widget.inDrawer ? null : _onSidebarPointerEnter,
      onExit: widget.inDrawer ? null : _onSidebarPointerExit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        clipBehavior: Clip.hardEdge,
        color: AppColors.navy,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Labelled rows need ~125 px (icon + gap + 48 px group toggle +
            // paddings); switching earlier overflows mid-animation.
            final showLabels =
                widget.inDrawer || constraints.maxWidth >= 180;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    showLabels ? 20 : 12,
                    AppSpacing.xl,
                    showLabels ? 20 : 12,
                    20,
                  ),
                  child: showLabels
                      ? Semantics(
                          header: true,
                          container: true,
                          child: Row(
                          children: [
                            _brandIcon(),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.t('appTitle'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _sidebarSubtitle(strings, role),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.65),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        )
                      : Semantics(
                          button: true,
                          label: strings.t('appTitle'),
                          excludeSemantics: true,
                          onTap: () =>
                              setState(() => _tapExpanded = !_tapExpanded),
                          child: Tooltip(
                            message: strings.t('appTitle'),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  setState(() => _tapExpanded = !_tapExpanded),
                              child: SizedBox(
                                height: AppSpacing.minTouchTarget,
                                child: Center(child: _brandIcon()),
                              ),
                            ),
                          ),
                        ),
                ),
                const Divider(color: Colors.white12, height: 1),
                if (widget.inDrawer) ...[
                  Semantics(
                    header: true,
                    container: true,
                    child: AppSidebarProfile(showLabels: showLabels),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                ],
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                    children: _sidebarItems(context, strings, showLabels, role),
                  ),
                ),
                if (!widget.inDrawer) AppSidebarProfile(showLabels: showLabels),
                if (widget.showLogout)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _SidebarTile(
                      icon: Icons.logout_rounded,
                      label: strings.t('exitToHome'),
                      selected: false,
                      showLabels: showLabels,
                      labelColor: widget.inDrawer ? AppColors.error : null,
                      iconColor: widget.inDrawer ? AppColors.error : null,
                      onTap: () async {
                        if (widget.inDrawer) Navigator.pop(context);
                        state.clearSession();
                        logoutToLogin(context);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _brandIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.sidebarActive.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: const Icon(
        Icons.school_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  String _sidebarSubtitle(AppLocalizations strings, AppRole? role) {
    return switch (role) {
      AppRole.teacher => strings.t('teacherMenuWelcome'),
      AppRole.secretary => strings.t('secretaryMenuWelcome'),
      AppRole.student => strings.t('studentPlatform'),
      AppRole.parent => strings.t('parentPortalTitle'),
      AppRole.admin => strings.t('adminPortalTitle'),
      null => strings.t('studentPlatform'),
    };
  }

  List<Widget> _sidebarItems(
    BuildContext context,
    AppLocalizations strings,
    bool showLabels,
    AppRole? role,
  ) {
    return switch (role) {
      AppRole.teacher => _teacherItems(context, strings, showLabels),
      AppRole.secretary => _secretaryItems(context, strings, showLabels),
      AppRole.student => _studentItems(context, strings, showLabels),
      AppRole.parent => _parentItems(context, strings, showLabels),
      AppRole.admin => _adminItems(context, strings, showLabels),
      null => _studentItems(context, strings, showLabels),
    };
  }

  List<Widget> _adminItems(
    BuildContext context,
    AppLocalizations strings,
    bool showLabels,
  ) {
    final auth = AuthorizationService(context.read<AppState>());
    return [
      for (final section in adminSidebarMenuOrder)
        _SidebarTile(
          icon: section.icon,
          label: section.label(strings),
          selected: widget.adminSection == section,
          showLabels: showLabels,
          onTap: () => _navAdmin(context, section),
        ),
      if (auth.canManageLocaleAndTheme)
        _SidebarTile(
          icon: Icons.settings_outlined,
          label: strings.t('settings'),
          selected: false,
          showLabels: showLabels,
          onTap: () => _openSettings(context),
        ),
    ];
  }

  List<Widget> _parentItems(
    BuildContext context,
    AppLocalizations strings,
    bool showLabels,
  ) {
    final auth = AuthorizationService(context.read<AppState>());
    return [
      for (final section in parentSidebarMenuOrder)
        _SidebarTile(
          icon: section.icon,
          label: section.label(strings),
          selected: widget.parentSection == section,
          showLabels: showLabels,
          onTap: () => _navParent(context, section),
        ),
      if (auth.canManageLocaleAndTheme)
        _SidebarTile(
          icon: Icons.settings_outlined,
          label: strings.t('settings'),
          selected: false,
          showLabels: showLabels,
          onTap: () => _openSettings(context),
        ),
    ];
  }

  List<Widget> _teacherItems(
    BuildContext context,
    AppLocalizations strings,
    bool showLabels,
  ) {
    return [
      _SidebarTile(
        icon: Icons.dashboard_rounded,
        label: strings.t('homePage'),
        selected: widget.teacherSection == TeacherNavSection.home,
        showLabels: showLabels,
        onTap: () => _nav(context, TeacherNavSection.home),
      ),
      _LessonPlatformSidebarGroup(
        label: strings.t('goToApp'),
        showLabels: showLabels,
        expanded: _lessonPlatformExpanded,
        isOnLessonPlatform: _onLessonPlatform,
        selectedSection: widget.lessonPlatformSection,
        onToggle: () => setState(() {
          _lessonPlatformExpanded = !_lessonPlatformExpanded;
        }),
        onParentTap: () {
          if (!_onLessonPlatform) {
            _nav(context, TeacherNavSection.lessonPlatform);
          } else {
            setState(() => _lessonPlatformExpanded = !_lessonPlatformExpanded);
          }
        },
        onSectionSelected: (section) {
          if (!_onLessonPlatform) {
            _nav(context, TeacherNavSection.lessonPlatform);
          }
          widget.onLessonPlatformSectionChanged?.call(section);
          if (widget.inDrawer) Navigator.pop(context);
          _collapse();
        },
      ),
      _SidebarTile(
        icon: Icons.groups_rounded,
        label: strings.t('studentPlatform'),
        selected: widget.teacherSection == TeacherNavSection.studentPlatform,
        showLabels: showLabels,
        onTap: () => _nav(context, TeacherNavSection.studentPlatform),
      ),
      _AcademicPlansSidebarGroup(
        label: strings.t('academicPlans'),
        showLabels: showLabels,
        expanded: _academicPlansExpanded,
        isOnAcademicPlans: _onAcademicPlans,
        selectedSection: widget.academicPlansSection,
        onToggle: () => setState(() {
          _academicPlansExpanded = !_academicPlansExpanded;
        }),
        onParentTap: () {
          if (!_onAcademicPlans) {
            _nav(context, TeacherNavSection.academicPlans);
          } else {
            setState(() => _academicPlansExpanded = !_academicPlansExpanded);
          }
        },
        onSectionSelected: (section) {
          context.read<AppState>().requestAcademicPlansSection(section);
          if (!_onAcademicPlans) {
            _nav(context, TeacherNavSection.academicPlans);
          }
          widget.onAcademicPlansSectionChanged?.call(section);
          if (widget.inDrawer) Navigator.pop(context);
          _collapse();
        },
      ),
      _SidebarTile(
        icon: Icons.supervisor_account_rounded,
        label: strings.t('mentorship'),
        selected: widget.teacherSection == TeacherNavSection.mentorship,
        showLabels: showLabels,
        onTap: () => _nav(context, TeacherNavSection.mentorship),
      ),
      _SidebarTile(
        icon: Icons.assessment_rounded,
        label: strings.t('reports'),
        selected: widget.teacherSection == TeacherNavSection.reports,
        showLabels: showLabels,
        onTap: () => _nav(context, TeacherNavSection.reports),
      ),
      _SidebarTile(
        icon: Icons.help_outline_rounded,
        label: strings.t('userGuide'),
        selected: widget.teacherSection == TeacherNavSection.userGuide,
        showLabels: showLabels,
        onTap: () => _nav(context, TeacherNavSection.userGuide),
      ),
      _SidebarTile(
        icon: Icons.settings_rounded,
        label: strings.t('settings'),
        selected: widget.teacherSection == TeacherNavSection.settings,
        showLabels: showLabels,
        onTap: () => _nav(context, TeacherNavSection.settings),
      ),
    ];
  }

  List<Widget> _studentItems(
    BuildContext context,
    AppLocalizations strings,
    bool showLabels,
  ) {
    final auth = AuthorizationService(context.read<AppState>());
    return [
      for (final section in studentSidebarMenuOrder)
        _SidebarTile(
          icon: section.icon,
          label: section.label(strings),
          selected: widget.studentSection == section,
          showLabels: showLabels,
          onTap: () => _navStudent(context, section),
        ),
      if (auth.canManageLocaleAndTheme)
        _SidebarTile(
          icon: Icons.settings_outlined,
          label: strings.t('settings'),
          selected: false,
          showLabels: showLabels,
          onTap: () => _openSettings(context),
        ),
    ];
  }

  List<Widget> _secretaryItems(
    BuildContext context,
    AppLocalizations strings,
    bool showLabels,
  ) {
    final active = widget.secretarySection;
    final activeModule = active?.sidebarModule;

    return [
      for (final module in secretaryMainMenuOrder)
        _SidebarTile(
          icon: module.icon,
          label: module.label(strings),
          selected: activeModule == module,
          showLabels: showLabels,
          onTap: () => _navSecretary(context, module),
        ),
      _SidebarTile(
        icon: SecretaryNavSection.profile.icon,
        label: SecretaryNavSection.profile.label(strings),
        selected: active == SecretaryNavSection.profile,
        showLabels: showLabels,
        onTap: () => _navSecretary(context, SecretaryNavSection.profile),
      ),
      if (AuthorizationService(context.read<AppState>()).canManageLocaleAndTheme)
        _SidebarTile(
          icon: Icons.settings_outlined,
          label: strings.t('settings'),
          selected: false,
          showLabels: showLabels,
          onTap: () => _openSettings(context),
        ),
    ];
  }

  void _openSettings(BuildContext context) {
    if (widget.inDrawer) Navigator.pop(context);
    _collapse();
    openAppSettings(context);
  }

  void _nav(BuildContext context, TeacherNavSection section) {
    if (widget.teacherSection == section) {
      if (widget.inDrawer) Navigator.pop(context);
      return;
    }
    if (widget.inDrawer) Navigator.pop(context);
    _collapse();
    navigateTeacherSection(context, section);
  }

  void _navStudent(BuildContext context, StudentNavSection section) {
    if (widget.studentSection == section) {
      if (widget.inDrawer) Navigator.pop(context);
      return;
    }
    if (widget.inDrawer) Navigator.pop(context);
    _collapse();
    navigateStudentSection(context, section);
  }

  void _navSecretary(BuildContext context, SecretaryNavSection section) {
    final current = widget.secretarySection?.sidebarModule;
    final target = section.sidebarModule;
    if (current == target && widget.secretarySection == section) {
      if (widget.inDrawer) Navigator.pop(context);
      return;
    }
    if (widget.inDrawer) Navigator.pop(context);
    _collapse();
    navigateSecretarySection(context, section);
  }

  void _navParent(BuildContext context, ParentNavSection section) {
    if (widget.parentSection == section) {
      if (widget.inDrawer) Navigator.pop(context);
      return;
    }
    if (widget.inDrawer) Navigator.pop(context);
    _collapse();
    navigateParentSection(context, section);
  }

  void _navAdmin(BuildContext context, AdminNavSection section) {
    if (widget.adminSection == section) {
      if (widget.inDrawer) Navigator.pop(context);
      return;
    }
    if (widget.inDrawer) Navigator.pop(context);
    _collapse();
    navigateAdminSection(context, section);
  }
}

/// Shared sidebar/drawer nav item: min 48 px hit area, button semantics,
/// selected pill ([AppRadius.medium]) and a visible keyboard focus ring.
class _SidebarInkItem extends StatefulWidget {
  const _SidebarInkItem({
    required this.label,
    required this.onTap,
    required this.child,
    this.selected = false,
    this.activeAlpha = 0.25,
    this.radius = AppRadius.medium,
    this.padding = EdgeInsets.zero,
    this.excludeChildSemantics = true,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final bool selected;
  final double activeAlpha;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// When false, descendants (e.g. a toggle button) keep their own semantics.
  final bool excludeChildSemantics;

  @override
  State<_SidebarInkItem> createState() => _SidebarInkItemState();
}

class _SidebarInkItemState extends State<_SidebarInkItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onTap,
      excludeSemantics: widget.excludeChildSemantics,
      child: Material(
        color: widget.selected
            ? AppColors.sidebarActive.withValues(alpha: widget.activeAlpha)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: _focused
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          hoverColor: AppColors.sidebarHover,
          focusColor: Colors.white.withValues(alpha: 0.16),
          onFocusChange: (value) {
            if (_focused != value) setState(() => _focused = value);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.showLabels,
    this.selected = false,
    this.labelColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showLabels;
  final bool selected;
  final Color? labelColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ??
        (selected ? Colors.white : Colors.white.withValues(alpha: 0.75));
    final tile = _SidebarInkItem(
      label: label,
      selected: selected,
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: showLabels ? 14 : 0),
      child: showLabels
          ? Row(
              children: [
                Icon(icon, size: 20, color: resolvedIconColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor ??
                          (selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8)),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: AppTypography.labelSize,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.sidebarActive,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            )
          : Center(child: Icon(icon, size: 22, color: resolvedIconColor)),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: showLabels ? tile : Tooltip(message: label, child: tile),
    );
  }
}

/// Expand/collapse toggle used inside group parent tiles (48 px target).
class _SidebarGroupToggle extends StatelessWidget {
  const _SidebarGroupToggle({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        expanded ? Icons.expand_less : Icons.expand_more,
        color: Colors.white.withValues(alpha: 0.75),
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
      tooltip: expanded ? 'Daralt' : 'Genişlet',
    );
  }
}

/// Indented child row of a sidebar group.
class _SidebarSubItem extends StatelessWidget {
  const _SidebarSubItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, bottom: 2),
      child: _SidebarInkItem(
        label: label,
        selected: selected,
        onTap: onTap,
        activeAlpha: 0.18,
        radius: AppRadius.small,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: AppTypography.bodySmallSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Group parent row (icon + label + optional expand toggle).
class _SidebarGroupParent extends StatelessWidget {
  const _SidebarGroupParent({
    required this.icon,
    required this.label,
    required this.showLabels,
    required this.isActive,
    required this.expanded,
    required this.onToggle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool showLabels;
  final bool isActive;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parentTile = _SidebarInkItem(
      label: label,
      selected: isActive,
      onTap: onTap,
      excludeChildSemantics: false,
      padding: EdgeInsets.symmetric(horizontal: showLabels ? 14 : 0),
      child: showLabels
          ? Row(
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        fontSize: AppTypography.labelSize,
                      ),
                    ),
                  ),
                ),
                if (isActive)
                  _SidebarGroupToggle(expanded: expanded, onToggle: onToggle),
              ],
            )
          : Center(child: Icon(icon, size: 22, color: Colors.white)),
    );
    return showLabels ? parentTile : Tooltip(message: label, child: parentTile);
  }
}

class _LessonPlatformSidebarGroup extends StatelessWidget {
  const _LessonPlatformSidebarGroup({
    required this.label,
    required this.showLabels,
    required this.expanded,
    required this.isOnLessonPlatform,
    required this.onToggle,
    required this.onParentTap,
    required this.onSectionSelected,
    this.selectedSection,
  });

  final String label;
  final bool showLabels;
  final bool expanded;
  final bool isOnLessonPlatform;
  final LessonPlatformSidebarSection? selectedSection;
  final VoidCallback onToggle;
  final VoidCallback onParentTap;
  final ValueChanged<LessonPlatformSidebarSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final sections = lessonPlatformSidebarMenuOrder;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarGroupParent(
            icon: Icons.auto_stories_rounded,
            label: label,
            showLabels: showLabels,
            isActive: isOnLessonPlatform,
            expanded: expanded,
            onToggle: onToggle,
            onTap: onParentTap,
          ),
          if (isOnLessonPlatform && expanded && showLabels)
            ...sections.map((section) {
              return _SidebarSubItem(
                icon: section.icon,
                label: section.label(strings),
                selected: selectedSection == section,
                onTap: () => onSectionSelected(section),
              );
            }),
        ],
      ),
    );
  }
}

class _AcademicPlansSidebarGroup extends StatelessWidget {
  const _AcademicPlansSidebarGroup({
    required this.label,
    required this.showLabels,
    required this.expanded,
    required this.isOnAcademicPlans,
    required this.onToggle,
    required this.onParentTap,
    required this.onSectionSelected,
    this.selectedSection,
  });

  final String label;
  final bool showLabels;
  final bool expanded;
  final bool isOnAcademicPlans;
  final AcademicPlansSidebarSection? selectedSection;
  final VoidCallback onToggle;
  final VoidCallback onParentTap;
  final ValueChanged<AcademicPlansSidebarSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final sections = academicPlansSidebarMenuOrder;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarGroupParent(
            icon: Icons.event_note_rounded,
            label: label,
            showLabels: showLabels,
            isActive: isOnAcademicPlans,
            expanded: expanded,
            onToggle: onToggle,
            onTap: onParentTap,
          ),
          if (isOnAcademicPlans && expanded && showLabels)
            ...sections.map((section) {
              return _SidebarSubItem(
                icon: section.icon,
                label: section.label(strings),
                selected: selectedSection == section,
                onTap: () => onSectionSelected(section),
              );
            }),
        ],
      ),
    );
  }
}

class _TeacherNavTabBar extends StatelessWidget {
  const _TeacherNavTabBar();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    if (!state.isTeacher || state.openTeacherTabs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        border: Border(bottom: BorderSide(color: context.tokens.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final section in state.openTeacherTabs)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _TeacherNavTabChip(
                  label: section.title(strings),
                  selected: state.activeTeacherTab == section,
                  onSelect: () => state.activateTeacherTab(section),
                  onClose: state.openTeacherTabs.length > 1
                      ? () => state.closeTeacherTab(section)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeacherNavTabChip extends StatelessWidget {
  const _TeacherNavTabChip({
    required this.label,
    required this.selected,
    required this.onSelect,
    this.onClose,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      container: true,
      child: Material(
        color: selected
            ? tokens.primary.withValues(alpha: 0.12)
            : tokens.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            selected ? tokens.primary : tokens.textSecondary,
                      ),
                ),
                if (onClose != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: selected ? tokens.primary : tokens.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
