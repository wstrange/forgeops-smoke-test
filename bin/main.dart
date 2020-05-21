import 'package:forgeops_smoke_test/forgerock_smoke_test.dart';

String testJson = '''
{
  "fqdn": "https://xxnightly.iam.forgeops.com",
  "amadminPassword": "6pbdxhe0xyvhvs1ppo99beqiyzgq4wh1"
}
''';

var url = 'https://hooks.slack.com/services/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';

/// This can be used to manually run the test suite
/// edit the parameters above, and run "dart bin/main.dart"
void main() async {
  var cfg = TestConfiguration.fromJson(testJson);
  var test = SmokeTest(cfg);

  try {
    await test.runSmokeTest();
    await sendSlackUpdate(url,test.getPrettyResults());
  }
  catch(e) {
    await sendSlackUpdate(url,'FAILED! ${test.getPrettyResults()}', showFailIcon: true );
  }

  print('test results= ${test.testResults}');


  await test.close();
}