import 'dart:convert';

import 'package:dio/dio.dart';

final _dio = Dio();

Future<void> sendSlackUpdate(String url, String text, {String channel = '#cloud-test', bool showFailIcon = false}) async {
  if( url == null || url.length < 20) {
    print('slack url not configured');
    return; // no slack url configured
  }

  _dio.options.contentType= Headers.formUrlEncodedContentType;
  var icon = showFailIcon ? ':face_vomiting:' : ':heavy_check_mark';
//  _dio.interceptors.add(
//        LogInterceptor(responseBody: true, requestBody: true, request: true));
  var j  = jsonEncode( {
    'channel' : channel,
    'username': 'smoke-test',
    'text' : text,
    'icon_emoji': icon,
  });
  try {
    var r = await _dio.post(url, data: {'payload': j });
  }
  catch(e) {
    if( e is DioError ) {
      print('url = $url ${e.response.statusMessage} ${e.response.statusCode}');
    }
    print('error sending to slack $e');
  }
}