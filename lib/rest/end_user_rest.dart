import 'package:forgeops_smoke_test/forgerock_smoke_test.dart';
import 'package:forgeops_smoke_test/rest/rest_client.dart';

// A Client that makes end user UI requests
//
class EndUserREST extends RESTClient {

  String get _fqdn => testConfig.fqdn;

  EndUserREST(TestConfiguration c) : super(c);

  // first Post:
  // curl 'https://nightly.iam.forgeops.com/am/json/realms/root/authenticate' \
  //  -X 'POST' \
  //  -H 'accept-api-version: protocol=1.0,resource=2.1' \
  // gets a response:
  // {"authId":"eyJ0ei6Is","template":"","stage":"DataStore1","header":"Sign in","callbacks":[{"type":"NameCallback","output":[{"name":"prompt","value":"User Name:"}],
  // "input":[{"name":"IDToken1","value":""}]},{"type":"PasswordCallback",
  // "output":[{"name":"prompt","value":"Password:"}],"input":[{"name":"IDToken2","value":""}]}]}
  // followed by next request
  // {"authId":"CZmPc3NLJQi6Is","template":"","stage":"DataStore1","header":"Sign in",
  // "callbacks":[  {"type":"NameCallback","output":[{"name":"prompt","value":"User Name:"}],
  // "input":[{"name":"IDToken1","value":"user.1"}]},{"type":"PasswordCallback",
  // "output":[{"name":"prompt","value":"Password:"}],"input":[{"name":"IDToken2","value":"Bar1Foo2"}]}]}
  // path we want:   callbacks[0].[

  Future<String> loginEndUser(String userId, String password) async {
    clearCookies();
    var r = await dio.post('$_fqdn/am/json/realms/root/authenticate');

   check200(r);
    var callbacks = r.data['callbacks'];
    callbacks[0]['input'][0]['value'] = userId;
    callbacks[1]['input'][0]['value'] = password;

    r = await dio.post('$_fqdn/am/json/realms/root/authenticate', data:  r.data);
    check200(r);
    var tokenId = r.data['tokenId'];

    // get the users id
    r = await dio.post('$_fqdn/am/json/users/?_action=idFromSession');
    check200(r);

    var id = r.data['id'];
    // Cookie manager should have set the iPlanetPro cookie
    return id;
  }

}
