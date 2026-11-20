import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import 'generator_tab.dart';
import 'tuner_tab.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.toolsTitle),
          actions: const [RunButton()],
          bottom: TabBar(tabs: [Tab(text: context.l10n.tabPitch), Tab(text: context.l10n.tabGenerator)]),
        ),
        body: const TabBarView(children: [TunerTab(), GeneratorTab()]),
      ),
    );
  }
}
