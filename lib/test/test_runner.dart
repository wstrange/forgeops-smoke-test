import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:forgeops_smoke_test/rest/idm_rest.dart';
import 'test_configuration.dart';
import '../rest/am_rest.dart';
import '../rest/idm_rest.dart';

typedef TestFunction = Future<void> Function();

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

class TestRunner {
  final TestConfiguration _config;
  AMRest am;
  IDMRest idm;
  final List<TestResult> _results = [];
  final DateTime _startedAt;

  List<TestResult> get testResults => _results;
  TestConfiguration get config => _config;

  // Get results suitable for slack message
  String getPrettyResults() {
    var s = StringBuffer('Smoke Test for ${_config.fqdn}\n');
    _results.forEach((r) {
      s.write('$r\n');
    });
    return s.toString();
  }


  // return test results as json
  Map<String, dynamic> toJson() {
    return {
      'fqdn': _config.fqdn,
      'startedAt': _startedAt.toIso8601String(),
      'runTime': DateTime.now().difference(_startedAt).inMilliseconds,
      'results:': _results.map((r) => r.toJson()).toList()
    };
  }

  TestRunner(this._config): _startedAt = DateTime.now() {
    // create the rest API clients for testing
    am = AMRest(_config);
    idm = IDMRest(_config, am);
  }

  Future<void> test(String test, TestFunction testFun) async {
    var _start = DateTime.now();
    try {
      await testFun();
    } on DioError catch (e) {
      var msg = '';
      if( e.response != null ) {
        msg = '${e.response.statusCode} ${e.response.statusMessage} ${e.response.data} ${e.response.headers}';
      }
      else  {
        msg = '${e.request} ${e.message}';
      }
      _results.add(TestResult(test, 'FAIL $msg ', false, _testTime(_start)));
      rethrow;
    }
    _results.add(TestResult(test, 'ok', true, _testTime(_start)));
  }

  int _testTime(DateTime start) =>
      DateTime.now().millisecondsSinceEpoch - start.millisecondsSinceEpoch;

  void expect(bool condition, {String message = ''}) {
    if (!condition) {
      throw Exception('FAIL $message');
    }
  }

  Future<void> close() async {
    am.close();
    idm.close();
  }
}
