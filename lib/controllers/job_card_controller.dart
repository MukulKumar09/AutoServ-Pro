// lib/controllers/job_card_controller.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/job_card_model.dart';
import '../services/firebase_service.dart';

class JobCardController extends ChangeNotifier {
  final FirebaseService _service;
  final _uuid = const Uuid();
  bool _disposed = false;

  JobCardController(this._service);

  // ── State ──────────────────────────────────────────────────────────────────
  List<JobCardModel> _jobCards     = [];
  List<JobCardModel> _filtered     = [];
  JobCardModel?      _activeCard;
  bool               _isLoading    = false;
  String?            _error;

  // Dashboard stats
  int    _todayCars    = 0;
  int    _openJobs     = 0;
  int    _completedJobs= 0;
  double _todayRevenue = 0;
  double _emiPending   = 0;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<JobCardModel> get jobCards       => _filtered;
  List<JobCardModel> get allJobCards    => _jobCards;
  JobCardModel?      get activeJobCard  => _activeCard;
  bool               get isLoading      => _isLoading;
  String?            get error          => _error;
  int    get todayCars     => _todayCars;
  int    get openJobs      => _openJobs;
  int    get completedJobs => _completedJobs;
  double get todayRevenue  => _todayRevenue;
  double get emiPending    => _emiPending;

  void _notify() { if (!_disposed) notifyListeners(); }

  // ── Watch all job cards ────────────────────────────────────────────────────
  void watchJobCards() {
    _isLoading = true;
    _notify();
    _service.watchAllJobCards().listen(
      (cards) {
        _jobCards  = cards;
        _filtered  = List.from(cards);
        _computeStats();
        _isLoading = false;
        _notify();
      },
      onError: (e) {
        _error     = e.toString();
        _isLoading = false;
        _notify();
      },
    );
  }

  void _computeStats() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    _todayCars     = _jobCards.where((c) => c.entryDate.isAfter(start)).length;
    _openJobs      = _jobCards.where((c) => c.status == JobStatus.open || c.status == JobStatus.inProgress).length;
    _completedJobs = _jobCards.where((c) => c.status == JobStatus.completed || c.status == JobStatus.delivered).length;
    _todayRevenue  = _jobCards.where((c) => c.entryDate.isAfter(start)).fold(0, (s, c) => s + c.totalPaid);
    _emiPending    = _jobCards.where((c) => c.hasBalance).fold(0, (s, c) => s + c.balanceDue);
  }

  // ── Search / Filter ────────────────────────────────────────────────────────
  Future<List<JobCardModel>> searchCards({
    String? regNumber, String? contact, String? name,
    DateTime? fromDate, DateTime? toDate,
    String? vehicleModel, bool? pendingOnly,
    int? month, int? year,
  }) async {
    List<JobCardModel> result;

    if (regNumber != null && regNumber.isNotEmpty) {
      result = await _service.searchByRegistration(regNumber);
    } else if (contact != null && contact.isNotEmpty) {
      result = await _service.searchByContact(contact);
    } else if (name != null && name.isNotEmpty) {
      result = await _service.searchByName(name);
    } else {
      result = List.from(_jobCards);
    }

    if (fromDate != null) result = result.where((c) => !c.entryDate.isBefore(fromDate)).toList();
    if (toDate   != null) result = result.where((c) => c.entryDate.isBefore(toDate.add(const Duration(days: 1)))).toList();
    if (vehicleModel != null && vehicleModel.isNotEmpty)
      result = result.where((c) => c.vehicleModel.toLowerCase().contains(vehicleModel.toLowerCase())).toList();
    if (pendingOnly == true) result = result.where((c) => c.hasBalance).toList();
    if (month != null) result = result.where((c) => c.entryDate.month == month).toList();
    if (year  != null) result = result.where((c) => c.entryDate.year  == year).toList();

    return result;
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────
  Future<String?> createNewJobCard({
    required String createdByUid,
    required String customerName,
    required String address,
    required String contactNumber,
    required String alternateNumber,
    required String vehicleMake,
    required String vehicleModel,
    required String registrationNumber,
    required String chassisNumber,
    required String engineNumber,
    required String kmReading,
  }) async {
    _isLoading = true; _error = null; _notify();
    try {
      final roNumber = await _service.generateRONumber();
      final now = DateTime.now();
      final card = JobCardModel(
        id: '', roNumber: roNumber,
        entryDate: now, inTime: now,
        customerName: customerName, address: address,
        contactNumber: contactNumber, alternateNumber: alternateNumber,
        vehicleMake: vehicleMake, vehicleModel: vehicleModel,
        registrationNumber: registrationNumber,
        chassisNumber: chassisNumber, engineNumber: engineNumber,
        kmReading: kmReading,
        createdBy: createdByUid, createdAt: now, updatedAt: now,
      );
      final id = await _service.createJobCard(card);
      _activeCard = card.copyWith(id: id);
      _isLoading = false; _notify();
      return id;
    } catch (e) {
      _error = e.toString(); _isLoading = false; _notify();
      return null;
    }
  }

  Future<bool> updateJobCard(JobCardModel updated) async {
    _error = null;
    try {
      await _service.updateJobCard(updated);
      final idx = _jobCards.indexWhere((c) => c.id == updated.id);
      if (idx != -1) _jobCards[idx] = updated;
      _filtered = List.from(_jobCards);
      if (_activeCard?.id == updated.id) _activeCard = updated;
      _computeStats();
      _notify();
      return true;
    } catch (e) {
      _error = e.toString(); _notify();
      return false;
    }
  }

  void setActiveJobCard(JobCardModel card) {
    _activeCard = card; _notify();
  }

  Future<void> loadJobCard(String id) async {
    _isLoading = true; _notify();
    _activeCard = await _service.getJobCard(id);
    _isLoading = false; _notify();
  }

  // ── Billing ────────────────────────────────────────────────────────────────
  Future<bool> updateBilling({
    required JobCardModel card,
    required List<BillingItem> labourItems,
    required List<BillingItem> subletItems,
    required double spareParts,
    required double advance,
  }) => updateJobCard(card.copyWith(
      labourItems: labourItems, subletItems: subletItems,
      spareParts: spareParts, advance: advance));

  // ── EMI Payment ────────────────────────────────────────────────────────────
  Future<bool> addPayment({
    required JobCardModel card,
    required double amount,
    required String paymentMode,
    required String notes,
  }) {
    final payment = PaymentEntry(
      id: _uuid.v4(), date: DateTime.now(),
      amount: amount, paymentMode: paymentMode, notes: notes,
    );
    return updateJobCard(card.copyWith(payments: [...card.payments, payment]));
  }

  // ── Image upload via Cloudinary ────────────────────────────────────────────
  Future<String?> uploadInspectionImage(JobCardModel card, String slot, File imageFile) async {
    try {
      final url = await _service.uploadImageFile(imageFile, 'garage/inspections/${card.id}');
      final imgs = Map<String, String>.from(card.inspectionImages)..[slot] = url;
      await updateJobCard(card.copyWith(inspectionImages: imgs));
      return url;
    } catch (e) {
      _error = e.toString(); _notify(); return null;
    }
  }

  Future<String?> uploadSignature(JobCardModel card, Uint8List bytes, String type) async {
    try {
      final url = await _service.uploadSignatureBytes(bytes, 'garage/signatures/${card.id}');
      final updated = type == 'customer'
          ? card.copyWith(customerSignatureUrl: url)
          : card.copyWith(managerSignatureUrl: url);
      await updateJobCard(updated);
      return url;
    } catch (e) {
      _error = e.toString(); _notify(); return null;
    }
  }

  // ── Status ─────────────────────────────────────────────────────────────────
  Future<bool> updateJobStatus(JobCardModel card, JobStatus status) {
    final outTime = (status == JobStatus.delivered || status == JobStatus.completed)
        ? DateTime.now() : card.outTime;
    return updateJobCard(card.copyWith(status: status, outTime: outTime));
  }

  // ── Reports ────────────────────────────────────────────────────────────────
  Future<Map<String, double>> getMonthlyRevenue(int year) => _service.getMonthlyRevenue(year);
  List<JobCardModel> getRecentJobCards({int limit = 10}) => _jobCards.take(limit).toList();

  void clearError() { _error = null; _notify(); }

  @override
  void dispose() { _disposed = true; super.dispose(); }
}
