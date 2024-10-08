import 'package:flutter/material.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:convert';

class OdooSSOLoginButton extends StatefulWidget {
  final String baseUrl;
  final Function(String) onLoginSuccess;

  const OdooSSOLoginButton(
      {super.key, required this.baseUrl, required this.onLoginSuccess});

  @override
  State<OdooSSOLoginButton> createState() => _OdooSSOLoginButtonState();
}

class _OdooSSOLoginButtonState extends State<OdooSSOLoginButton> {
  String? _ssoUrl;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _handleSSOLogin,
      child: const Text('SSO Login'),
    );
  }

  Future<void> _handleSSOLogin() async {
    try {
      await _fetchSSOUrl();
      if (_ssoUrl != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OdooSSOWebView(
              ssoUrl: _ssoUrl!,
              baseUrl: widget.baseUrl,
              onLoginSuccess: widget.onLoginSuccess,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to retrieve SSO URL')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchSSOUrl() async {
    final response = await http.get(Uri.parse('${widget.baseUrl}/web/login'));
    final document = parse(response.body);
    _ssoUrl = document
        .querySelector('div.o_auth_oauth_providers a')
        ?.attributes['href'];
  }
}

class OdooSSOWebView extends StatefulWidget {
  final String ssoUrl;
  final String baseUrl;
  final Function(String) onLoginSuccess;

  const OdooSSOWebView({
    super.key,
    required this.ssoUrl,
    required this.baseUrl,
    required this.onLoginSuccess,
  });

  @override
  State<OdooSSOWebView> createState() => _OdooSSOWebViewState();
}

class _OdooSSOWebViewState extends State<OdooSSOWebView> {
  late final WebViewController _controller;
  final WebviewCookieManager _cookieManager = WebviewCookieManager();

  String? _redirectUrl;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _extractRedirectUrl();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (_redirectUrl != null && request.url.startsWith(_redirectUrl!)) {
              _extractSessionId(request.url);
              return NavigationDecision.navigate;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.ssoUrl));
  }

  void _extractRedirectUrl() {
    final uri = Uri.parse(widget.ssoUrl);
    final stateParam = uri.queryParameters['state'];
    if (stateParam != null) {
      final decodedState =
          json.decode(Uri.decodeFull(stateParam)) as Map<String, dynamic>;
      _redirectUrl = Uri.decodeFull(decodedState['r'] as String);
    }
  }

  Future<void> _extractSessionId(String url) async {
    print("Attempting to extract session ID from URL: $url");

    // Try to get cookies using CookieManager
    final cookies = await _cookieManager.getCookies(url);
    print(
        "Cookies found by CookieManager: ${cookies.map((c) => '${c.name}: ${c.value}').join(', ')}");

    for (final cookie in cookies) {
      if (cookie.name == 'session_id') {
        _sessionId = cookie.value;
        print("Session ID found in CookieManager: $_sessionId");
        break;
      }
    }

    // If session_id is not found, try to extract it using JavaScript
    if (_sessionId == null) {
      try {
        final allCookies = await _controller
            .runJavaScriptReturningResult("document.cookie") as String;
        print("All cookies from JavaScript: $allCookies");

        final cookieList = allCookies.split('; ');
        for (final cookie in cookieList) {
          if (cookie.startsWith('session_id=')) {
            _sessionId = cookie.split('=')[1];
            print("Session ID found in JavaScript: $_sessionId");
            break;
          }
        }
      } catch (e) {
        print("Error executing JavaScript: $e");
      }
    }

    if (_sessionId != null) {
      print("Final extracted session ID: $_sessionId");
      widget.onLoginSuccess(_sessionId!);
      Navigator.of(context).pop(); // Close the WebView
    } else {
      print("Failed to extract session ID");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extract session ID')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SSO Login')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
        ],
      ),
    );
  }
}

// Example usage
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Odoo SSO Login Example')),
        body: Center(
          child: OdooSSOLoginButton(
            baseUrl: 'https://us.apexive.com',
            onLoginSuccess: (String sessionId) {
              print('Login successful! Session ID: $sessionId');
            },
          ),
        ),
      ),
    );
  }
}
