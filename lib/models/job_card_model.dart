// lib/models/job_card_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum JobStatus { open, inProgress, completed, delivered, cancelled }

enum PaymentStatus { pending, partial, paid }

/// Represents a single labour or sublet billing row
class BillingItem {
  final String id;
  final String description;
  final double amount;

  BillingItem(
      {required this.id, required this.description, required this.amount});

  factory BillingItem.fromMap(Map<String, dynamic> map) => BillingItem(
        id: map['id'] ?? '',
        description: map['description'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'amount': amount,
      };

  BillingItem copyWith({String? id, String? description, double? amount}) =>
      BillingItem(
        id: id ?? this.id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
      );
}

/// A single EMI payment entry
class PaymentEntry {
  final String id;
  final DateTime date;
  final double amount;
  final String paymentMode;
  final String notes;

  PaymentEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.paymentMode,
    this.notes = '',
  });

  factory PaymentEntry.fromMap(Map<String, dynamic> map) => PaymentEntry(
        id: map['id'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        amount: (map['amount'] ?? 0).toDouble(),
        paymentMode: map['paymentMode'] ?? '',
        notes: map['notes'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': Timestamp.fromDate(date),
        'amount': amount,
        'paymentMode': paymentMode,
        'notes': notes,
      };
}

/// Inventory checklist model
class InventoryChecklist {
  final bool keyRemote;
  final bool audioSystem;
  final bool cdDvdChanger;
  final int speakers;
  final bool ownerManual;
  final bool mobileCharger;
  final bool keyChain;
  final int dollIdol;
  final bool airFreshener;
  final bool upholsteryTornBroken;
  final int floorMat;
  final String seatCovers;
  final bool jackHandle;
  final bool underbodyDamages;
  final bool bootMat;
  final bool firstAidKit;
  final String toolList;
  final bool wheelCoverCap;
  final bool mudFlaps;
  final bool spareWheel;
  final int sideMirror;
  final int fogLamp;
  final bool wiperArmsBlades;
  final bool fuelCap;
  final bool hornLowHigh;
  final String others;

  const InventoryChecklist({
    this.keyRemote = false,
    this.audioSystem = false,
    this.cdDvdChanger = false,
    this.speakers = 0,
    this.ownerManual = false,
    this.mobileCharger = false,
    this.keyChain = false,
    this.dollIdol = 0,
    this.airFreshener = false,
    this.upholsteryTornBroken = false,
    this.floorMat = 0,
    this.seatCovers = '',
    this.jackHandle = false,
    this.underbodyDamages = false,
    this.bootMat = false,
    this.firstAidKit = false,
    this.toolList = '',
    this.wheelCoverCap = false,
    this.mudFlaps = false,
    this.spareWheel = false,
    this.sideMirror = 0,
    this.fogLamp = 0,
    this.wiperArmsBlades = false,
    this.fuelCap = false,
    this.hornLowHigh = false,
    this.others = '',
  });

  factory InventoryChecklist.fromMap(Map<String, dynamic> map) =>
      InventoryChecklist(
        keyRemote: map['keyRemote'] ?? false,
        audioSystem: map['audioSystem'] ?? false,
        cdDvdChanger: map['cdDvdChanger'] ?? false,
        speakers: map['speakers'] ?? 0,
        ownerManual: map['ownerManual'] ?? false,
        mobileCharger: map['mobileCharger'] ?? false,
        keyChain: map['keyChain'] ?? false,
        dollIdol: map['dollIdol'] ?? 0,
        airFreshener: map['airFreshener'] ?? false,
        upholsteryTornBroken: map['upholsteryTornBroken'] ?? false,
        floorMat: map['floorMat'] ?? 0,
        seatCovers: map['seatCovers'] ?? '',
        jackHandle: map['jackHandle'] ?? false,
        underbodyDamages: map['underbodyDamages'] ?? false,
        bootMat: map['bootMat'] ?? false,
        firstAidKit: map['firstAidKit'] ?? false,
        toolList: map['toolList'] ?? '',
        wheelCoverCap: map['wheelCoverCap'] ?? false,
        mudFlaps: map['mudFlaps'] ?? false,
        spareWheel: map['spareWheel'] ?? false,
        sideMirror: map['sideMirror'] ?? 0,
        fogLamp: map['fogLamp'] ?? 0,
        wiperArmsBlades: map['wiperArmsBlades'] ?? false,
        fuelCap: map['fuelCap'] ?? false,
        hornLowHigh: map['hornLowHigh'] ?? false,
        others: map['others'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'keyRemote': keyRemote,
        'audioSystem': audioSystem,
        'cdDvdChanger': cdDvdChanger,
        'speakers': speakers,
        'ownerManual': ownerManual,
        'mobileCharger': mobileCharger,
        'keyChain': keyChain,
        'dollIdol': dollIdol,
        'airFreshener': airFreshener,
        'upholsteryTornBroken': upholsteryTornBroken,
        'floorMat': floorMat,
        'seatCovers': seatCovers,
        'jackHandle': jackHandle,
        'underbodyDamages': underbodyDamages,
        'bootMat': bootMat,
        'firstAidKit': firstAidKit,
        'toolList': toolList,
        'wheelCoverCap': wheelCoverCap,
        'mudFlaps': mudFlaps,
        'spareWheel': spareWheel,
        'sideMirror': sideMirror,
        'fogLamp': fogLamp,
        'wiperArmsBlades': wiperArmsBlades,
        'fuelCap': fuelCap,
        'hornLowHigh': hornLowHigh,
        'others': others,
      };

  InventoryChecklist copyWith({
    bool? keyRemote,
    bool? audioSystem,
    bool? cdDvdChanger,
    int? speakers,
    bool? ownerManual,
    bool? mobileCharger,
    bool? keyChain,
    int? dollIdol,
    bool? airFreshener,
    bool? upholsteryTornBroken,
    int? floorMat,
    String? seatCovers,
    bool? jackHandle,
    bool? underbodyDamages,
    bool? bootMat,
    bool? firstAidKit,
    String? toolList,
    bool? wheelCoverCap,
    bool? mudFlaps,
    bool? spareWheel,
    int? sideMirror,
    int? fogLamp,
    bool? wiperArmsBlades,
    bool? fuelCap,
    bool? hornLowHigh,
    String? others,
  }) =>
      InventoryChecklist(
        keyRemote: keyRemote ?? this.keyRemote,
        audioSystem: audioSystem ?? this.audioSystem,
        cdDvdChanger: cdDvdChanger ?? this.cdDvdChanger,
        speakers: speakers ?? this.speakers,
        ownerManual: ownerManual ?? this.ownerManual,
        mobileCharger: mobileCharger ?? this.mobileCharger,
        keyChain: keyChain ?? this.keyChain,
        dollIdol: dollIdol ?? this.dollIdol,
        airFreshener: airFreshener ?? this.airFreshener,
        upholsteryTornBroken: upholsteryTornBroken ?? this.upholsteryTornBroken,
        floorMat: floorMat ?? this.floorMat,
        seatCovers: seatCovers ?? this.seatCovers,
        jackHandle: jackHandle ?? this.jackHandle,
        underbodyDamages: underbodyDamages ?? this.underbodyDamages,
        bootMat: bootMat ?? this.bootMat,
        firstAidKit: firstAidKit ?? this.firstAidKit,
        toolList: toolList ?? this.toolList,
        wheelCoverCap: wheelCoverCap ?? this.wheelCoverCap,
        mudFlaps: mudFlaps ?? this.mudFlaps,
        spareWheel: spareWheel ?? this.spareWheel,
        sideMirror: sideMirror ?? this.sideMirror,
        fogLamp: fogLamp ?? this.fogLamp,
        wiperArmsBlades: wiperArmsBlades ?? this.wiperArmsBlades,
        fuelCap: fuelCap ?? this.fuelCap,
        hornLowHigh: hornLowHigh ?? this.hornLowHigh,
        others: others ?? this.others,
      );
}

/// Mechanical service checklist
class MechanicalChecklist {
  final bool coolantLeakage;
  final bool clutchOperation;
  final bool transmissionOil;
  final bool handBrake;
  final bool steeringCheck;
  final bool doorFunctions;
  final bool engineOilReplace;
  final bool brakeClutchFluid;
  final bool wipersCheck;
  final bool headTailLamp;
  final bool acMovement;
  final bool suspension;
  final bool batteryWaterLevel;
  final bool tyreInflation;
  final bool switchesCheck;
  final bool brakePadLinear;

  const MechanicalChecklist({
    this.coolantLeakage = false,
    this.clutchOperation = false,
    this.transmissionOil = false,
    this.handBrake = false,
    this.steeringCheck = false,
    this.doorFunctions = false,
    this.engineOilReplace = false,
    this.brakeClutchFluid = false,
    this.wipersCheck = false,
    this.headTailLamp = false,
    this.acMovement = false,
    this.suspension = false,
    this.batteryWaterLevel = false,
    this.tyreInflation = false,
    this.switchesCheck = false,
    this.brakePadLinear = false,
  });

  factory MechanicalChecklist.fromMap(Map<String, dynamic> map) =>
      MechanicalChecklist(
        coolantLeakage: map['coolantLeakage'] ?? false,
        clutchOperation: map['clutchOperation'] ?? false,
        transmissionOil: map['transmissionOil'] ?? false,
        handBrake: map['handBrake'] ?? false,
        steeringCheck: map['steeringCheck'] ?? false,
        doorFunctions: map['doorFunctions'] ?? false,
        engineOilReplace: map['engineOilReplace'] ?? false,
        brakeClutchFluid: map['brakeClutchFluid'] ?? false,
        wipersCheck: map['wipersCheck'] ?? false,
        headTailLamp: map['headTailLamp'] ?? false,
        acMovement: map['acMovement'] ?? false,
        suspension: map['suspension'] ?? false,
        batteryWaterLevel: map['batteryWaterLevel'] ?? false,
        tyreInflation: map['tyreInflation'] ?? false,
        switchesCheck: map['switchesCheck'] ?? false,
        brakePadLinear: map['brakePadLinear'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'coolantLeakage': coolantLeakage,
        'clutchOperation': clutchOperation,
        'transmissionOil': transmissionOil,
        'handBrake': handBrake,
        'steeringCheck': steeringCheck,
        'doorFunctions': doorFunctions,
        'engineOilReplace': engineOilReplace,
        'brakeClutchFluid': brakeClutchFluid,
        'wipersCheck': wipersCheck,
        'headTailLamp': headTailLamp,
        'acMovement': acMovement,
        'suspension': suspension,
        'batteryWaterLevel': batteryWaterLevel,
        'tyreInflation': tyreInflation,
        'switchesCheck': switchesCheck,
        'brakePadLinear': brakePadLinear,
      };

  MechanicalChecklist copyWith({
    bool? coolantLeakage,
    bool? clutchOperation,
    bool? transmissionOil,
    bool? handBrake,
    bool? steeringCheck,
    bool? doorFunctions,
    bool? engineOilReplace,
    bool? brakeClutchFluid,
    bool? wipersCheck,
    bool? headTailLamp,
    bool? acMovement,
    bool? suspension,
    bool? batteryWaterLevel,
    bool? tyreInflation,
    bool? switchesCheck,
    bool? brakePadLinear,
  }) =>
      MechanicalChecklist(
        coolantLeakage: coolantLeakage ?? this.coolantLeakage,
        clutchOperation: clutchOperation ?? this.clutchOperation,
        transmissionOil: transmissionOil ?? this.transmissionOil,
        handBrake: handBrake ?? this.handBrake,
        steeringCheck: steeringCheck ?? this.steeringCheck,
        doorFunctions: doorFunctions ?? this.doorFunctions,
        engineOilReplace: engineOilReplace ?? this.engineOilReplace,
        brakeClutchFluid: brakeClutchFluid ?? this.brakeClutchFluid,
        wipersCheck: wipersCheck ?? this.wipersCheck,
        headTailLamp: headTailLamp ?? this.headTailLamp,
        acMovement: acMovement ?? this.acMovement,
        suspension: suspension ?? this.suspension,
        batteryWaterLevel: batteryWaterLevel ?? this.batteryWaterLevel,
        tyreInflation: tyreInflation ?? this.tyreInflation,
        switchesCheck: switchesCheck ?? this.switchesCheck,
        brakePadLinear: brakePadLinear ?? this.brakePadLinear,
      );
}

/// Central Job Card model
class JobCardModel {
  final String id;
  final String roNumber;
  final DateTime entryDate;
  final DateTime inTime;
  DateTime? outTime;

  // Customer Info
  final String customerName;
  final String address;
  final String contactNumber;
  final String alternateNumber;

  // Vehicle Info
  final String vehicleMake;
  final String vehicleModel;
  final String registrationNumber;
  final String chassisNumber;
  final String engineNumber;
  final String kmReading;

  // Checklists
  final InventoryChecklist inventoryChecklist;
  final MechanicalChecklist mechanicalChecklist;

  // Images
  final Map<String, String> inspectionImages; // key: slot name, value: URL
  final String? fuelGaugeImage;
  final String damageNotes;

  // Jobs
  final List<String> demandedJobs;
  final List<String> recommendedJobs;

  // Billing
  final List<BillingItem> labourItems;
  final List<BillingItem> subletItems;
  final double spareParts;
  final double labourGst;
  final double advance;

  // EMI Payments
  final List<PaymentEntry> payments;

  // Status
  final JobStatus status;
  final PaymentStatus paymentStatus;

  // Authorization
  final String? customerSignatureUrl;
  final String? managerSignatureUrl;
  final String receivedBy;
  final String deliveryNotes;

  // Meta
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobCardModel({
    required this.id,
    required this.roNumber,
    required this.entryDate,
    required this.inTime,
    this.outTime,
    required this.customerName,
    required this.address,
    required this.contactNumber,
    required this.alternateNumber,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.registrationNumber,
    required this.chassisNumber,
    required this.engineNumber,
    required this.kmReading,
    this.inventoryChecklist = const InventoryChecklist(),
    this.mechanicalChecklist = const MechanicalChecklist(),
    this.inspectionImages = const {},
    this.fuelGaugeImage,
    this.damageNotes = '',
    this.demandedJobs = const [],
    this.recommendedJobs = const [],
    this.labourItems = const [],
    this.subletItems = const [],
    this.spareParts = 0,
    this.labourGst = 18,
    this.advance = 0,
    this.payments = const [],
    this.status = JobStatus.open,
    this.paymentStatus = PaymentStatus.pending,
    this.customerSignatureUrl,
    this.managerSignatureUrl,
    this.receivedBy = '',
    this.deliveryNotes = '',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // --- Computed Totals ---
  double get labourTotal => labourItems.fold(0, (sum, i) => sum + i.amount);
  double get labourGstAmount => labourTotal * (labourGst / 100);
  double get subletTotal => subletItems.fold(0, (sum, i) => sum + i.amount);
  double get grandTotal =>
      spareParts + labourTotal + labourGstAmount + subletTotal;
  double get totalPaid =>
      payments.fold(0.0, (sum, p) => sum + p.amount) + advance;
  double get balanceDue => grandTotal - totalPaid;
  bool get hasBalance => balanceDue > 0;

  Duration? get serviceDuration =>
      outTime != null ? outTime!.difference(inTime) : null;

  factory JobCardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobCardModel(
      id: doc.id,
      roNumber: data['roNumber'] ?? '',
      entryDate: (data['entryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inTime: (data['inTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      outTime: (data['outTime'] as Timestamp?)?.toDate(),
      customerName: data['customerName'] ?? '',
      address: data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      alternateNumber: data['alternateNumber'] ?? '',
      vehicleMake: data['vehicleMake'] ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      chassisNumber: data['chassisNumber'] ?? '',
      engineNumber: data['engineNumber'] ?? '',
      kmReading: data['kmReading'] ?? '',
      inventoryChecklist: data['inventoryChecklist'] != null
          ? InventoryChecklist.fromMap(data['inventoryChecklist'])
          : const InventoryChecklist(),
      mechanicalChecklist: data['mechanicalChecklist'] != null
          ? MechanicalChecklist.fromMap(data['mechanicalChecklist'])
          : const MechanicalChecklist(),
      inspectionImages:
          Map<String, String>.from(data['inspectionImages'] ?? {}),
      fuelGaugeImage: data['fuelGaugeImage'],
      damageNotes: data['damageNotes'] ?? '',
      demandedJobs: List<String>.from(data['demandedJobs'] ?? []),
      recommendedJobs: List<String>.from(data['recommendedJobs'] ?? []),
      labourItems: (data['labourItems'] as List<dynamic>? ?? [])
          .map((e) => BillingItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      subletItems: (data['subletItems'] as List<dynamic>? ?? [])
          .map((e) => BillingItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      spareParts: (data['spareParts'] ?? 0).toDouble(),
      labourGst: (data['labourGst'] ?? 18).toDouble(),
      advance: (data['advance'] ?? 0).toDouble(),
      payments: (data['payments'] as List<dynamic>? ?? [])
          .map((e) => PaymentEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      status: JobStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'open'),
        orElse: () => JobStatus.open,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (s) => s.name == (data['paymentStatus'] ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
      customerSignatureUrl: data['customerSignatureUrl'],
      managerSignatureUrl: data['managerSignatureUrl'],
      receivedBy: data['receivedBy'] ?? '',
      deliveryNotes: data['deliveryNotes'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    // Compute payment status
    final ps = balanceDue <= 0
        ? PaymentStatus.paid
        : totalPaid > 0
            ? PaymentStatus.partial
            : PaymentStatus.pending;

    return {
      'roNumber': roNumber,
      'entryDate': Timestamp.fromDate(entryDate),
      'inTime': Timestamp.fromDate(inTime),
      'outTime': outTime != null ? Timestamp.fromDate(outTime!) : null,
      'customerName': customerName,
      'address': address,
      'contactNumber': contactNumber,
      'alternateNumber': alternateNumber,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'registrationNumber': registrationNumber,
      'chassisNumber': chassisNumber,
      'engineNumber': engineNumber,
      'kmReading': kmReading,
      'inventoryChecklist': inventoryChecklist.toMap(),
      'mechanicalChecklist': mechanicalChecklist.toMap(),
      'inspectionImages': inspectionImages,
      'fuelGaugeImage': fuelGaugeImage,
      'damageNotes': damageNotes,
      'demandedJobs': demandedJobs,
      'recommendedJobs': recommendedJobs,
      'labourItems': labourItems.map((e) => e.toMap()).toList(),
      'subletItems': subletItems.map((e) => e.toMap()).toList(),
      'spareParts': spareParts,
      'labourGst': labourGst,
      'advance': advance,
      'payments': payments.map((e) => e.toMap()).toList(),
      'grandTotal': grandTotal,
      'totalPaid': totalPaid,
      'balanceDue': balanceDue,
      'status': status.name,
      'paymentStatus': ps.name,
      'customerSignatureUrl': customerSignatureUrl,
      'managerSignatureUrl': managerSignatureUrl,
      'receivedBy': receivedBy,
      'deliveryNotes': deliveryNotes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  JobCardModel copyWith({
    String? id,
    String? roNumber,
    DateTime? entryDate,
    DateTime? inTime,
    DateTime? outTime,
    String? customerName,
    String? address,
    String? contactNumber,
    String? alternateNumber,
    String? vehicleMake,
    String? vehicleModel,
    String? registrationNumber,
    String? chassisNumber,
    String? engineNumber,
    String? kmReading,
    InventoryChecklist? inventoryChecklist,
    MechanicalChecklist? mechanicalChecklist,
    Map<String, String>? inspectionImages,
    String? fuelGaugeImage,
    String? damageNotes,
    List<String>? demandedJobs,
    List<String>? recommendedJobs,
    List<BillingItem>? labourItems,
    List<BillingItem>? subletItems,
    double? spareParts,
    double? labourGst,
    double? advance,
    List<PaymentEntry>? payments,
    JobStatus? status,
    PaymentStatus? paymentStatus,
    String? customerSignatureUrl,
    String? managerSignatureUrl,
    String? receivedBy,
    String? deliveryNotes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      JobCardModel(
        id: id ?? this.id,
        roNumber: roNumber ?? this.roNumber,
        entryDate: entryDate ?? this.entryDate,
        inTime: inTime ?? this.inTime,
        outTime: outTime ?? this.outTime,
        customerName: customerName ?? this.customerName,
        address: address ?? this.address,
        contactNumber: contactNumber ?? this.contactNumber,
        alternateNumber: alternateNumber ?? this.alternateNumber,
        vehicleMake: vehicleMake ?? this.vehicleMake,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        registrationNumber: registrationNumber ?? this.registrationNumber,
        chassisNumber: chassisNumber ?? this.chassisNumber,
        engineNumber: engineNumber ?? this.engineNumber,
        kmReading: kmReading ?? this.kmReading,
        inventoryChecklist: inventoryChecklist ?? this.inventoryChecklist,
        mechanicalChecklist: mechanicalChecklist ?? this.mechanicalChecklist,
        inspectionImages: inspectionImages ?? this.inspectionImages,
        fuelGaugeImage: fuelGaugeImage ?? this.fuelGaugeImage,
        damageNotes: damageNotes ?? this.damageNotes,
        demandedJobs: demandedJobs ?? this.demandedJobs,
        recommendedJobs: recommendedJobs ?? this.recommendedJobs,
        labourItems: labourItems ?? this.labourItems,
        subletItems: subletItems ?? this.subletItems,
        spareParts: spareParts ?? this.spareParts,
        labourGst: labourGst ?? this.labourGst,
        advance: advance ?? this.advance,
        payments: payments ?? this.payments,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        customerSignatureUrl: customerSignatureUrl ?? this.customerSignatureUrl,
        managerSignatureUrl: managerSignatureUrl ?? this.managerSignatureUrl,
        receivedBy: receivedBy ?? this.receivedBy,
        deliveryNotes: deliveryNotes ?? this.deliveryNotes,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
