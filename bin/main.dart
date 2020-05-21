import 'package:forgerock_smoke_test/forgerock_smoke_test.dart';

String testJson = '''
{
  "fqdn": "https://smoke.iam.forgeops.com",
  "amadminPassword": "mga58ga7javrhaheeddzcewy1dohu4ox"
}
''';

/// This can be used to manually run the test suite
/// edit the parameters above, and run "dart bin/main.dart"
void main() async {
  var cfg = TestConfiguration.fromJson(testJson);
  var test = SmokeTest(cfg);

  await test.runSmokeTest();

  print('test results= ${test.testResults}');

  await test.close();
}