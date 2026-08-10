import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfGenerator {
  static Future<File> generatePdfFromImages(List<String> imagePaths, String fileName) async {
    final pdf = pw.Document();

    for (var path in imagePaths) {
      final imageFile = File(path);
      if (await imageFile.exists()) {
        final image = pw.MemoryImage(await imageFile.readAsBytes());
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }
    }

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
