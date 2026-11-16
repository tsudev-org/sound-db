import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/format.dart';
import '../../widgets/common.dart';

/// Hỏi nhãn rồi lưu phiên hiện tại vào kho cục bộ; đã đăng nhập thì đồng bộ.
Future<void> saveCurrentSession(BuildContext context) async {
  final services = AppScope.of(context);
  final controller = TextEditingController(text: 'Phiên đo ${formatDateTime(DateTime.now())}');
  final label = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Lưu phiên đo'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 120,
        decoration: const InputDecoration(labelText: 'Tên phiên'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Lưu')),
      ],
    ),
  );
  if (label == null || !context.mounted) return;
  final session = services.measurement.buildSession(
    label: label.isEmpty ? 'Phiên đo' : label,
    deviceModel: services.deviceModel,
  );
  if (session == null) {
    showMessage(context, 'Phiên quá ngắn để lưu (cần ít nhất 1 giây).');
    return;
  }
  await services.store.saveSession(session);
  if (!context.mounted) return;
  showMessage(context, 'Đã lưu "${session.label}".');
  await services.sync.syncNow(onlyIfAuto: true);
}
