// lib/pdf/pdf_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/job_card_model.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
final _dateFormat = DateFormat('dd MMM yyyy');
final _timeFormat = DateFormat('hh:mm a');

class PdfService {
  static Future<void> printJobCard(JobCardModel card) async {
    final pdf = await _buildJobCardPdf(card);
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  static Future<void> printInvoice(JobCardModel card) async {
    final pdf = await _buildInvoicePdf(card);
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  static Future<pw.Document> _buildJobCardPdf(JobCardModel card) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildHeader(card, fontBold, font),
        footer: (ctx) => _buildFooter(ctx, font),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _buildCustomerSection(card, fontBold, font),
          pw.SizedBox(height: 12),
          _buildVehicleSection(card, fontBold, font),
          pw.SizedBox(height: 12),
          _buildInventorySection(card, fontBold, font),
          pw.SizedBox(height: 12),
          _buildMechanicalSection(card, fontBold, font),
          pw.SizedBox(height: 12),
          _buildJobsSection(card, fontBold, font),
        ],
      ),
    );
    return pdf;
  }

  static Future<pw.Document> _buildInvoicePdf(JobCardModel card) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildHeader(card, fontBold, font),
        footer: (ctx) => _buildFooter(ctx, font),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          _buildCustomerSection(card, fontBold, font),
          pw.SizedBox(height: 12),
          _buildVehicleSection(card, fontBold, font),
          pw.SizedBox(height: 12),
          _buildBillingSection(card, fontBold, font),
          pw.SizedBox(height: 12),
          _buildPaymentHistory(card, fontBold, font),
          pw.SizedBox(height: 24),
          _buildSignatureSection(card, fontBold, font),
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _buildHeader(
      JobCardModel card, pw.Font bold, pw.Font regular) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey900,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('AutoServ Pro',
                      style: pw.TextStyle(
                          font: bold,
                          fontSize: 20,
                          color: PdfColors.amber)),
                  pw.Text('Workshop Management System',
                      style: pw.TextStyle(
                          font: regular,
                          fontSize: 9,
                          color: PdfColors.grey300)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(card.roNumber,
                      style: pw.TextStyle(
                          font: bold,
                          fontSize: 16,
                          color: PdfColors.amber)),
                  pw.Text(
                      'Date: ${_dateFormat.format(card.entryDate)}',
                      style: pw.TextStyle(
                          font: regular,
                          fontSize: 10,
                          color: PdfColors.grey300)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: PdfColors.amber, thickness: 2),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('AutoServ Pro — Workshop Management Software',
              style:
                  pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey500)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style:
                  pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerSection(
      JobCardModel card, pw.Font bold, pw.Font regular) {
    return _section(
      'CUSTOMER INFORMATION',
      bold,
      pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          _tableRow('Customer Name', card.customerName, 'Contact', card.contactNumber, bold, regular),
          _tableRow('Address', card.address, 'Alternate', card.alternateNumber, bold, regular),
        ],
      ),
    );
  }

  static pw.Widget _buildVehicleSection(
      JobCardModel card, pw.Font bold, pw.Font regular) {
    return _section(
      'VEHICLE INFORMATION',
      bold,
      pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          _tableRow('Make', card.vehicleMake, 'Model', card.vehicleModel, bold, regular),
          _tableRow('Reg. No.', card.registrationNumber, 'KM Reading', card.kmReading, bold, regular),
          _tableRow('Chassis', card.chassisNumber, 'Engine', card.engineNumber, bold, regular),
          _tableRow('In Time', _timeFormat.format(card.inTime), 'Out Time', card.outTime != null ? _timeFormat.format(card.outTime!) : '—', bold, regular),
        ],
      ),
    );
  }

  static pw.Widget _buildBillingSection(
      JobCardModel card, pw.Font bold, pw.Font regular) {
    return _section(
      'BILLING DETAILS',
      bold,
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Labour table
          if (card.labourItems.isNotEmpty) ...[
            pw.Text('Labour Charges',
                style: pw.TextStyle(font: bold, fontSize: 11)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Description', bold, isHeader: true),
                    _cell('Amount', bold, isHeader: true, align: pw.Alignment.centerRight),
                  ],
                ),
                ...card.labourItems.map((i) => pw.TableRow(children: [
                      _cell(i.description, regular),
                      _cell(_currency.format(i.amount), regular, align: pw.Alignment.centerRight),
                    ])),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _cell('Subtotal', bold),
                    _cell(_currency.format(card.labourTotal), bold, align: pw.Alignment.centerRight),
                  ],
                ),
                pw.TableRow(children: [
                  _cell('GST @ 18%', regular),
                  _cell(_currency.format(card.labourGstAmount), regular, align: pw.Alignment.centerRight),
                ]),
              ],
            ),
            pw.SizedBox(height: 12),
          ],

          // Sublet table
          if (card.subletItems.isNotEmpty) ...[
            pw.Text('Sublet Charges',
                style: pw.TextStyle(font: bold, fontSize: 11)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Description', bold, isHeader: true),
                    _cell('Amount', bold, isHeader: true, align: pw.Alignment.centerRight),
                  ],
                ),
                ...card.subletItems.map((i) => pw.TableRow(children: [
                      _cell(i.description, regular),
                      _cell(_currency.format(i.amount), regular, align: pw.Alignment.centerRight),
                    ])),
              ],
            ),
            pw.SizedBox(height: 12),
          ],

          // Grand total box
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              children: [
                _totalRow('Spare Parts', card.spareParts, regular, bold),
                _totalRow('Labour (incl. GST)', card.labourTotal + card.labourGstAmount, regular, bold),
                _totalRow('Sublet', card.subletTotal, regular, bold),
                pw.Divider(color: PdfColors.grey400),
                _totalRow('GRAND TOTAL', card.grandTotal, bold, bold, isBold: true),
                pw.SizedBox(height: 4),
                _totalRow('Advance Paid', card.advance, regular, bold, isGreen: true),
                _totalRow('EMI Collected', card.payments.fold(0, (s, p) => s + p.amount), regular, bold, isGreen: true),
                pw.Divider(color: PdfColors.grey400),
                _totalRow('BALANCE DUE', card.balanceDue, bold, bold,
                    isBold: true, isRed: card.balanceDue > 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentHistory(
      JobCardModel card, pw.Font bold, pw.Font regular) {
    if (card.payments.isEmpty) return pw.SizedBox();
    return _section(
      'PAYMENT HISTORY',
      bold,
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _cell('#', bold, isHeader: true),
              _cell('Date', bold, isHeader: true),
              _cell('Mode', bold, isHeader: true),
              _cell('Amount', bold, isHeader: true, align: pw.Alignment.centerRight),
            ],
          ),
          ...card.payments.asMap().entries.map((e) => pw.TableRow(children: [
                _cell('${e.key + 1}', regular),
                _cell(_dateFormat.format(e.value.date), regular),
                _cell(e.value.paymentMode, regular),
                _cell(_currency.format(e.value.amount), regular, align: pw.Alignment.centerRight),
              ])),
        ],
      ),
    );
  }

  static pw.Widget _buildInventorySection(
      JobCardModel card, pw.Font bold, pw.Font regular) {
    final inv = card.inventoryChecklist;
    final items = <String>[];
    if (inv.keyRemote) items.add('Key Remote');
    if (inv.audioSystem) items.add('Audio System');
    if (inv.cdDvdChanger) items.add('CD/DVD Changer');
    if (inv.speakers > 0) items.add('Speakers: ${inv.speakers}');
    if (inv.ownerManual) items.add('Owner Manual');
    if (inv.jackHandle) items.add('Jack & Handle');
    if (inv.spareWheel) items.add('Spare Wheel');
    if (inv.firstAidKit) items.add('First Aid Kit');
    if (inv.others.isNotEmpty) items.add('Others: ${inv.others}');

    return _section(
      'INVENTORY CHECKLIST',
      bold,
      pw.Wrap(
        spacing: 8,
        runSpacing: 4,
        children: items
            .map((i) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(i,
                      style: pw.TextStyle(font: regular, fontSize: 9)),
                ))
            .toList(),
      ),
    );
  }

  static pw.Widget _buildMechanicalSection(
      JobCardModel card, pw.Font bold, pw.Font regular) {
    final mc = card.mechanicalChecklist;
    final checked = <String>[];
    if (mc.coolantLeakage) checked.add('Coolant Leakage');
    if (mc.clutchOperation) checked.add('Clutch Operation');
    if (mc.transmissionOil) checked.add('Transmission Oil');
    if (mc.handBrake) checked.add('Hand Brake');
    if (mc.steeringCheck) checked.add('Steering');
    if (mc.engineOilReplace) checked.add('Engine Oil');
    if (mc.wipersCheck) checked.add('Wipers');
    if (mc.headTailLamp) checked.add('Head/Tail Lamp');
    if (mc.tyreInflation) checked.add('Tyre Inflation');
    if (mc.brakePadLinear) checked.add('Brake Pads');

    return _section(
      'MECHANICAL SERVICE CHECKLIST',
      bold,
      pw.Wrap(
        spacing: 8,
        runSpacing: 4,
        children: checked
            .map((i) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.lightGreen100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.green),
                  ),
                  child: pw.Row(children: [
                    pw.Text('✓ ',
                        style: pw.TextStyle(
                            font: bold,
                            fontSize: 9,
                            color: PdfColors.green)),
                    pw.Text(i,
                        style: pw.TextStyle(font: regular, fontSize: 9)),
                  ]),
                ))
            .toList(),
      ),
    );
  }

  static pw.Widget _buildJobsSection(
      JobCardModel card, pw.Font bold, pw.Font regular) {
    if (card.demandedJobs.isEmpty && card.recommendedJobs.isEmpty) {
      return pw.SizedBox();
    }
    return _section(
      'JOBS',
      bold,
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (card.demandedJobs.isNotEmpty)
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Demanded:',
                      style: pw.TextStyle(font: bold, fontSize: 10)),
                  pw.SizedBox(height: 4),
                  ...card.demandedJobs.map((j) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text('• $j',
                            style: pw.TextStyle(
                                font: regular, fontSize: 9)),
                      )),
                ],
              ),
            ),
          if (card.recommendedJobs.isNotEmpty)
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Recommended:',
                      style: pw.TextStyle(font: bold, fontSize: 10)),
                  pw.SizedBox(height: 4),
                  ...card.recommendedJobs.map((j) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Text('• $j',
                            style: pw.TextStyle(
                                font: regular, fontSize: 9)),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureSection(
      JobCardModel card, pw.Font bold, pw.Font regular) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                height: 60,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Customer Signature',
                  style:
                      pw.TextStyle(font: bold, fontSize: 10)),
              pw.Text(card.customerName,
                  style: pw.TextStyle(
                      font: regular, fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                height: 60,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Manager / Advisor Signature',
                  style: pw.TextStyle(font: bold, fontSize: 10)),
              pw.Text(
                  card.receivedBy.isNotEmpty
                      ? card.receivedBy
                      : 'Authorized Signatory',
                  style: pw.TextStyle(
                      font: regular, fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  static pw.Widget _section(
      String title, pw.Font bold, pw.Widget content) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  font: bold, fontSize: 11, color: PdfColors.grey800)),
          pw.Divider(color: PdfColors.amber, thickness: 1),
          pw.SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  static pw.TableRow _tableRow(
      String l1, String v1, String l2, String v2,
      pw.Font bold, pw.Font regular) {
    return pw.TableRow(children: [
      _cell(l1, bold, isHeader: true),
      _cell(v1, regular),
      _cell(l2, bold, isHeader: true),
      _cell(v2, regular),
    ]);
  }

  static pw.Widget _cell(String text, pw.Font font,
      {bool isHeader = false, pw.Alignment? align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Align(
        alignment: align ?? pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: isHeader ? 9 : 10,
            color: isHeader ? PdfColors.grey700 : PdfColors.black,
          ),
        ),
      ),
    );
  }

  static pw.Widget _totalRow(
      String label, double amount, pw.Font labelFont, pw.Font valueFont,
      {bool isBold = false, bool isGreen = false, bool isRed = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: labelFont, fontSize: isBold ? 12 : 10)),
          pw.Text(
            _currency.format(amount),
            style: pw.TextStyle(
              font: valueFont,
              fontSize: isBold ? 12 : 10,
              color: isGreen
                  ? PdfColors.green700
                  : isRed
                      ? PdfColors.red700
                      : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
