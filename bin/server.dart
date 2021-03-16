import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:forgeops_smoke_test/forgerock_smoke_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = '0.0.0.0';

/// Simple web service that listens for requests to run the test suite
/// Test suite parameters are POSTed to /test. See the README.md
void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8080';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  var slackUrl = Platform.environment['SLACK_URL'];

  var staticHandler =
      createStaticHandler('public', defaultDocument: 'index.html');

  var app = Router();

  // POST to the /test endpoint to start the test
  app.post('/test', (Request request) async {
    var body = await request.readAsString(); // get the body
    var param = Uri(query: body).queryParameters; // parse as URI to extract form params
    var fqdn = param['fqdn'];
    var d = param['debug'];
    var _debug = (d != null && d == 'true') ? true : false;

    var cfg =
        TestConfiguration('https://$fqdn', param['amadminPassword'], debug: _debug);
    var test = SmokeTest(cfg);
    var testOK = await test.runSmokeTest();
    await test.close();

    var hostString = '<https://${request.requestedUri.host}|Smoke Service>';

    if (testOK) {
      await sendSlackUpdate(
          // slackUrl, '$hostString\n\n${test.getPrettyResults()}');
          // Make slack message shorter.
          slackUrl, '$hostString test OK $fqdn');
      return Response.ok(_results2Json(test),
          headers: {'content-type': 'application/json'});
    } else {
      await sendSlackUpdate(
          slackUrl, '$hostString\n\n${test.getPrettyResults()}',
          showFailIcon: true);
      return Response.internalServerError(body: _results2Json(test));
    }
  });

  var handler = Cascade().add(staticHandler).add(app.handler).handler;

  // Pipelines compose middleware plus a single handler
  var pipe = const Pipeline().addMiddleware(logRequests()).addHandler(handler);

  var server = await io.serve(pipe, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

String _results2Json(SmokeTest t) => _encoder.convert(t.toJson());

final _encoder = JsonEncoder.withIndent('  ');
