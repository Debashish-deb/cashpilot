/// Bank Auth WebView Screen
/// Displays GoCardless bank authorization in a WebView
library;

import 'package:flutter/material.dart';
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
          if (request.url.startsWith('cashpilot://bank-callback')) {
            Navigator.pop(context, true); // Success
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authorize Bank Access'),
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
