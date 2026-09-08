import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// Bestätigungsdialog für die Konto-Löschung (DSGVO, siehe
/// ROADMAP_QuizApp.md Abschnitt 18i). Der „Endgültig löschen"-Knopf ist
/// gesperrt, bis der Nutzer das Bestätigungswort eintippt - die Aktion ist
/// unwiderruflich. Gibt beim Schließen `true` zurück, wenn bestätigt wurde.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  String get _keyword => S.t('delete_account_keyword');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.t('delete_account_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.t('delete_account_dialog_body')),
          const SizedBox(height: 8),
          Text(
            S.f('delete_account_dialog_prompt', [_keyword]),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(hintText: _keyword),
            onChanged: (v) =>
                setState(() => _matches = v.trim().toUpperCase() == _keyword.toUpperCase()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(S.t('delete_account_cancel')),
        ),
        TextButton(
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.signalRed),
          child: Text(S.t('delete_account_confirm')),
        ),
      ],
    );
  }
}
