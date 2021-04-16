import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:forgeops_smoke_test/rest/end_user_rest.dart';
import 'package:forgeops_smoke_test/rest/idm_rest.dart';
import 'test_configuration.dart';
import '../rest/am_rest.dart';
import '../rest/idm_rest.dart';

typedef TestFunction = Future<void> Function();

// Records a Test Result
class TestResult {
  String test;
  String message;
  bool passed;
  int testTimeMsec;
  TestResult(this.test, this.message, this.passed, this.testTimeMsec);

  Map<String, Object> toJson() =>
      {'test': test, 'message': message, 'time': testTimeMsec};

  String toJsonString() =>  json.encode(toJson());

  @override
  String toString() => toJsonString();
}


// Provides Framework for running tests.
// loosely modeled on Dart's test framework
class TestRunner {
  // after this many failures, halt the test
  static final NUM_FAILED_ALLOWED = 1;
  final TestConfiguration _config;
  AMRest amClient;
  late IDMRest idmClient;
  EndUserREST endUserClient;
  final List<TestResult> _results = [];
  final DateTime _startedAt;
  int _failed = 0; // count of failed tests
  int get failed => _failed;

  List<TestResult> get testResults => _results;
  TestConfiguration get config => _config;

  TestRunner(this._config): _startedAt = DateTime.now(),
        endUserClient = EndUserREST(_config),
        amClient = AMRest(_config)
  {
    // create the rest API clients for testing
    idmClient = IDMRest(_config, amClient);
  }

  // Get results suitable for slack message
  String getPrettyResults() {
    var s = StringBuffer('Smoke Test results for target ${_config.fqdn}\n');
    _results.forEach((r) {
      s.write('$r\n');
    });
    if( _failed > 0) {
      s.write('Number of failed tests: $_failed');
    }
    return s.toString();
  }


  // return test results as json
  Map<String, dynamic> toJson() {
    return {
      'fqdn': _config.fqdn,
      'startedAt': _startedAt.toIso8601String(),
      'runTime': DateTime.now().difference(_startedAt).inMilliseconds,
      'results:': _results.map((r) => r.toJson()).toList(),
      'numberFailedTests' : _failed
    };
  }

  /// Run a test provided as a closure.
  Future<void> test(String test, TestFunction testFun) async {
    var _start = DateTime.now();
    var msg = 'ok';
    try {
      await testFun();
      _results.add(TestResult(test, msg, true, _testTime(_start)));
    } on DioError catch (e) {
      if( e.response != null ) {
        msg = '${e.response?.statusCode} ${e.response?.statusMessage}}';
      }
      else  {
        msg = '${e.request} ${e.message}';
      }
      ++_failed;
      _results.add(TestResult(test, 'ERROR $msg ', false, _testTime(_start)));
      //rethrow;
    }
    catch(e) {
      ++_failed;
      msg = 'Exception $e';
    }

    // This is added to fail fast..
    if( _failed > NUM_FAILED_ALLOWED) {
      throw Exception('Test halted due to failures');
    }

  }

  int _testTime(DateTime start) =>
      DateTime.now().millisecondsSinceEpoch - start.millisecondsSinceEpoch;

  void expect(bool condition, {String message = ''}) {
    if (!condition) {
      throw Exception('FAIL $message');
    }
  }

  Future<void> close() async {
    amClient.close();
    idmClient.close();
  }
}
