import 'package:dio/dio.dart';
import 'package:forgeops_smoke_test/forgerock_smoke_test.dart';
import 'am_rest.dart';

// A Client that makes IDM REST calls
// See https://backstage.forgerock.com/docs/idm/6.5/integrators-guide/#appendix-rest
class IDMRest {
  final AMRest _amRest;
  final String _adminClientId = 'idm-admin-ui'; // id of the idm admin client
  final Dio _dio;
  String _accessToken;
  final TestConfiguration _config;

  String get _fqdn => _config.fqdn;

  IDMRest(this._config, this._amRest) : _dio = Dio() {

   if( _config.debug ) {
        LogInterceptor(responseBody: true, requestBody: true, request: true);
    }
  }

  String get oauth2redirectUrl => '$_fqdn/admin/appAuthHelperRedirect.html';

  // Get a bearer token for accessing the /openidm admin ui
  // We need to authenticate as amadmin to AM first
  Future<String> getBearerToken() async {
    _accessToken = await _amRest.authCodeFlow(
        redirectUrl: oauth2redirectUrl,
        client_id: _adminClientId,
        scopes: ['openid']);

    // set the dio base options for the bearer token
    // this wil add the bearer token to all future requests.
    _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
    return _accessToken;
  }

  // Discussion with Jake: Any oauth2 client can be used. Doesnt matter
  // What matters is the Subject (sub:) in the token. Must be mapped to an admin
  // user (in IDM - authentication.json / access.json)
  //
  // Get an access token for the idm API. As a side effect of this call
  // we add the access token to future REST requests.
  // NOT USED RIGHT NOW. We use amadmin to get a token
//  Future<String> _getAccessToken() async {
//    _accessToken =
//        await _amRest.getOAuth2Token(_adminClientId, _adminClientPassword);
//    _dio.options.headers = {'Authorization': 'Bearer $_accessToken'};
//    return _accessToken;
//  }

  // Create a user - return the id
  Future<String> createUser(String id) async {
    var r = await _dio.post('$_fqdn/openidm/managed/user?_action=create',
        data: _userTemplate(id));
    if (r.statusCode == 201) {
      return r.data['_id'];
    } else {
      throw Exception('Cant create user ${r.statusCode} ${r.statusMessage}');
    }
  }

  Options ifMatch = Options(headers: {'if-match': '*'});

  Future<String> deleteUser(String id) async {
    var r =
        await _dio.delete('$_fqdn/openidm/managed/user/$id', options: ifMatch);
    return r.statusMessage;
  }

  // Look up the user and return the _id
  Future<String> queryUser(String userName) async {
    var q = {'userName': userName, '_queryFilter': 'userName eq "$userName"'};
    var r = await _dio.get('$_fqdn/openidm/managed/user', queryParameters: q);
    var payload = r.data;
    // extract the uuid
    if( payload == null || payload['resultCount'] == 0 ) {
      return null;
    }
    return payload['result'].first['_id'];
  }

  Future<String> modifyUser(String id) async {
    var p = [
      {'operation': 'replace', 'field': '/sn', 'value': 'Updated-SN'}
    ];
    var r = await _dio.patch('$_fqdn/openidm/managed/user/$id',
        options: ifMatch, data: p);
    return r.statusMessage;
  }

  Map<String, String> _userTemplate(String id) => {
        'userName': '$id',
        'givenName': '$id',
        'sn': '$id',
        'mail': '$id@test.com',
        'password': TestConfiguration.TEST_PASSWORD,
      };

  void close() => _dio.close();
}
