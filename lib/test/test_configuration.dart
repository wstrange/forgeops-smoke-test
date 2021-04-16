import 'dart:convert';

class TestConfiguration {
  late String fqdn;
  late String amAdminPassword;
  late bool debug;

  static final TEST_PASSWORD = 'Bar1Foo2'; // for creating users, self registration

  TestConfiguration(this.fqdn,this.amAdminPassword,{this.debug = false}) ;

  TestConfiguration.fromJson(String json) {
    var _map = jsonDecode(json);
    fqdn = _map['fqdn'];
    amAdminPassword = _map['amadminPassword'];
    debug = _map['debug'] ?? false;
  }

}

