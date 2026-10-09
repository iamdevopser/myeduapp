import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/parent_guardian_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_state.dart';
import '../../../services/account_service.dart';
import '../../../services/secretary_parent_service.dart';
import '../../../services/secretary_student_service.dart';
import '../../../utils/course_form_options.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/email_validation.dart';
import '../../../utils/parent_relation_labels.dart';
import 'secretary_slide_panel.dart';

Future<bool> showSecretaryParentFormPanel(BuildContext context) async {
  final strings = AppLocalizations.of(context);
  final result = await showSecretaryEndPanel<bool>(
    context: context,
    title: strings.t('secretaryParentAdd'),
    child: SecretaryParentForm(
      onSaved: () {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop(true);
      },
    ),
  );
  return result == true;
}

class SecretaryParentForm extends StatefulWidget {
  const SecretaryParentForm({super.key, required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<SecretaryParentForm> createState() => _SecretaryParentFormState();
}

class _SecretaryParentFormState extends State<SecretaryParentForm> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _portalUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  int? _linkStudentId;
  ParentRelationType _relation = ParentRelationType.anne;
  bool _primaryContact = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _portalUsernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final parentService = SecretaryParentService(context.read<AppState>().db);
    final studentService = SecretaryStudentService(context.read<AppState>().db);

    return FutureBuilder<List<Map<String, Object?>>>(
      future: studentService.listStudents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final students = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.t('secretaryParentRegistrationHint'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Text(
              strings.t('secretaryParentSectionContact'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: strings.t('parentFullName'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: strings.t('parentPhone'),
                helperText: strings.t('secretaryParentPhoneOptional'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: strings.t('parentEmail'),
                helperText: strings.t('secretaryParentEmailHint'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: strings.t('parentAddress'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: strings.t('parentNotes')),
            ),
            const SizedBox(height: 24),
            Text(
              strings.t('secretaryParentSectionStudentLink'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.t('secretaryParentLinkStudentHint'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            if (students.isEmpty)
              Text(strings.t('noStudents'))
            else ...[
              DropdownButtonFormField<int?>(
                isExpanded: true,
                value: _linkStudentId,
                decoration: InputDecoration(
                  labelText: strings.t('secretaryParentLinkStudentLabel'),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(strings.t('secretaryParentLinkStudentNone')),
                  ),
                  ...students.map((row) {
                    final id = row['id'] as int;
                    final grade = CourseFormOptions.resolveGrade(
                      row['sinif_ad'] as String?,
                    );
                    final section = CourseFormOptions.resolveSection(
                      row['sinif_sube'] as String?,
                    );
                    final label =
                        '${row['numara']} — ${row['ad_soyad']} · '
                        '${CourseFormOptions.gradeLabel(grade)} $section';
                    return DropdownMenuItem(
                      value: id,
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _linkStudentId = v),
              ),
              if (_linkStudentId != null) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<ParentRelationType>(
                  isExpanded: true,
                  value: _relation,
                  decoration: InputDecoration(
                    labelText: strings.t('parentRelationType'),
                  ),
                  items: ParentRelationType.values
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.label(strings)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _relation = v);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.t('secretaryParentPrimaryContact')),
                  subtitle: Text(
                    strings.t('secretaryParentPrimaryContactHint'),
                  ),
                  value: _primaryContact,
                  onChanged: (v) => setState(() => _primaryContact = v),
                ),
              ],
            ],
            const SizedBox(height: 24),
            Text(
              strings.t('secretaryParentSectionPortal'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.t('secretaryParentPortalHint'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portalUsernameController,
              decoration: InputDecoration(
                labelText: strings.t('secretaryParentPortalUsername'),
                helperText: strings.t('secretaryParentPortalUsernameHint'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: strings.t('studentPortalPassword'),
                helperText: strings.t('secretaryParentPortalPasswordHint'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordConfirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: strings.t('studentPortalPasswordConfirm'),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saving
                  ? null
                  : () => _save(context, parentService, strings),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.t('secretaryParentAdd')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save(
    BuildContext context,
    SecretaryParentService parentService,
    AppLocalizations strings,
  ) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final emailRaw = _emailController.text.trim();
    if (emailRaw.isNotEmpty && !isValidEmail(emailRaw)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.t('invalidEmail'))));
      return;
    }

    final portalUsername = _portalUsernameController.text.trim();
    final wantsPortal = portalUsername.isNotEmpty;
    if (wantsPortal) {
      final password = _passwordController.text;
      final confirm = _passwordConfirmController.text;
      if (password.isEmpty || password != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('studentPortalPasswordMismatch'))),
        );
        return;
      }
    }

    setState(() => _saving = true);
    final db = context.read<AppState>().db;
    try {
      final parentId = await parentService.createParent(
        fullName: name,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: emailRaw.isEmpty ? null : emailRaw,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_linkStudentId != null) {
        await parentService.linkToStudent(
          studentId: _linkStudentId!,
          parentId: parentId,
          relation: _relation,
          isPrimary: _primaryContact,
        );
      }

      if (wantsPortal) {
        await AccountService(db, actorAccountId: 0).createParentPortalAccount(
          parentId: parentId,
          username: portalUsername,
          fullName: name,
          passwordPlain: _passwordController.text,
          email: emailRaw.isEmpty ? null : emailRaw,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('secretaryParentSaved'))),
      );
      widget.onSaved();
    } on AccountValidationException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.t(e.messageKey))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
