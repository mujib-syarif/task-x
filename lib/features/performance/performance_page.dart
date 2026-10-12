import 'package:flutter/material.dart';

import '../../core/services/metrics_service.dart';
import '../../core/services/services.dart';
import 'tabs/battery_tab.dart';
import 'tabs/cpu_tab.dart';
import 'tabs/network_tab.dart';
import 'tabs/ram_tab.dart';
import 'tabs/storage_tab.dart';

enum PerfTab { cpu, ram, storage, battery, network }

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key, this.initialTab = PerfTab.cpu});

  final PerfTab initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: PerfTab.values.length,
      initialIndex: initialTab.index,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Performance Monitor'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'CPU'),
              Tab(text: 'RAM'),
              Tab(text: 'Penyimpanan'),
              Tab(text: 'Baterai'),
              Tab(text: 'Jaringan'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: ValueListenableBuilder<MetricsSnapshot?>(
            valueListenable: Services.metrics.snapshot,
            builder: (context, snap, _) {
              return TabBarView(
                children: [
                  CpuTab(snap: snap),
                  RamTab(snap: snap),
                  StorageTab(snap: snap),
                  BatteryTab(snap: snap),
                  NetworkTab(snap: snap),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
