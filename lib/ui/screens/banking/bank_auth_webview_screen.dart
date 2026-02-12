/// Bank Auth WebView Screen
/// Displays GoCardless bank authorization in a WebView
library;

import 'package:flutter/material.dart';
import 'package:cashpilot/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BankAuthWebViewScreen extends StatefulWidget {
  final String authUrl;
  final String requisitionId;

  const BankAuthWebViewScreen({
    super.key,
    required this.authUrl,
    required this.requisitionId,
  });

  @override
  State<BankAuthWebViewScreen> createState() => _BankAuthWebViewScreenState();
}

class _BankAuthWebViewScreenState extends State<BankAuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onNavigationRequest: (request) {
          // Detect redirect back to app
          if (request.url.startsWith('cashpilot://bank/callback')) {
            Navigator.pop(context, true); // Success
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));

    if (widget.authUrl.startsWith('mock://')) {
      _loadMockPage();
    } else {
      _controller.loadRequest(Uri.parse(widget.authUrl));
    }
  }

  void _loadMockPage() {
    // Extract bank name/id from param if possible or just show generic
    final uri = Uri.parse(widget.authUrl);
    final bankId = uri.queryParameters['inst'] ?? 'Bank';
    
    final html = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; padding: 20px; text-align: center; background-color: #f5f5f7; display: flex; flex-direction: column; height: 90vh; justify-content: center; }
          .card { background: white; padding: 30px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
          h1 { font-size: 24px; margin-bottom: 30px; color: #333; }
          img { width: 80px; height: 80px; margin-bottom: 20px; border-radius: 20%; background: #eee; }
          p { color: #666; margin-bottom: 40px; line-height: 1.5; }
          .btn { background-color: #007AFF; color: white; border: none; padding: 16px 32px; font-size: 16px; border-radius: 12px; cursor: pointer; width: 100%; font-weight: 600; text-decoration: none; display: inline-block; box-sizing: border-box; }
          .btn:active { opacity: 0.8; }
          .secure { font-size: 12px; color: #999; margin-top: 20px; display: flex; align-items: center; justify-content: center; gap: 5px; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>Connect to ${bankId.replaceAll('_', ' ').toUpperCase()}</h1>
          <p>CashPilot is requesting access to your account details and transaction history.</p>
          
          <a href="cashpilot://bank/callback?req=${widget.requisitionId}" class="btn">Authorize Access</a>
          
          <div class="secure">
            <span>🔒</span> Secure Mock Connection
          </div>
        </div>
      </body>
      </html>
    ''';
    
    _controller.loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bankingAuthorizeTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
