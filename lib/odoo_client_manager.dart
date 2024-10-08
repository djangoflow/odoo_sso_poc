import 'package:djangoflow_odoo_auth/djangoflow_odoo_auth.dart';
import 'package:odoo_rpc/src/odoo_client.dart';
import 'package:odoo_rpc/src/odoo_session.dart';

class CustomOdooClientManager implements OdooClientManager {
  OdooClient? _odooClient;

  CustomOdooClientManager();

  @override
  OdooClient? getClient() => _odooClient;

  @override
  void initializeClient(String baseUrl, {OdooSession? session}) {
    _odooClient = ExtendedOdooClient(baseUrl, session);
  }
}
