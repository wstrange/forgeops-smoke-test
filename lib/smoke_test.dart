import 'test/test_configuration.dart';

import 'test/test_runner.dart';

class SmokeTest extends TestRunner {
  SmokeTest(TestConfiguration config) : super(config);

  // Run all the smoke tests.
  // Any exception causes the test to stop immediately
  Future<void> runSmokeTest() async {
    print('run smoke test');
    try {
      await amTests();
      await idmTests();
      await integrationTests();
    } catch (e) {
      print('Tests failed with exception ${e}');
      rethrow;
    }
  }

  // Run all the AM tests
  Future<void> amTests() async {
    await test('Authenticate as AMAdmin', () async {
      var token = await am.authenticateAsAdmin();
      expect(token != null, message: 'Cant authenticate as amadmin');
    });

//    await test('Dynamic client registration', () async {
//      var token = await am.getOAuth2Token('master-client', 'password');
//      assert(token != null);
//
//      // now use the access token to register a client
//      var client_json = await am.registerOAuthClient(token);
//
//      assert( client_json != null);
//      assert( client_json['client_id'] != null);
//    });

    // for SAML - use scripts https://stash.forgerock.org/users/ravi.geda/repos/saml2/browse/saml2/setup-saml2.sh
  }

  // Run all IDM tests
  Future<void> idmTests() async {
    String uuid;
    var testUser = 'testuser01';

    await test('IDM Login as Admin', () async {
      var idm_access_token = await idm.getBearerToken();
      expect(idm_access_token != null);
    });

    await test('IDM Admin Create a user', () async {
      uuid = await idm.createUser(testUser);
      expect(uuid != null, message: 'Can not create user $testUser');
    });

    await test('IDM find user', () async {
      var uid = await idm.queryUser(testUser);
      expect(uid == uuid, message: 'Test user not found $testUser');
    });

    await test('IDM Modify User', () async {
      await idm.modifyUser(uuid);
    });

    await test('IDM Delete user', () async {
      await idm.deleteUser(uuid);
    });
  }

  // todo: Additional integration tests
  // log on to the end user UI
  Future<void> integrationTests() async {
    var uuid;

    // search for non existing user
    await test('Search for non existent user', () async {
      uuid = await idm.queryUser('nonUser');
      expect(uuid == null, message: 'uuid was not null!');
    });

    // Create some sample users. These get left in place after the test
    // so we can use them for adhoc manual testing
  
    await Future.forEach( [1,2,3,4,5], (i) async {
      var user = 'user.$i';
      var uuid = await idm.queryUser(user);

      if( uuid == null ) {
        await idm.createUser(user);
      }
    });

  }



  // todo: Clean up after all tests
  // This is where we want to delete any users, etc.
  Future<void> cleanupTests() async {}
}
