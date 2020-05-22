import 'dart:io';

import 'package:forgeops_smoke_test/forgerock_smoke_test.dart';

String testJson = '''
{
  "fqdn": "https://xxnightly.iam.forgeops.com",
  "amadminPassword": "6pbdxhe0xyvhvs1ppo99beqiyzgq4wh1"
}
''';

/// This can be used to manually run the test suite
/// edit the parameters above, and run "dart bin/main.dart"
void main() async {

  var slack = Platform.environment['SLACK_URL'];

  var cfg = TestConfiguration.fromJson(testJson);
  var test = SmokeTest(cfg);

  try {
    await test.runSmokeTest();
    await sendSlackUpdate(url,test.getPrettyResults());
  }
  catch(e) {
    await sendSlackUpdate(slack,'FAILED! ${test.getPrettyResults()}', showFailIcon: true );
  }

  print('test results= ${test.testResults}');


  await test.close();
}