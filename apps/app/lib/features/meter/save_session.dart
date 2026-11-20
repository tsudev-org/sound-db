import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

/// Hỏi nhãn rồi lưu phiên hiện tại vào kho cục bộ; đã đăng nhập thì đồng bộ.
Future<void> saveCurrentSession(BuildContext context) async {
  final services = AppScope.of(context);
  final l = context.l10n;
  final controller = TextEditingController(text: l.defaultSessionLabel(formatDateTime(DateTime.now())));
  final label = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.saveSession),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 120,
        decoration: InputDecoration(labelText: l.sessionName),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(l.save)),
      ],
    ),
  );
  if (label == null || !context.mounted) return;
  final session = services.measurement.buildSession(
    label: label.isEmpty ? l.sessionFallback : label,
    deviceModel: services.deviceModel,
  );
  if (session == null) {
    showMessage(context, l.sessionTooShort);
    return;
  }
  await services.store.saveSession(session);
  if (!context.mounted) return;
  showMessage(context, l.savedLabel(session.label));
  await services.sync.syncNow(onlyIfAuto: true);
}
