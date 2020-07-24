import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:forgeops_smoke_test/forgerock_smoke_test.dart';

abstract class RESTClient {
  final Dio _dio;
  final TestConfiguration testConfig;
  final _cookieJar = CookieJar();

  Dio get dio => _dio;

  RESTClient(this.testConfig) : _dio = Dio() {
    // The cookie manager saves cookies such as iPlanetPro, and then
    // sends back them on future requests.
    _dio.interceptors.add(CookieManager(_cookieJar));
    if (testConfig.debug) {
      _dio.interceptors.add(LogInterceptor(responseBody: true));
    }
    clearCookies();
  }

  // This is a work around for Dio cookie manager - which uses static storage
  // for cookies. https://github.com/flutterchina/cookie_jar/issues/22
  void clearCookies() {
    (_cookieJar as DefaultCookieJar).deleteAll();
  }

  void check200(Response r) {
    if (r.statusCode != 200) {
      throw Exception('Response error=${r.statusCode} msg=${r.statusMessage}');
    }
  }

  void close() => dio.close();


}
