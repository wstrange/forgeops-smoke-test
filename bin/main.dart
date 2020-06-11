import 'dart:io';

import 'package:forgeops_smoke_test/forgerock_smoke_test.dart';
//
//For testing, create a test.json file:
//
//{
//"fqdn": "https://smoke.iam.forgeops.com",
//"amadminPassword": "enter-password-here",
//"debug": true
//}


/// This can be used to manually run the test suite
/// edit the parameters above, and run "dart bin/main.dart"
void main() async {

  var slack = Platform.environment['SLACK_URL'];
  var testJson = File('test.json').readAsStringSync();

  var cfg = TestConfiguration.fromJson(testJson);
  var test = SmokeTest(cfg);

  try {
    await test.runSmokeTest();
    //await sendSlackUpdate(slack,test.getPrettyResults());
  }
  catch(e) {
    //await sendSlackUpdate(slack,'FAILED! ${test.getPrettyResults()}', showFailIcon: true );
  }

  print(test.getPrettyResults());


  await test.close();
}