import 'package:flutter/material.dart';

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
          title: const Text('Công cụ'),
          actions: const [RunButton()],
          bottom: const TabBar(tabs: [Tab(text: 'Tần số & cao độ'), Tab(text: 'Phát tín hiệu')]),
        ),
        body: const TabBarView(children: [TunerTab(), GeneratorTab()]),
      ),
    );
  }
}
