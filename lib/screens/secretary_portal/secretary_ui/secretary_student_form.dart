import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/app_state.dart';
import '../../../services/account_service.dart';
import '../../../services/secretary_student_service.dart';
import '../../../utils/course_form_options.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/student_password_hash.dart';
import 'secretary_slide_panel.dart';

Future<bool> showSecretaryStudentFormPanel(BuildContext context) async {
  final strings = AppLocalizations.of(context);
  final result = await showSecretaryEndPanel<bool>(
    context: context,
    title: strings.t('secretaryStudentAdd'),
    child: SecretaryStudentForm(
      onSaved: () {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop(true);
      },
    ),
  );
  return result == true;
}

class SecretaryStudentForm extends StatefulWidget {
  const SecretaryStudentForm({super.key, required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<SecretaryStudentForm> createState() => _SecretaryStudentFormState();
}

class _SecretaryStudentFormState extends State<SecretaryStudentForm> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _emailController = TextEditingController();
  final _portalUsernameController = TextEditingController();
  final _passwordController = TextEditingController(
    text: StudentPasswordHash.defaultPortalPassword,
  );
  final _passwordConfirmController = TextEditingController(
    text: StudentPasswordHash.defaultPortalPassword,
  );
  int? _classId;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _emailController.dispose();
    _portalUsernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final service = SecretaryStudentService(context.read<AppState>().db);

    return FutureBuilder<List<Map<String, Object?>>>(
      future: service.listStudentClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final classes = snapshot.data ?? [];
        if (_classId == null && classes.isNotEmpty) {
          _classId = classes.first['id'] as int;
        }
        if (classes.isEmpty) {
          return Text(strings.t('noStudentClasses'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.t('secretaryStudentRegistrationHint'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              isExpanded: true,
              value: _classId,
              decoration: InputDecoration(
                labelText: strings.t('studentClassName'),
              ),
              items: classes.map((row) {
                final id = row['id'] as int;
                final label = CourseFormOptions.studentClassGradeSectionLabel(
                  row['ad'] as String? ?? '',
                  section: row['sube'] as String?,
                );
                return DropdownMenuItem(value: id, child: Text(label));
              }).toList(),
              onChanged: (v) => setState(() => _classId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: strings.t('studentName')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings.t('studentNumber'),
                helperText: strings.t('secretaryStudentNumberOptional'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: strings.t('studentEmail')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portalUsernameController,
              decoration: InputDecoration(
                labelText: strings.t('secretaryStudentPortalUsername'),
                helperText: strings.t('secretaryStudentPortalUsernameHint'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: strings.t('studentPortalPassword'),
                helperText: strings.t('secretaryStudentPortalPasswordHint'),
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
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
              ),
              onPressed: _saving || _classId == null
                  ? null
                  : () => _save(context, service, strings),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(strings.t('addStudent')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save(
    BuildContext context,
    SecretaryStudentService service,
    AppLocalizations strings,
  ) async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _classId == null) return;
    final numberText = _numberController.text.trim();
    final number = numberText.isEmpty ? null : int.tryParse(numberText);
    if (numberText.isNotEmpty && number == null) return;
    final password = _passwordController.text;
    final confirm = _passwordConfirmController.text;
    if (password.isEmpty || password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('studentPortalPasswordMismatch'))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final email = _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim();
      await service.validateStudentPortalAccount(
        portalUsername: _portalUsernameController.text,
        email: email,
      );
      final studentId = await service.createStudent(
        classId: _classId!,
        name: name,
        number: number,
        email: email,
        passwordPlain: password,
      );
      await service.createStudentPortalAccountIfNeeded(
        studentId: studentId,
        name: name,
        passwordPlain: password,
        portalUsername: _portalUsernameController.text,
        email: email,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('secretaryStudentSaved'))),
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
