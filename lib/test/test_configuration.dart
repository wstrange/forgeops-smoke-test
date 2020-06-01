import 'dart:convert';

class TestConfiguration {
  String fqdn;
  String amAdminPassword;
  bool debug;

  TestConfiguration(this.fqdn,this.amAdminPassword,{this.debug = false}) ;

  TestConfiguration.fromJson(String json) {
    var _map = jsonDecode(json);
    fqdn = _map['fqdn'];
    amAdminPassword = _map['amadminPassword'];
    debug = _map['debug'] ?? false;
  }

}

