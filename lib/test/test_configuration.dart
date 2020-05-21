import 'dart:convert';

class TestConfiguration {
  String fqdn;
  String amAdminPassword;

  TestConfiguration(this.fqdn,this.amAdminPassword) ;

  TestConfiguration.fromJson(String json) {
    var _map = jsonDecode(json);
    fqdn = _map['fqdn'];
    amAdminPassword = _map['amadminPassword'];
  }

}

