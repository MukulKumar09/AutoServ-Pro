import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/job_card_model.dart';

class PdfService {
  static Future<Uint8List> generateJobCardPdf(JobCardModel card) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('AutoServ Pro', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800)),
                pw.Text('Job Card: ${card.roNumber}', style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Customer & Vehicle Information'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              _buildTableRow('Name', card.customerName, 'Contact', card.contactNumber),
              _buildTableRow('Address', card.address, 'Alt Contact', card.alternateNumber),
              _buildTableRow('Vehicle', '${card.vehicleMake} ${card.vehicleModel}', 'Reg No', card.registrationNumber),
              _buildTableRow('Chassis', card.chassisNumber, 'Engine', card.engineNumber),
              _buildTableRow('KM Reading', card.kmReading, 'Entry Date', card.entryDate.toString().split(' ')[0]),
            ],
          ),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Demanded Jobs'),
          pw.Bullet(text: card.demandedJobs.isEmpty ? 'None' : card.demandedJobs.join('\n')),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Recommended Jobs'),
          pw.Bullet(text: card.recommendedJobs.isEmpty ? 'None' : card.recommendedJobs.join('\n')),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
    );
  }

  static pw.TableRow _buildTableRow(String k1, String v1, String k2, String v2) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6), 
          child: pw.Text(k1, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6), 
          child: pw.Text(v1, style: const pw.TextStyle(fontSize: 10))
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6), 
          child: pw.Text(k2, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6), 
          child: pw.Text(v2, style: const pw.TextStyle(fontSize: 10))
        ),
      ]
    );
  }
}
