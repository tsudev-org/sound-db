import 'package:flutter/material.dart';
import 'package:tsudev_ui/tsudev_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_scope.dart';
import '../core/format.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import 'pro_service.dart';

/// Giá TsuDEV Pro trên web (VNĐ đã gồm thuế, PRODUCT_POLICY 7.2). Bản cửa hàng hiện giá cửa hàng trả về.
const proPriceVnd = '490.000 ₫';

/// Điều khoản đứng TRƯỚC nút mua - NGUYÊN VĂN PRODUCT_POLICY mục 7.5 (test so với `.standards`).
String proTerms(String price, {bool english = false}) => english
    ? 'TsuDEV Pro $price for 1 year, does NOT renew automatically. Renewing early adds 1 year to your remaining '
        'time. If it expires without renewal, the app returns to the free version and stops syncing to the cloud; data on your '
        'device stays intact, and your cloud copy can be downloaded for 90 days before it is deleted.'
    : 'TsuDEV Pro $price cho 1 năm, KHÔNG tự gia hạn. Gia hạn sớm được cộng thêm 1 năm vào thời hạn còn lại. Hết hạn mà '
        'chưa gia hạn, ứng dụng trở về bản miễn phí và ngừng đồng bộ lên đám mây; dữ liệu trên thiết bị vẫn giữ nguyên, bản sao '
        'trên đám mây còn tải về được 90 ngày rồi bị xoá.';

String _date(DateTime d) => formatDate(d.toLocal());

/// Màn Pro / Ủng hộ (PRODUCT_POLICY 3.3, 7.2, 7.5). Ngoài cửa hàng ⇒ mua trên tsudev.com (không nhúng thanh toán vào
/// app). Bản Play ⇒ không dẫn ra web (Play Billing nối sau, B2).
class ProPage extends StatelessWidget {
  const ProPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final pro = services.pro;
    final p = context.palette;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: const Text('TsuDEV Pro')),
      body: ListenableBuilder(
        listenable: pro,
        builder: (context, _) {
          final until = pro.proUntil;
          final active = pro.isPro;
          return ListView(padding: const EdgeInsets.all(SdbSpacing.s4), children: [
            Row(children: [
              Expanded(child: Text(l.proStatus, style: const TextStyle(fontWeight: FontWeight.w600))),
              TsuBadge(kind: pro.state.badge),
            ]),
            const SizedBox(height: SdbSpacing.s2),
            Text(
              active
                  ? l.proActiveLine(_date(until!))
                  : until != null && until.millisecondsSinceEpoch > 0
                      ? l.proExpiredLine(_date(until), _date(until.add(const Duration(days: 90))))
                      : l.proFreeLine,
              style: TextStyle(color: p.textSecondary),
            ),
            const SizedBox(height: SdbSpacing.s6),
            Text(l.proFeaturesTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: SdbSpacing.s2),
            Text(l.proFeatures),
            const SizedBox(height: SdbSpacing.s6),
            Text(proTerms(proPriceVnd, english: l.localeName == 'en'), key: const Key('pro-terms'), style: TextStyle(color: p.textSecondary, fontSize: 13)),
            const SizedBox(height: SdbSpacing.s4),
            if (isPlayBuild)
              Text(l.proPlaySoon, style: TextStyle(color: p.textMuted))
            else ...[
              FilledButton.icon(
                key: const Key('pro-buy'),
                onPressed: () => launchUrl(proBuyUrl, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(active ? l.proRenewWeb : l.proBuyWeb),
              ),
              const SizedBox(height: SdbSpacing.s2),
              OutlinedButton.icon(
                onPressed: () => launchUrl(donateUrl, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.favorite_outline),
                label: Text(l.supportTsudev),
              ),
              const SizedBox(height: SdbSpacing.s2),
              Text(l.proPayNote,
                  style: TextStyle(color: p.textMuted, fontSize: 12)),
            ],
            const SizedBox(height: SdbSpacing.s4),
            if (services.auth.signedIn)
              TextButton.icon(
                onPressed: () => pro.refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(l.proCheckAgain),
              ),
          ]);
        },
      ),
    );
  }
}
