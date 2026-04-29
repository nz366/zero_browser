// is a abstract that wraps all remote requests and used for network usage analytics for dev tools.
import 'package:http/http.dart' as http;

class Getter {
  // each tabs has its own getter instance.
  Getter({required this.context});

  final TabContext context;

  Future<http.Response> get(Uri uri) async {
    // todo track response time and size for dev tools
    return await http.get(uri);
  }

  Future<http.Response> post(Uri uri, {required body}) async {
    return await http.post(uri, body: body);
  }

  Future<http.Response> put(Uri uri, {required body}) async {
    return await http.put(uri, body: body);
  }

  Future<http.Response> delete(Uri uri) async {
    return await http.delete(uri);
  }
}

class TabContext {}
