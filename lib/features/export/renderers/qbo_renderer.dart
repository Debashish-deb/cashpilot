import 'dart:convert';
import 'dart:typed_data';
import '../models/export_bundle.dart';
import 'i_renderer.dart';

class QboRenderer implements IRenderer {
  @override
  String get extension => 'qbo';

  @override
  String get mimeType => 'application/vnd.intu.qbo';

  @override
  Future<Uint8List> render(ExportBundle bundle) async {
    // Basic OFX/QBO structure
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    buffer.writeln('OFXHEADER:100');
    buffer.writeln('DATA:OFXSGML');
    buffer.writeln('VERSION:102');
    buffer.writeln('SECURITY:NONE');
    buffer.writeln('ENCODING:USASCII');
    buffer.writeln('CHARSET:1252');
    buffer.writeln('COMPRESSION:NONE');
    buffer.writeln('OLDFILEUID:NONE');
    buffer.writeln('NEWFILEUID:NONE');
    buffer.writeln('');
    buffer.writeln('<OFX>');
    buffer.writeln('  <SIGNONMSGSRSV1>');
    buffer.writeln('    <SONRS>');
    buffer.writeln('      <STATUS><CODE>0</CODE><SEVERITY>INFO</SEVERITY></STATUS>');
    buffer.writeln('      <DTSERVER>$dateStr</DTSERVER>');
    buffer.writeln('      <LANGUAGE>ENG</LANGUAGE>');
    buffer.writeln('    </SONRS>');
    buffer.writeln('  </SIGNONMSGSRSV1>');
    buffer.writeln('  <BANKMSGSRSV1>');
    buffer.writeln('    <STMTTRNRS>');
    buffer.writeln('      <TRNUID>1</TRNUID>');
    buffer.writeln('      <STATUS><CODE>0</CODE><SEVERITY>INFO</SEVERITY></STATUS>');
    buffer.writeln('      <STMTRS>');
    buffer.writeln('        <CURDEF>EUR</CURDEF>');
    buffer.writeln('        <BANKTRANLIST>');
    
    for (final e in bundle.expenses) {
      final eDate = '${e.date.year}${e.date.month.toString().padLeft(2, '0')}${e.date.day.toString().padLeft(2, '0')}';
      final amount = -(e.amount / 100.0); // Expenses are negative in bank statements

      buffer.writeln('          <STMTTRN>');
      buffer.writeln('            <TRNTYPE>DEBIT</TRNTYPE>');
      buffer.writeln('            <DTPOSTED>$eDate</DTPOSTED>');
      buffer.writeln('            <TRNAMT>${amount.toStringAsFixed(2)}</TRNAMT>');
      buffer.writeln('            <FITID>${e.id}</FITID>');
      buffer.writeln('            <NAME>${_escape(e.merchantName ?? e.title)}</NAME>');
      if (e.notes != null) buffer.writeln('            <MEMO>${_escape(e.notes!)}</MEMO>');
      buffer.writeln('          </STMTTRN>');
    }

    buffer.writeln('        </BANKTRANLIST>');
    buffer.writeln('      </STMTRS>');
    buffer.writeln('    </STMTTRNRS>');
    buffer.writeln('  </BANKMSGSRSV1>');
    buffer.writeln('</OFX>');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  String _escape(String text) {
    return text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  }
}
