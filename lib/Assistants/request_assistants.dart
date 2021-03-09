import 'dart:convert';

import 'package:http/http.dart' as http;

class RequestAssistants {
  static Future<dynamic> getRequest(String url) async {
    http.Response response = await http.get(url);
    try {
      if(response.statusCode == 200)
        {
          String jsonData = response.body ;
          print(response.body);

          var jsondecode = jsonDecode(jsonData);
          print(jsondecode);
          return jsondecode ;
        }else {
        return 'failed';
      }
    } catch (exp) {
      return 'failed';
    }
  }
}
