import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'dart:convert';

// Make REST calls to ForgeRock AM.
class AMRest {
  final String _amUrl;
  String _amCookie;
  final String _adminPassword;
  CookieJar _cookieJar;
  final Dio _dio;

  AMRest(String fqdn, this._adminPassword)
      : _dio = Dio(),
        _amUrl = '$fqdn/am' {
    _cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(_cookieJar));
    // Uncomment if you want to view requests
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  Future<String> authenticateAsAdmin() async {
    var headers = {
      'X-OpenAM-Username': 'amadmin',
      'X-OpenAM-Password': _adminPassword,
      'Accept-API-Version': 'resource=2.1, protocol=1.0'
    };

    var r = await _dio.post(
        '$_amUrl/json/realms/root/authenticate?authIndexType=service&authIndexValue=adminconsoleservice',
        options: RequestOptions(
            headers: headers, contentType: Headers.jsonContentType));
    _amCookie = r.data['tokenId'];
    return _amCookie;
  }

  // regex used to extract code= from the location header.
  final _codeRegex = RegExp(r'(?<=code=)(.+?)(?=&)');

  // Perform the auth code oauth2 flow to get an access token
  // this is done as the user amadmin - so we get an access
  // token that can be used for IDM.
  Future<String> authCodeFlow(
      {String redirectUrl, String client_id, List<String> scopes}) async {
    if (_amCookie != null) {
      await authenticateAsAdmin();
    }
    var headers = {'accept-api-version': 'resource=2.1'};
    var params = {
      'redirect_uri': redirectUrl,
      'client_id': client_id,
      'response_type': 'code',
      'scope': 'openid', // todo: fix scopes
    };
    var options = Options(
        headers: headers,
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (status) => status < 500);
    var r = await _dio.post('$_amUrl/oauth2/authorize',
        options: options,
        queryParameters: params,
        data: {'decision': 'Allow', 'csrf': _amCookie});
    var loc_header = r.headers.value('location');
    var auth_code = _codeRegex.firstMatch(loc_header).group(0);

    var data = {
      'grant_type': 'authorization_code',
      'code': auth_code,
      'redirect_uri': redirectUrl,
      'client_id': client_id
    };

    options = Options(
        headers: {
          'Accept-API-Version': 'resource=2.0, protocol=1.0',
        },
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (status) => status < 500);

    var r2 = await _dio.post('$_amUrl/oauth2/access_token',
        data: data, options: options);
    return r2.data['access_token'];
  }

  /// Client Credential flow to get an oauth2 token
  Future<String> getOAuth2Token(String clientId, String clientPassword) async {
    var auth =
        'Basic ' + base64Encode(utf8.encode('$clientId:$clientPassword'));

    var options = Options(headers: {
      'Authorization': auth,
    }, contentType: Headers.formUrlEncodedContentType);

    var r = await _dio.post('$_amUrl/oauth2/access_token',
        data: {'grant_type': 'client_credentials'}, options: options);

    return r.data['access_token'];
  }

  Future<String> getOAuth2TokenResourceOwnerFlow(
      String clientId, String clientPassword,
      [String user = 'amadmin', String password]) async {
    var auth =
        'Basic ' + base64Encode(utf8.encode('$clientId:$clientPassword'));

    var options = Options(headers: {
      'Authorization': auth,
    }, contentType: Headers.formUrlEncodedContentType);

    var r = await _dio.post('$_amUrl/oauth2/access_token',
        data: {'grant_type': 'client_credentials'}, options: options);

    return r.data['access_token'];
  }

  // Register an oauth2 client. [token] is an oauth2 access token
  // that has the scope dynamic_client_registration assigned.
  // https://backstage.forgerock.com/docs/am/6.5/oauth2-guide/#register-oauth2-client-dynamic-access-token-example
  // https://openid.net/specs/openid-connect-core-1_0-17.html#codeExample
  Future<Map<String, Object>> registerOAuthClient(String token) async {
    var options = Options(headers: {'Authorization': 'Bearer $token'});
    var r = await _dio.post('$_amUrl/oauth2/register',
        data: {
          'redirect_uris': ['https://fake.com'],
          'client name': 'Test Client',
          'client_uri': 'https://fake.com',
          'scopes': ['profile', 'openid'],
          'response_types': ['code', 'id_token', 'token'],
        },
        options: options);
    return r.data as Map<String, Object>;
  }

  void close() => _dio.close();
}
