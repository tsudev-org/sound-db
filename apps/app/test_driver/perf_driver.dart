import 'package:integration_test/integration_test_driver.dart';

/// Ghi `build/<reportKey>.json` cho từng khối watchPerformance của integration_test/perf_test.dart.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    for (final e in data.entries) {
      await writeResponseData(e.value as Map<String, dynamic>, testOutputFilename: e.key);
    }
  },
);
