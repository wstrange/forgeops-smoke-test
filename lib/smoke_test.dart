import 'test/test_configuration.dart';

import 'test/test_runner.dart';

class SmokeTest extends TestRunner {
  SmokeTest(TestConfiguration config) : super(config);

  // Run all the smoke tests. Return true if all tests passed
  Future<bool> runSmokeTest() async {
    try {
      await amTests();
      await idmTests();
      await integrationTests();
      // login ui has changed -
      // await endUserTests();
    } catch (e) {
      print('Tests failed with exception ${e}');
      return false;
    }
    return failed == 0; // all tests passed?
  }

  // Run all the AM tests
  Future<void> amTests() async {
    await test('Authenticate as AMAdmin', () async {
      var token = await amClient.authenticateAsAdmin();
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
      var idm_access_token = await idmClient.getBearerToken();
      expect(idm_access_token != null);
    });

    await test('IDM Admin Create a user', () async {
      uuid = await idmClient.createUser(testUser);
      expect(uuid != null, message: 'Can not create user $testUser');
    });

    await test('IDM find user', () async {
      var uid = await idmClient.queryUser(testUser);
      expect(uid == uuid, message: 'Test user not found $testUser');
    });

    await test('IDM Modify User', () async {
      await idmClient.modifyUser(uuid);
    });

    await test('IDM Delete user', () async {
      await idmClient.deleteUser(uuid);
    });

    // search for a user that does not exist
    await test('Search for non existent user', () async {
      var id = await idmClient.queryUser('nonUser');
      expect(id == null, message: 'uuid was not null!');
    });
  }

  // Integration tests between AM/IDM
  Future<void> integrationTests() async {
    // Create some sample users. These get left in place after the test
    // so we can use them for adhoc manual testing

    await Future.forEach([1, 2, 3, 4, 5], (i) async {
      var user = 'user.$i';
      var uuid = await idmClient.queryUser(user);

      if (uuid == null) {
        await idmClient.createUser(user);
      }
    });

    await test('Self Registration Test', () async {
      var m = await amClient.selfRegisterUser();
      expect(m['tokenId'] != null,
          message: 'tokenId missing in registration response');
    });
  }

  Future<void> endUserTests() async {
    await test('End user login test ', ()  async {
       await endUserClient.loginEndUser('user.1', TestConfiguration.TEST_PASSWORD);
    });
  }

  // todo: Clean up after all tests
  // This is where we want to delete any test users, etc.
  Future<void> cleanupTests() async {}

}
