import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('فاتورة اختبارية / Test Invoice', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 12),
              pw.Text('تاريخ: ${DateTime.now()}', style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 24),
              pw.Text('This is a simple generated PDF to verify PDF creation.', style: pw.TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    ),
  );

  final outDir = Directory('build');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final filename = 'build/test_invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File(filename);
  await file.writeAsBytes(await pdf.save());
  print('Saved test PDF to: ${file.path}');
}
