import '../modules/core/models/base_record.dart';
import 'module_pdf_helper.dart';

class PdfHelper {
  static Future<void> generateCasePdf(ModuleRecord caseData) async {
    await ModulePdfHelper.generatePdf(caseData);
  }
}
