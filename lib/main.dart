import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';

// ---------------------------------------------------------------------------
// 1. CONFIGURATION
// ---------------------------------------------------------------------------

const String kGeminiApiKey = "";

// ---------------------------------------------------------------------------
// 2. DATA MODELS
// ---------------------------------------------------------------------------

class Resume {
  final String id;
  String title;
  String templateId;
  DateTime lastUpdated;
  PersonalInfo personalInfo;
  String objective;
  String summary;
  String portfolioUrl;
  List<ExperienceItem> experience;
  List<EducationItem> education;
  List<String> skills;
  List<String> languages;
  List<String> certificates;
  List<ReferenceItem> references;
  List<CustomSection> customSections;

  bool showObjective;
  bool showSummary;
  bool showExperience;
  bool showEducation;
  bool showSkills;
  bool showLanguages;
  bool showCertificates;
  bool showReferences;
  bool showQrCode;

  Resume({
    required this.id,
    required this.title,
    this.templateId = 'modern_blue',
    required this.lastUpdated,
    required this.personalInfo,
    this.objective = "",
    this.summary = "",
    this.portfolioUrl = "",
    List<ExperienceItem>? experience,
    List<EducationItem>? education,
    List<String>? skills,
    List<String>? languages,
    List<String>? certificates,
    List<ReferenceItem>? references,
    List<CustomSection>? customSections,
    this.showObjective = true,
    this.showSummary = true,
    this.showExperience = true,
    this.showEducation = true,
    this.showSkills = true,
    this.showLanguages = true,
    this.showCertificates = true,
    this.showReferences = true,
    this.showQrCode = true,
  }) : experience = experience ?? [],
       education = education ?? [],
       skills = skills ?? [],
       languages = languages ?? [],
       certificates = certificates ?? [],
       references = references ?? [],
       customSections = customSections ?? [];

  double get score {
    double s = 0;
    if (personalInfo.fullName.isNotEmpty) s += 10;
    if (personalInfo.email.isNotEmpty) s += 5;
    if (summary.isNotEmpty) s += 15;
    if (experience.isNotEmpty) s += 25;
    if (education.isNotEmpty) s += 15;
    if (skills.isNotEmpty) s += 15;
    if (languages.isNotEmpty) s += 5;
    if (references.isNotEmpty) s += 5;
    if (portfolioUrl.isNotEmpty) s += 5;
    return s.clamp(0.0, 100.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'templateId': templateId,
      'lastUpdated': lastUpdated.toIso8601String(),
      'personalInfo': personalInfo.toMap(),
      'objective': objective,
      'summary': summary,
      'portfolioUrl': portfolioUrl,
      'experience': experience.map((x) => x.toMap()).toList(),
      'education': education.map((x) => x.toMap()).toList(),
      'skills': skills,
      'languages': languages,
      'certificates': certificates,
      'references': references.map((x) => x.toMap()).toList(),
      'customSections': customSections.map((x) => x.toMap()).toList(),
      'showObjective': showObjective,
      'showSummary': showSummary,
      'showExperience': showExperience,
      'showEducation': showEducation,
      'showSkills': showSkills,
      'showLanguages': showLanguages,
      'showCertificates': showCertificates,
      'showReferences': showReferences,
      'showQrCode': showQrCode,
    };
  }

  factory Resume.fromMap(Map<String, dynamic> map) {
    return Resume(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled',
      templateId: map['templateId']?.toString() ?? 'modern_blue',
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'].toString()) ?? DateTime.now()
          : DateTime.now(),
      personalInfo: PersonalInfo.fromMap(
        Map<String, dynamic>.from(map['personalInfo'] as Map? ?? {}),
      ),
      objective: map['objective']?.toString() ?? '',
      summary: map['summary']?.toString() ?? '',
      portfolioUrl: map['portfolioUrl']?.toString() ?? '',
      experience:
          (map['experience'] as List?)
              ?.map(
                (x) => ExperienceItem.fromMap(
                  Map<String, dynamic>.from(x as Map? ?? {}),
                ),
              )
              .toList() ??
          [],
      education:
          (map['education'] as List?)
              ?.map(
                (x) => EducationItem.fromMap(
                  Map<String, dynamic>.from(x as Map? ?? {}),
                ),
              )
              .toList() ??
          [],
      skills: (map['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      languages:
          (map['languages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      certificates:
          (map['certificates'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      references:
          (map['references'] as List?)
              ?.map(
                (x) => ReferenceItem.fromMap(
                  Map<String, dynamic>.from(x as Map? ?? {}),
                ),
              )
              .toList() ??
          [],
      customSections:
          (map['customSections'] as List?)
              ?.map(
                (x) => CustomSection.fromMap(
                  Map<String, dynamic>.from(x as Map? ?? {}),
                ),
              )
              .toList() ??
          [],
      showObjective: map['showObjective'] ?? true,
      showSummary: map['showSummary'] ?? true,
      showExperience: map['showExperience'] ?? true,
      showEducation: map['showEducation'] ?? true,
      showSkills: map['showSkills'] ?? true,
      showLanguages: map['showLanguages'] ?? true,
      showCertificates: map['showCertificates'] ?? true,
      showReferences: map['showReferences'] ?? true,
      showQrCode: map['showQrCode'] ?? true,
    );
  }
}

class CustomSection {
  String id;
  String title;
  String content;

  CustomSection({required this.id, this.title = "", this.content = ""});

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
  };

  factory CustomSection.fromMap(Map<String, dynamic> map) => CustomSection(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    content: map['content'] ?? '',
  );
}

class PersonalInfo {
  String fullName;
  String email;
  String phone;
  String jobTitle;
  String address;
  PersonalInfo({
    this.fullName = "",
    this.email = "",
    this.phone = "",
    this.jobTitle = "",
    this.address = "",
  });
  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'jobTitle': jobTitle,
    'address': address,
  };
  factory PersonalInfo.fromMap(Map<String, dynamic> map) => PersonalInfo(
    fullName: map['fullName'] ?? '',
    email: map['email'] ?? '',
    phone: map['phone'] ?? '',
    jobTitle: map['jobTitle'] ?? '',
    address: map['address'] ?? '',
  );
}

class ExperienceItem {
  final String id;
  String jobTitle;
  String company;
  String startDate;
  String endDate;
  String description;
  ExperienceItem({
    required this.id,
    this.jobTitle = "",
    this.company = "",
    this.startDate = "",
    this.endDate = "",
    this.description = "",
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'jobTitle': jobTitle,
    'company': company,
    'startDate': startDate,
    'endDate': endDate,
    'description': description,
  };
  factory ExperienceItem.fromMap(Map<String, dynamic> map) => ExperienceItem(
    id: map['id'] ?? '',
    jobTitle: map['jobTitle'] ?? '',
    company: map['company'] ?? '',
    startDate: map['startDate'] ?? '',
    endDate: map['endDate'] ?? '',
    description: map['description'] ?? '',
  );
}

class EducationItem {
  final String id;
  String school;
  String degree;
  String startDate;
  String endDate;
  EducationItem({
    required this.id,
    this.school = "",
    this.degree = "",
    this.startDate = "",
    this.endDate = "",
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'school': school,
    'degree': degree,
    'startDate': startDate,
    'endDate': endDate,
  };
  factory EducationItem.fromMap(Map<String, dynamic> map) => EducationItem(
    id: map['id'] ?? '',
    school: map['school'] ?? '',
    degree: map['degree'] ?? '',
    startDate: map['startDate'] ?? '',
    endDate: map['endDate'] ?? '',
  );
}

class ReferenceItem {
  final String id;
  String name;
  String company;
  String contact;
  ReferenceItem({
    required this.id,
    this.name = "",
    this.company = "",
    this.contact = "",
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'company': company,
    'contact': contact,
  };
  factory ReferenceItem.fromMap(Map<String, dynamic> map) => ReferenceItem(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    company: map['company'] ?? '',
    contact: map['contact'] ?? '',
  );
}

// ---------------------------------------------------------------------------
// 3. STATE MANAGEMENT
// ---------------------------------------------------------------------------

class ResumeProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? _user;
  Resume? _currentResume;
  bool _isLoading = true;

  User? get user => _user;
  Resume? get currentResume => _currentResume;
  bool get isLoading => _isLoading;

  ResumeProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      _user = _auth.currentUser;
      if (_user == null) {
        UserCredential cred = await _auth.signInAnonymously();
        _user = cred.user;
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<Resume>> getResumesStream() {
    if (_user == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_user!.uid)
        .collection('resumes')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Resume.fromMap(d.data())).toList());
  }

  Future<void> createNewResume() async {
    if (_user == null) return;
    final String newId = const Uuid().v4();
    final newResume = Resume(
      id: newId,
      title: "Untitled Resume",
      lastUpdated: DateTime.now(),
      personalInfo: PersonalInfo(),
    );
    _currentResume = newResume;
    await _db
        .collection('users')
        .doc(_user!.uid)
        .collection('resumes')
        .doc(newId)
        .set(newResume.toMap());
    notifyListeners();
  }

  // --- DUPLICATE & DELETE FUNCTIONS ADDED HERE ---
  Future<void> duplicateResume(Resume r) async {
    if (_user == null) return;
    final String newId = const Uuid().v4();

    final newResume = Resume(
      id: newId,
      title: "Copy of ${r.title}", // Add "Copy of" prefix
      templateId: r.templateId,
      lastUpdated: DateTime.now(),
      personalInfo: r.personalInfo,
      objective: r.objective,
      summary: r.summary,
      portfolioUrl: r.portfolioUrl,
      experience: r.experience,
      education: r.education,
      skills: r.skills,
      languages: r.languages,
      certificates: r.certificates,
      references: r.references,
      customSections: r.customSections,
      showObjective: r.showObjective,
      showSummary: r.showSummary,
      showExperience: r.showExperience,
      showEducation: r.showEducation,
      showSkills: r.showSkills,
      showLanguages: r.showLanguages,
      showCertificates: r.showCertificates,
      showReferences: r.showReferences,
      showQrCode: r.showQrCode,
    );

    await _db
        .collection('users')
        .doc(_user!.uid)
        .collection('resumes')
        .doc(newId)
        .set(newResume.toMap());
  }

  Future<void> deleteResume(String id) async {
    if (_user == null) return;
    await _db
        .collection('users')
        .doc(_user!.uid)
        .collection('resumes')
        .doc(id)
        .delete();
  }
  // ----------------------------------------------

  void selectResume(Resume resume) {
    _currentResume = resume;
    notifyListeners();
  }

  Future<void> updateTemplate(String newTemplateId) async {
    if (_currentResume == null) return;
    _currentResume!.templateId = newTemplateId;
    await _save();
  }

  Future<void> _save() async {
    if (_currentResume == null || _user == null) return;

    final updatedResume = Resume(
      id: _currentResume!.id,
      title: _currentResume!.title,
      templateId: _currentResume!.templateId,
      lastUpdated: DateTime.now(),
      personalInfo: _currentResume!.personalInfo,
      objective: _currentResume!.objective,
      summary: _currentResume!.summary,
      portfolioUrl: _currentResume!.portfolioUrl,
      experience: _currentResume!.experience,
      education: _currentResume!.education,
      skills: _currentResume!.skills,
      languages: _currentResume!.languages,
      certificates: _currentResume!.certificates,
      references: _currentResume!.references,
      customSections: _currentResume!.customSections,
      showObjective: _currentResume!.showObjective,
      showSummary: _currentResume!.showSummary,
      showExperience: _currentResume!.showExperience,
      showEducation: _currentResume!.showEducation,
      showSkills: _currentResume!.showSkills,
      showLanguages: _currentResume!.showLanguages,
      showCertificates: _currentResume!.showCertificates,
      showReferences: _currentResume!.showReferences,
      showQrCode: _currentResume!.showQrCode,
    );

    _currentResume = updatedResume;
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(_user!.uid)
          .collection('resumes')
          .doc(_currentResume!.id)
          .update(_currentResume!.toMap());
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  Future<void> toggleSection(String section) async {
    if (_currentResume == null) return;
    switch (section) {
      case 'Objective':
        _currentResume!.showObjective = !_currentResume!.showObjective;
        break;
      case 'Summary':
        _currentResume!.showSummary = !_currentResume!.showSummary;
        break;
      case 'Experience':
        _currentResume!.showExperience = !_currentResume!.showExperience;
        break;
      case 'Education':
        _currentResume!.showEducation = !_currentResume!.showEducation;
        break;
      case 'Skills':
        _currentResume!.showSkills = !_currentResume!.showSkills;
        break;
      case 'Languages':
        _currentResume!.showLanguages = !_currentResume!.showLanguages;
        break;
      case 'Certificates':
        _currentResume!.showCertificates = !_currentResume!.showCertificates;
        break;
      case 'References':
        _currentResume!.showReferences = !_currentResume!.showReferences;
        break;
      case 'QR Code':
        _currentResume!.showQrCode = !_currentResume!.showQrCode;
        break;
    }
    await _save();
  }

  // --- CUSTOM SECTIONS METHODS ---
  Future<void> addCustomSection(String title) async {
    if (_currentResume == null) return;
    final newSection = CustomSection(
      id: const Uuid().v4(),
      title: title,
      content: "",
    );
    _currentResume!.customSections.add(newSection);
    await _save();
  }

  Future<void> updateCustomSection(String id, String content) async {
    if (_currentResume == null) return;
    final index = _currentResume!.customSections.indexWhere((s) => s.id == id);
    if (index != -1) {
      _currentResume!.customSections[index].content = content;
      await _save();
    }
  }

  Future<void> removeCustomSection(String id) async {
    if (_currentResume == null) return;
    _currentResume!.customSections.removeWhere((s) => s.id == id);
    await _save();
  }

  Future<void> updatePersonalInfo(
    String n,
    String e,
    String p,
    String r,
    String a,
  ) async {
    if (_currentResume == null) return;
    _currentResume!.personalInfo
      ..fullName = n
      ..email = e
      ..phone = p
      ..jobTitle = r
      ..address = a;
    await _save();
  }

  Future<void> updateSummary(String v) async {
    if (_currentResume != null) {
      _currentResume!.summary = v;
      await _save();
    }
  }

  Future<void> updateObjective(String v) async {
    if (_currentResume != null) {
      _currentResume!.objective = v;
      await _save();
    }
  }

  Future<void> updatePortfolioUrl(String v) async {
    if (_currentResume != null) {
      _currentResume!.portfolioUrl = v;
      await _save();
    }
  }

  Future<void> addExperience(ExperienceItem i) async {
    _currentResume?.experience.add(i);
    await _save();
  }

  Future<void> updateExperience(ExperienceItem i) async {
    int idx = _currentResume?.experience.indexWhere((e) => e.id == i.id) ?? -1;
    if (idx != -1) {
      _currentResume?.experience[idx] = i;
      await _save();
    }
  }

  Future<void> deleteExperience(String id) async {
    _currentResume?.experience.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> addEducation(EducationItem i) async {
    _currentResume?.education.add(i);
    await _save();
  }

  Future<void> updateEducation(EducationItem i) async {
    int idx = _currentResume?.education.indexWhere((e) => e.id == i.id) ?? -1;
    if (idx != -1) {
      _currentResume?.education[idx] = i;
      await _save();
    }
  }

  Future<void> deleteEducation(String id) async {
    _currentResume?.education.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> addReference(ReferenceItem i) async {
    _currentResume?.references.add(i);
    await _save();
  }

  Future<void> updateReference(ReferenceItem i) async {
    int idx = _currentResume?.references.indexWhere((e) => e.id == i.id) ?? -1;
    if (idx != -1) {
      _currentResume?.references[idx] = i;
      await _save();
    }
  }

  Future<void> deleteReference(String id) async {
    _currentResume?.references.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> updateSkills(List<String> l) async {
    _currentResume?.skills = l;
    await _save();
  }

  Future<void> updateLanguages(List<String> l) async {
    _currentResume?.languages = l;
    await _save();
  }

  Future<void> updateCertificates(List<String> l) async {
    _currentResume?.certificates = l;
    await _save();
  }
}

// ---------------------------------------------------------------------------
// 4. PDF GENERATION
// ---------------------------------------------------------------------------

Future<void> generateResumePdf(Resume resume) async {
  final pdf = pw.Document();

  final fontOpenSans = await PdfGoogleFonts.openSansRegular();
  final fontOpenSansBold = await PdfGoogleFonts.openSansBold();
  final fontOpenSansItalic = await PdfGoogleFonts.openSansItalic();

  final theme = pw.ThemeData.withFont(
    base: fontOpenSans,
    bold: fontOpenSansBold,
    italic: fontOpenSansItalic,
  );

  pw.Page pageLayout;

  // STRICT ID MATCHING - Ensuring all 6 work
  switch (resume.templateId) {
    case 'classic_green':
      pageLayout = _buildTemplateLayout(
        resume,
        theme,
        PdfColors.green800,
        PdfColors.green100,
        _SidebarPosition.topHeader,
      );
      break;
    case 'professional_red':
      pageLayout = _buildTemplateLayout(
        resume,
        theme,
        PdfColors.red800,
        PdfColors.red100,
        _SidebarPosition.topHeader,
      );
      break;
    case 'elegant_orange':
      pageLayout = _buildTemplateLayout(
        resume,
        theme,
        PdfColors.orange800,
        PdfColors.orange100,
        _SidebarPosition.right,
      );
      break;
    case 'creative_violet':
      pageLayout = _buildTemplateLayout(
        resume,
        theme,
        PdfColors.purple800,
        PdfColors.purple100,
        _SidebarPosition.left,
      );
      break;
    case 'clean_grey':
      pageLayout = _buildTemplateLayout(
        resume,
        theme,
        PdfColors.grey800,
        PdfColors.grey200,
        _SidebarPosition.right,
      );
      break;
    case 'modern_blue':
    default:
      pageLayout = _buildTemplateLayout(
        resume,
        theme,
        PdfColors.blue800,
        PdfColors.blue100,
        _SidebarPosition.left,
      );
      break;
  }

  pdf.addPage(pageLayout);
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

enum _SidebarPosition { left, right, topHeader }

// --- UNIVERSAL TEMPLATE BUILDER (FIXED) ---
// Corrected to avoid conflict between pageTheme and other settings
pw.Page _buildTemplateLayout(
  Resume r,
  pw.ThemeData theme,
  PdfColor primaryColor,
  PdfColor secondaryColor,
  _SidebarPosition position,
) {
  return pw.MultiPage(
    // REMOVED pageFormat, theme, margin here because they are in pageTheme
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.all(0),
      buildBackground: (context) {
        if (position == _SidebarPosition.left) {
          return pw.Row(
            children: [
              pw.Container(
                width: 180,
                height: double.infinity,
                color: primaryColor,
              ),
              pw.Expanded(child: pw.Container(color: PdfColors.white)),
            ],
          );
        } else if (position == _SidebarPosition.right) {
          return pw.Row(
            children: [
              pw.Expanded(child: pw.Container(color: PdfColors.white)),
              pw.Container(
                width: 180,
                height: double.infinity,
                color: primaryColor,
              ),
            ],
          );
        } else {
          return pw.Container();
        }
      },
    ),
    build: (pw.Context context) {
      // 1. Sidebar Content (Contact, Skills, Languages, QR)
      final isSidebarLayout =
          position == _SidebarPosition.left ||
          position == _SidebarPosition.right;
      final sidebarTextColor = isSidebarLayout
          ? PdfColors.white
          : PdfColors.black;
      final sidebarHeaderColor = isSidebarLayout
          ? PdfColors.white
          : primaryColor;

      final sidebarContent = [
        if (r.showQrCode && r.portfolioUrl.isNotEmpty) ...[
          pw.Center(
            child: pw.Container(
              height: 80,
              width: 80,
              padding: const pw.EdgeInsets.all(4),
              color: PdfColors.white,
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: r.portfolioUrl,
                drawText: false,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
        ],
        _buildSidebarSection(
          "CONTACT",
          [r.personalInfo.email, r.personalInfo.phone, r.personalInfo.address],
          sidebarHeaderColor,
          textColor: sidebarTextColor,
        ),
        if (r.showSkills && r.skills.isNotEmpty)
          _buildSidebarSection(
            "SKILLS",
            r.skills,
            sidebarHeaderColor,
            textColor: sidebarTextColor,
          ),
        if (r.showLanguages && r.languages.isNotEmpty)
          _buildSidebarSection(
            "LANGUAGES",
            r.languages,
            sidebarHeaderColor,
            textColor: sidebarTextColor,
          ),
      ];

      // 2. Main Content Body (WITHOUT HEADER INFO)
      final mainBodyContent = [
        if (r.showObjective && r.objective.isNotEmpty) ...[
          _buildMainSectionTitle("OBJECTIVE", primaryColor),
          pw.Text(r.objective, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 15),
        ],
        if (r.showSummary && r.summary.isNotEmpty) ...[
          _buildMainSectionTitle("SUMMARY", primaryColor),
          pw.Text(r.summary, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 15),
        ],
        if (r.showExperience && r.experience.isNotEmpty) ...[
          _buildMainSectionTitle("EXPERIENCE", primaryColor),
          ...r.experience.map(
            (e) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    e.jobTitle,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    "${e.company} | ${e.startDate} - ${e.endDate}",
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  if (e.description.isNotEmpty)
                    pw.Text(
                      e.description,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 10),
        ],
        if (r.showEducation && r.education.isNotEmpty) ...[
          _buildMainSectionTitle("EDUCATION", primaryColor),
          ...r.education.map(
            (e) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    e.school,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    "${e.degree} | ${e.startDate} - ${e.endDate}",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 10),
        ],
        if (r.showCertificates && r.certificates.isNotEmpty) ...[
          _buildMainSectionTitle("CERTIFICATES", primaryColor),
          ...r.certificates.map(
            (c) => pw.Bullet(text: c, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.SizedBox(height: 10),
        ],
        ...r.customSections.map(
          (cs) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildMainSectionTitle(cs.title.toUpperCase(), primaryColor),
              pw.Text(cs.content, style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 10),
            ],
          ),
        ),
        if (r.showReferences && r.references.isNotEmpty) ...[
          _buildMainSectionTitle("REFERENCES", primaryColor),
          ...r.references.map(
            (ref) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  ref.name,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  "${ref.company} | ${ref.contact}",
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 5),
              ],
            ),
          ),
        ],
      ];

      // --- LAYOUT LOGIC ---

      if (position == _SidebarPosition.topHeader) {
        // Top Header Layout
        return [
          // Header Widget (Fixed)
          pw.Container(
            color: primaryColor,
            padding: const pw.EdgeInsets.all(20),
            width: double.infinity,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      r.personalInfo.fullName.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      r.personalInfo.jobTitle.toUpperCase(),
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 16),
                    ),
                  ],
                ),
                if (r.showQrCode && r.portfolioUrl.isNotEmpty)
                  pw.Container(
                    height: 60,
                    width: 60,
                    padding: const pw.EdgeInsets.all(2),
                    color: PdfColors.white,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: r.portfolioUrl,
                      drawText: false,
                    ),
                  ),
              ],
            ),
          ),
          // Body using Partitions
          pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Partitions(
              children: [
                pw.Partition(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    // No need to filter strings/widgets here as we separated mainBodyContent
                    children: mainBodyContent,
                  ),
                ),
                pw.Partition(
                  width: 20,
                  child: pw.SizedBox(width: 20), // FIXED: Added required child
                ),
                pw.Partition(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: sidebarContent,
                  ),
                ),
              ],
            ),
          ),
        ];
      } else {
        // Sidebar Left/Right Layouts
        // We include the header info (Name/Title) in the main column here
        final combinedMainContent = [
          pw.Text(
            r.personalInfo.fullName.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: isSidebarLayout ? primaryColor : PdfColors.black,
            ),
          ),
          pw.Text(
            r.personalInfo.jobTitle.toUpperCase(),
            style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          ...mainBodyContent,
        ];

        final sidebarPart = pw.Partition(
          width: 180,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: sidebarContent,
            ),
          ),
        );

        final mainPart = pw.Partition(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: combinedMainContent,
            ),
          ),
        );

        return [
          pw.Partitions(
            children: position == _SidebarPosition.left
                ? [sidebarPart, mainPart]
                : [mainPart, sidebarPart],
          ),
        ];
      }
    },
  );
}

pw.Widget _buildSidebarSection(
  String title,
  List<String> items,
  PdfColor headerColor, {
  PdfColor textColor = PdfColors.white,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          color: headerColor,
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
      ),
      pw.Divider(color: headerColor, thickness: 1),
      ...items
          .where((i) => i.isNotEmpty)
          .map(
            (i) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                i,
                style: pw.TextStyle(color: textColor, fontSize: 10),
              ),
            ),
          ),
      pw.SizedBox(height: 20),
    ],
  );
}

pw.Widget _buildMainSectionTitle(String title, PdfColor color) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: color,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
      pw.Divider(color: color, thickness: 1),
      pw.SizedBox(height: 5),
    ],
  );
}

// ---------------------------------------------------------------------------
// 5. MAIN APP UI
// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCWKgnR4kbGNMFtT9n83nUpNsG9oCRDSLI",
        authDomain: "ai-resume-builder-f9edb.firebaseapp.com",
        projectId: "ai-resume-builder-f9edb",
        storageBucket: "ai-resume-builder-f9edb.firebasestorage.app",
        messagingSenderId: "150371540490",
        appId: "1:150371540490:web:55278cb01d94d03c9189f3",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ResumeProvider(),
      child: const AiResumeApp(),
    ),
  );
}

class AiResumeApp extends StatelessWidget {
  const AiResumeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AI Resume',
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.light,
    theme: ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: const Color(0xFF2E64FA),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black), // Black outline
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    ),
    home: const SplashScreen(),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () async {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => (p.getBool('seen') ?? false)
              ? const AuthWrapper()
              : const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2E64FA).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description,
              size: 80,
              color: Color(0xFF2E64FA),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "AI Resume Builder",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const CircularProgressIndicator(color: Color(0xFF2E64FA)),
        ],
      ),
    ),
  );
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              "What brings you to\nAI Resume?",
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            ...[
              "Create my first resume",
              "Enhance my resume",
              "Just exploring",
            ].map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () async {
                    (await SharedPreferences.getInstance()).setBool(
                      'seen',
                      true,
                    );
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        l,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: () async {
                  (await SharedPreferences.getInstance()).setBool('seen', true);
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    );
                  }
                },
                child: const Text("Skip", style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) =>
      Provider.of<ResumeProvider>(context).isLoading
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : const MainTabNavigator();
}

class MainTabNavigator extends StatefulWidget {
  const MainTabNavigator({super.key});
  @override
  State<MainTabNavigator> createState() => _MainTabNavigatorState();
}

class _MainTabNavigatorState extends State<MainTabNavigator> {
  int _idx = 0;
  final _screens = [
    const DashboardScreen(),
    const TemplatesScreen(isSelectionMode: false),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: _screens[_idx],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _idx,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2E64FA),
      unselectedItemColor: Colors.grey,
      onTap: (i) => setState(() => _idx = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Templates'),
      ],
    ),
  );
}

// --- TEMPLATES SCREEN (6 TEMPLATES) ---
class TemplatesScreen extends StatelessWidget {
  final bool isSelectionMode;
  const TemplatesScreen({super.key, required this.isSelectionMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Template")),
      body: Consumer<ResumeProvider>(
        builder: (context, provider, child) {
          final currentTemplate =
              provider.currentResume?.templateId ?? 'modern_blue';

          // 6 Distinct Templates matching the styles requested
          final templates = [
            {
              'id': 'modern_blue',
              'name': 'Modern Blue',
              'color': Colors.blue.shade800,
              'style': 'sidebar_left',
            },
            {
              'id': 'classic_green',
              'name': 'Classic Green',
              'color': Colors.green.shade700,
              'style': 'header_top',
            },
            {
              'id': 'professional_red',
              'name': 'Professional Red',
              'color': Colors.red.shade800,
              'style': 'header_top',
            },
            {
              'id': 'elegant_orange',
              'name': 'Elegant Orange',
              'color': Colors.orange.shade800,
              'style': 'sidebar_right',
            },
            {
              'id': 'creative_violet',
              'name': 'Creative Violet',
              'color': Colors.purple.shade800,
              'style': 'sidebar_left',
            },
            {
              'id': 'clean_grey',
              'name': 'Clean Grey',
              'color': Colors.grey.shade800,
              'style': 'sidebar_right',
            },
          ];

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: templates.length,
            itemBuilder: (ctx, i) {
              final t = templates[i];
              return _buildTemplateCard(
                context,
                provider,
                id: t['id'] as String,
                name: t['name'] as String,
                color: t['color'] as Color,
                styleType: t['style'] as String,
                isSelected: currentTemplate == t['id'],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    ResumeProvider provider, {
    required String id,
    required String name,
    required Color color,
    required String styleType,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (provider.currentResume == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Create a resume first!")),
          );
          return;
        }

        provider.updateTemplate(id);

        if (isSelectionMode) {
          final latestResume = provider.currentResume;
          if (latestResume != null) {
            generateResumePdf(latestResume);
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Selected $name template")));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF2E64FA), width: 3)
              : Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: _buildMiniPreview(styleType, color),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E64FA),
                      size: 16,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPreview(String type, Color color) {
    // Helper to build simulated lines of text
    Widget line(double width, {double height = 2, Color? c}) => Container(
      height: height,
      width: width,
      color: c ?? Colors.black12,
      margin: const EdgeInsets.symmetric(vertical: 1.5),
    );

    // Mockup content block
    Widget contentBlock() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(40, height: 3, c: Colors.black26), // Header
        const SizedBox(height: 2),
        line(double.infinity),
        line(double.infinity),
        line(50),
        const SizedBox(height: 6),
        line(40, height: 3, c: Colors.black26),
        const SizedBox(height: 2),
        line(double.infinity),
        line(double.infinity),
        line(30),
      ],
    );

    if (type == 'sidebar_left') {
      return Row(
        children: [
          Container(width: 30, color: color), // Sidebar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    color: Colors.black12,
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                  Expanded(child: contentBlock()),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (type == 'sidebar_right') {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    color: Colors.black12,
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                  Expanded(child: contentBlock()),
                ],
              ),
            ),
          ),
          Container(width: 30, color: color), // Sidebar
        ],
      );
    } else {
      // Top Header
      return Column(
        children: [
          Container(height: 25, color: color), // Header
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: contentBlock()),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        line(20, height: 3, c: Colors.black38),
                        line(20),
                        line(20),
                        line(20),
                        const SizedBox(height: 10),
                        line(20, height: 3, c: Colors.black38),
                        line(20),
                        line(20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E64FA).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description,
                    size: 40,
                    color: Color(0xFF2E64FA),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "AI Resume CV PDF",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(Icons.star, "Rate App", () {}),
          _drawerItem(Icons.share, "Share App", () {}),
          _drawerItem(Icons.privacy_tip, "Privacy Policy", () {}),
          _drawerItem(Icons.description, "Service Terms", () {}),
        ],
      ),
    );
  }
}

Widget _drawerItem(IconData i, String t, VoidCallback tap) => ListTile(
  leading: Icon(i, color: Colors.black87),
  title: Text(t, style: const TextStyle(color: Colors.black87)),
  onTap: tap,
);

// --- DASHBOARD SCREEN (UPDATED WITH MENU) ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<ResumeProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Resumes", style: TextStyle(color: Colors.black)),
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<Resume>>(
        stream: p.getResumesStream(),
        builder: (c, s) {
          if (!s.hasData || s.data!.isEmpty) {
            // EMPTY STATE
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 220,
                          width: 220,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(
                          Icons.assignment_ind_rounded,
                          size: 140,
                          color: Color(0xFF5A8CFF),
                        ),
                        Positioned(
                          right: 40,
                          bottom: 40,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          await p.createNewResume();
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditResumeScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E64FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Create your first resume now",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await p.createNewResume();
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditResumeScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "NEW RESUME",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E64FA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: s.data!.length,
                    itemBuilder: (ctx, i) => GestureDetector(
                      onTap: () {
                        p.selectResume(s.data![i]);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditResumeScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircularPercentIndicator(
                              radius: 25,
                              percent: s.data![i].score / 100,
                              center: Text(
                                "${s.data![i].score.toInt()}%",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                              progressColor: Colors.blue,
                              backgroundColor: Colors.grey.shade100,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.data![i].personalInfo.fullName.isEmpty
                                      ? "Untitled"
                                      : s.data![i].personalInfo.fullName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "Last update: ${DateFormat('MM/dd').format(s.data![i].lastUpdated)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // --- FUNCTIONAL MENU BUTTON ---
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_horiz,
                                color: Colors.grey,
                              ),
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  // Confirm Dialog
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Delete Resume?"),
                                      content: const Text(
                                        "This action cannot be undone.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await p.deleteResume(s.data![i].id);
                                  }
                                } else if (value == 'duplicate') {
                                  await p.duplicateResume(s.data![i]);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Resume duplicated"),
                                      ),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'duplicate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.copy, color: Colors.black54),
                                      SizedBox(width: 10),
                                      Text("Duplicate"),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EditResumeScreen extends StatelessWidget {
  const EditResumeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final r = Provider.of<ResumeProvider>(context).currentResume;
    if (r == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Resume", style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SectionTile(
              icon: Icons.person,
              title: "Personal Information",
              isCompleted: r.personalInfo.fullName.isNotEmpty,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalInfoFormScreen(),
                ),
              ),
            ),
            if (r.showObjective)
              _SectionTile(
                icon: Icons.gps_fixed,
                title: "Objective",
                isCompleted: r.objective.isNotEmpty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ObjectiveFormScreen(),
                  ),
                ),
              ),
            if (r.showExperience)
              _SectionTile(
                icon: Icons.work,
                title: "Professional Experience",
                isCompleted: r.experience.isNotEmpty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExperienceListScreen(),
                  ),
                ),
              ),
            if (r.showEducation)
              _SectionTile(
                icon: Icons.school,
                title: "Education",
                isCompleted: r.education.isNotEmpty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EducationListScreen(),
                  ),
                ),
              ),
            if (r.showSkills)
              _SectionTile(
                icon: Icons.psychology,
                title: "Skills",
                isCompleted: r.skills.isNotEmpty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const StringListScreen(title: "Skills", type: "skills"),
                  ),
                ),
              ),
            if (r.showLanguages)
              _SectionTile(
                icon: Icons.translate,
                title: "Languages",
                isCompleted: r.languages.isNotEmpty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StringListScreen(
                      title: "Languages",
                      type: "languages",
                    ),
                  ),
                ),
              ),
            if (r.showCertificates)
              _SectionTile(
                icon: Icons.verified,
                title: "Courses and Certificates",
                isCompleted: r.certificates.isNotEmpty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StringListScreen(
                      title: "Certificates",
                      type: "certificates",
                    ),
                  ),
                ),
              ),
            if (r.showReferences)
              _SectionTile(
                icon: Icons.people,
                title: "References",
                isCompleted: r.references.isNotEmpty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReferenceListScreen(),
                  ),
                ),
              ),
            if (r.showSummary)
              _SectionTile(
                icon: Icons.description,
                title: "Summary",
                isCompleted: r.summary.isNotEmpty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SummaryFormScreen()),
                ),
              ),
            if (r.showQrCode)
              _SectionTile(
                icon: Icons.qr_code,
                title: "QR Code",
                isCompleted: r.portfolioUrl.isNotEmpty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrCodeFormScreen()),
                ),
              ),
            // Custom Sections Display
            ...r.customSections.map(
              (cs) => _SectionTile(
                icon: Icons.extension,
                title: cs.title,
                isCompleted: cs.content.isNotEmpty,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomSectionFormScreen(customSection: cs),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _showSectionManager(context),
              icon: const Icon(
                Icons
                    .tune, // Changed icon to represent management/settings better
                color: Color(0xFF5A8CFF),
              ),
              label: const Text(
                "Add or remove sections", // Updated label
                style: TextStyle(
                  color: Color(0xFF5A8CFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2E64FA).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularPercentIndicator(
                    radius: 20,
                    lineWidth: 4,
                    percent: r.score / 100,
                    progressColor: Colors.green,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "View Resume Score",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _genCoverLetter(context),
                      icon: const Icon(Icons.description, color: Colors.white),
                      label: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note, color: Colors.white),
                          Text(
                            "Cover Letter",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF9C27B0,
                        ), // Purple like screenshot
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // NEW FLOW: Redirect to Template Screen FIRST
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const TemplatesScreen(isSelectionMode: true),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility, color: Colors.white),
                      label: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.white),
                          Text(
                            "View Resume",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF2E64FA,
                        ), // Blue like screenshot
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showSectionManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer<ResumeProvider>(
        builder: (ctx, provider, _) {
          final r = provider.currentResume!;
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (ctx, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const Text(
                        "Manage Sections",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Toggle sections to add or remove them from your resume.",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      _toggleTile(
                        "Objective",
                        r.showObjective,
                        (v) => provider.toggleSection('Objective'),
                      ),
                      _toggleTile(
                        "Summary",
                        r.showSummary,
                        (v) => provider.toggleSection('Summary'),
                      ),
                      _toggleTile(
                        "Experience",
                        r.showExperience,
                        (v) => provider.toggleSection('Experience'),
                      ),
                      _toggleTile(
                        "Education",
                        r.showEducation,
                        (v) => provider.toggleSection('Education'),
                      ),
                      _toggleTile(
                        "Skills",
                        r.showSkills,
                        (v) => provider.toggleSection('Skills'),
                      ),
                      _toggleTile(
                        "Languages",
                        r.showLanguages,
                        (v) => provider.toggleSection('Languages'),
                      ),
                      _toggleTile(
                        "Certificates",
                        r.showCertificates,
                        (v) => provider.toggleSection('Certificates'),
                      ),
                      _toggleTile(
                        "References",
                        r.showReferences,
                        (v) => provider.toggleSection('References'),
                      ),
                      _toggleTile(
                        "QR Code",
                        r.showQrCode,
                        (v) => provider.toggleSection('QR Code'),
                      ),
                      // List custom sections with delete option
                      ...r.customSections.map(
                        (cs) => ListTile(
                          title: Text(cs.title),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                provider.removeCustomSection(cs.id),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Add Custom Section Button
                      ElevatedButton.icon(
                        onPressed: () {
                          _showAddCustomSectionDialog(context, provider);
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          "Add Custom Section",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E64FA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Done",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddCustomSectionDialog(
    BuildContext context,
    ResumeProvider provider,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Custom Section"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Section Title (e.g. Projects)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addCustomSection(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _genCoverLetter(BuildContext context) async {
    final r = Provider.of<ResumeProvider>(
      context,
      listen: false,
    ).currentResume!;

    // Show AI Generation Popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2E64FA)),
              const SizedBox(height: 20),
              const Text(
                "AI is generating for you...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Crafting a professional cover letter based on your profile.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final m = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: kGeminiApiKey,
      );
      final prompt =
          "Write a professional cover letter for ${r.personalInfo.fullName}, a ${r.personalInfo.jobTitle}. Skills: ${r.skills.join(', ')}. Keep it concise.";
      final response = await m.generateContent([Content.text(prompt)]);

      final text = response.text;

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (text != null) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "AI Cover Letter",
                    style: TextStyle(color: Colors.black),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF2E64FA)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Copied to clipboard!")),
                      );
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Text(text, style: const TextStyle(color: Colors.black)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}

class CustomSectionFormScreen extends StatefulWidget {
  final CustomSection customSection;
  const CustomSectionFormScreen({super.key, required this.customSection});

  @override
  State<CustomSectionFormScreen> createState() =>
      _CustomSectionFormScreenState();
}

class _CustomSectionFormScreenState extends State<CustomSectionFormScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.customSection.content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customSection.title),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<ResumeProvider>(
                context,
                listen: false,
              ).updateCustomSection(widget.customSection.id, _controller.text);
              Navigator.pop(context);
            },
            child: const Text(
              "SAVE",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: 10,
          decoration: const InputDecoration(hintText: "Enter details..."),
        ),
      ),
    );
  }
}

Widget _toggleTile(String title, bool val, Function(bool) onChanged) {
  return SwitchListTile(
    title: Text(title, style: const TextStyle(color: Colors.black)),
    value: val,
    onChanged: onChanged,
    activeColor: const Color(0xFF2E64FA),
  );
}

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isCompleted;

  const _SectionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isCompleted = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade200,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ListTile(
      leading: Icon(icon, color: Colors.black87, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCompleted)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      dense: true,
      onTap: onTap,
    ),
  );
}

// --- FORMS & SCREENS (LIGHT THEMED) ---

class PersonalInfoFormScreen extends StatefulWidget {
  const PersonalInfoFormScreen({super.key});
  @override
  State<PersonalInfoFormScreen> createState() => _PState();
}

class _PState extends State<PersonalInfoFormScreen> {
  final _n = TextEditingController();
  final _e = TextEditingController();
  final _p = TextEditingController();
  final _j = TextEditingController();
  final _a = TextEditingController();
  @override
  void initState() {
    super.initState();
    final r = Provider.of<ResumeProvider>(
      context,
      listen: false,
    ).currentResume!;
    _n.text = r.personalInfo.fullName;
    _e.text = r.personalInfo.email;
    _p.text = r.personalInfo.phone;
    _j.text = r.personalInfo.jobTitle;
    _a.text = r.personalInfo.address;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Personal Info", style: TextStyle(color: Colors.black)),
      actions: [
        TextButton(
          onPressed: () {
            Provider.of<ResumeProvider>(
              context,
              listen: false,
            ).updatePersonalInfo(_n.text, _e.text, _p.text, _j.text, _a.text);
            Navigator.pop(context);
          },
          child: const Text(
            "SAVE",
            style: TextStyle(
              color: Color(0xFF2E64FA),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _txt("Name", _n),
        _txt("Job Title", _j),
        _txt("Email", _e),
        _txt("Phone", _p),
        _txt("Address", _a),
      ],
    ),
  );
}

class QrCodeFormScreen extends StatefulWidget {
  const QrCodeFormScreen({super.key});
  @override
  State<QrCodeFormScreen> createState() => _QState();
}

class _QState extends State<QrCodeFormScreen> {
  final _url = TextEditingController();
  @override
  void initState() {
    super.initState();
    final r = Provider.of<ResumeProvider>(context, listen: false).currentResume;
    if (r != null) _url.text = r.portfolioUrl;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("QR Code Link", style: TextStyle(color: Colors.black)),
      actions: [
        TextButton(
          onPressed: () {
            Provider.of<ResumeProvider>(
              context,
              listen: false,
            ).updatePortfolioUrl(_url.text);
            Navigator.pop(context);
          },
          child: const Text(
            "SAVE",
            style: TextStyle(
              color: Color(0xFF2E64FA),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Enter a URL (LinkedIn, Portfolio) to generate a QR Code on your PDF.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildTextField("Website / Portfolio URL", _url),
        ],
      ),
    ),
  );
}

class ObjectiveFormScreen extends StatelessWidget {
  const ObjectiveFormScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const GenericAiFormScreen(title: "Objective", type: "objective");
}

class SummaryFormScreen extends StatelessWidget {
  const SummaryFormScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const GenericAiFormScreen(title: "Summary", type: "summary");
}

class GenericAiFormScreen extends StatefulWidget {
  final String title;
  final String type;
  const GenericAiFormScreen({
    super.key,
    required this.title,
    required this.type,
  });
  @override
  State<GenericAiFormScreen> createState() => _GenericAiFormScreenState();
}

class _GenericAiFormScreenState extends State<GenericAiFormScreen> {
  final _controller = TextEditingController();
  bool _isGenerating = false;
  @override
  void initState() {
    super.initState();
    final r = Provider.of<ResumeProvider>(context, listen: false).currentResume;
    if (r != null) {
      _controller.text = widget.type == 'objective' ? r.objective : r.summary;
    }
  }

  Future<void> _generate() async {
    // Show AI Generation Popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2E64FA)),
              const SizedBox(height: 20),
              const Text(
                "AI is generating for you...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() => _isGenerating = true);
    final r = Provider.of<ResumeProvider>(
      context,
      listen: false,
    ).currentResume!;
    final prompt =
        "Write a professional resume ${widget.type} for a ${r.personalInfo.jobTitle}. Skills: ${r.skills.join(', ')}. Experience: ${r.experience.map((e) => e.jobTitle).join(', ')}. Keep it concise and impactful.";

    try {
      if (kGeminiApiKey.contains("YOUR_")) {
        _controller.text = "Please set API Key in main.dart";
      } else {
        final model = GenerativeModel(
          model: 'models/gemini-2.5-flash',
          apiKey: kGeminiApiKey,
        );
        final res = await model.generateContent([Content.text(prompt)]);
        if (res.text != null) _controller.text = res.text!;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    if (mounted) {
      Navigator.pop(context); // Close the popup
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title, style: const TextStyle(color: Colors.black)),
      actions: [
        TextButton(
          onPressed: () {
            final p = Provider.of<ResumeProvider>(context, listen: false);
            widget.type == 'objective'
                ? p.updateObjective(_controller.text)
                : p.updateSummary(_controller.text);
            Navigator.pop(context);
          },
          child: const Text(
            "SAVE",
            style: TextStyle(
              color: Color(0xFF2E64FA),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generate,
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text(
                "WRITE WITH AI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E64FA),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            maxLines: 10,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              hintText: "Enter text...",
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    ),
  );
}

class StringListScreen extends StatefulWidget {
  final String title;
  final String type;
  const StringListScreen({super.key, required this.title, required this.type});
  @override
  State<StringListScreen> createState() => _StringListScreenState();
}

class _StringListScreenState extends State<StringListScreen> {
  final _controller = TextEditingController();
  List<String> _items = [];
  @override
  void initState() {
    super.initState();
    final r = Provider.of<ResumeProvider>(context, listen: false).currentResume;
    if (r != null) {
      if (widget.type == 'skills') {
        _items = List.from(r.skills);
      } else if (widget.type == 'languages') {
        _items = List.from(r.languages);
      } else {
        _items = List.from(r.certificates);
      }
    }
  }

  void _save() {
    final p = Provider.of<ResumeProvider>(context, listen: false);
    if (widget.type == 'skills') {
      p.updateSkills(_items);
    } else if (widget.type == 'languages') {
      p.updateLanguages(_items);
    } else {
      p.updateCertificates(_items);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title, style: const TextStyle(color: Colors.black)),
      actions: [
        TextButton(
          onPressed: _save,
          child: const Text(
            "SAVE",
            style: TextStyle(
              color: Color(0xFF2E64FA),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Add ${widget.title}...",
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    setState(() => _items.add(_controller.text));
                  }
                  _controller.clear();
                },
                icon: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF2E64FA),
                  size: 30,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (c, i) => ListTile(
              title: Text(
                _items[i],
                style: const TextStyle(color: Colors.black),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => _items.removeAt(i)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class ExperienceListScreen extends StatelessWidget {
  const ExperienceListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<ResumeProvider>(context);
    final list = p.currentResume?.experience ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Experience", style: TextStyle(color: Colors.black)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExperienceFormScreen()),
        ),
        backgroundColor: const Color(0xFF2E64FA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: list.isEmpty
          ? const Center(
              child: Text(
                "No experience added.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (c, i) => Dismissible(
                key: Key(list[i].id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => p.deleteExperience(list[i].id),
                child: Card(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      list[i].jobTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      list[i].company,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.grey),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExperienceFormScreen(item: list[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class ExperienceFormScreen extends StatefulWidget {
  final ExperienceItem? item;
  const ExperienceFormScreen({super.key, this.item});
  @override
  State<ExperienceFormScreen> createState() => _ExperienceFormScreenState();
}

class _ExperienceFormScreenState extends State<ExperienceFormScreen> {
  final _title = TextEditingController();
  final _comp = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _desc = TextEditingController();
  bool _isGenerating = false;
  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _title.text = widget.item!.jobTitle;
      _comp.text = widget.item!.company;
      _start.text = widget.item!.startDate;
      _end.text = widget.item!.endDate;
      _desc.text = widget.item!.description;
    }
  }

  Future<void> _generateDesc() async {
    if (_title.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter Job Title first")));
      return;
    }

    // Show Popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2E64FA)),
              const SizedBox(height: 20),
              const Text(
                "AI is generating for you...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    setState(() => _isGenerating = true);
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: kGeminiApiKey,
      );
      final prompt =
          "Write a concise, bullet-point job description for a ${_title.text} at ${_comp.text}. Write in FIRST PERSON past tense (e.g. 'Developed', 'Managed'). Do NOT write as a recruiter. Focus on achievements.";
      final response = await model.generateContent([Content.text(prompt)]);

      final text = response.text;
      if (text != null) {
        _desc.text = text;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) {
      Navigator.pop(context); // Close popup
      setState(() => _isGenerating = false);
    }
  }

  void _save() {
    final i = ExperienceItem(
      id: widget.item?.id ?? const Uuid().v4(),
      jobTitle: _title.text,
      company: _comp.text,
      startDate: _start.text,
      endDate: _end.text,
      description: _desc.text,
    );
    final p = Provider.of<ResumeProvider>(context, listen: false);
    widget.item != null ? p.updateExperience(i) : p.addExperience(i);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        "Edit Experience",
        style: TextStyle(color: Colors.black),
      ),
      actions: [
        TextButton(
          onPressed: _save,
          child: const Text(
            "SAVE",
            style: TextStyle(
              color: Color(0xFF2E64FA),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField("Job Title", _title),
          const SizedBox(height: 16),
          _buildTextField("Company", _comp),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField("Start", _start)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("End", _end)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateDesc,
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text(
                "WRITE WITH AI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E64FA),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField("Description", _desc, maxLines: 5),
        ],
      ),
    ),
  );
}

class EducationListScreen extends StatelessWidget {
  const EducationListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<ResumeProvider>(context);
    final list = p.currentResume?.education ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Education", style: TextStyle(color: Colors.black)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EducationFormScreen()),
        ),
        backgroundColor: const Color(0xFF2E64FA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: list.isEmpty
          ? const Center(
              child: Text(
                "No education added.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (c, i) => Dismissible(
                key: Key(list[i].id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => p.deleteEducation(list[i].id),
                child: Card(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      list[i].school,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      list[i].degree,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.grey),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EducationFormScreen(item: list[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class EducationFormScreen extends StatefulWidget {
  final EducationItem? item;
  const EducationFormScreen({super.key, this.item});
  @override
  State<EducationFormScreen> createState() => _EducationFormScreenState();
}

class _EducationFormScreenState extends State<EducationFormScreen> {
  final _school = TextEditingController();
  final _degree = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _school.text = widget.item!.school;
      _degree.text = widget.item!.degree;
      _start.text = widget.item!.startDate;
      _end.text = widget.item!.endDate;
    }
  }

  void _save() {
    final i = EducationItem(
      id: widget.item?.id ?? const Uuid().v4(),
      school: _school.text,
      degree: _degree.text,
      startDate: _start.text,
      endDate: _end.text,
    );
    final p = Provider.of<ResumeProvider>(context, listen: false);
    widget.item != null ? p.updateEducation(i) : p.addEducation(i);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        "Edit Education",
        style: TextStyle(color: Colors.black),
      ),
      actions: [
        TextButton(
          onPressed: _save,
          child: const Text(
            "SAVE",
            style: TextStyle(
              color: Color(0xFF2E64FA),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField("School", _school),
          const SizedBox(height: 16),
          _buildTextField("Degree", _degree),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField("Start", _start)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("End", _end)),
            ],
          ),
        ],
      ),
    ),
  );
}

class ReferenceListScreen extends StatelessWidget {
  const ReferenceListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<ResumeProvider>(context);
    final list = p.currentResume?.references ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text("References", style: TextStyle(color: Colors.black)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReferenceFormScreen()),
        ),
        backgroundColor: const Color(0xFF2E64FA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: list.isEmpty
          ? const Center(
              child: Text(
                "No references added.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (c, i) => Dismissible(
                key: Key(list[i].id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => p.deleteReference(list[i].id),
                child: Card(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      list[i].name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      list[i].company,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.grey),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReferenceFormScreen(item: list[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class ReferenceFormScreen extends StatefulWidget {
  final ReferenceItem? item;
  const ReferenceFormScreen({super.key, this.item});
  @override
  State<ReferenceFormScreen> createState() => _ReferenceFormScreenState();
}

class _ReferenceFormScreenState extends State<ReferenceFormScreen> {
  final _name = TextEditingController();
  final _comp = TextEditingController();
  final _cont = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _name.text = widget.item!.name;
      _comp.text = widget.item!.company;
      _cont.text = widget.item!.contact;
    }
  }

  void _save() {
    final i = ReferenceItem(
      id: widget.item?.id ?? const Uuid().v4(),
      name: _name.text,
      company: _comp.text,
      contact: _cont.text,
    );
    final p = Provider.of<ResumeProvider>(context, listen: false);
    widget.item != null ? p.updateReference(i) : p.addReference(i);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        "Edit Reference",
        style: TextStyle(color: Colors.black),
      ),
      actions: [
        TextButton(
          onPressed: _save,
          child: const Text(
            "SAVE",
            style: TextStyle(
              color: Color(0xFF2E64FA),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField("Name", _name),
          const SizedBox(height: 16),
          _buildTextField("Company", _comp),
          const SizedBox(height: 16),
          _buildTextField("Contact (Phone/Email)", _cont),
        ],
      ),
    ),
  );
}

Widget _txt(String l, TextEditingController c) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(l, style: const TextStyle(color: Colors.grey)),
    const SizedBox(height: 5),
    TextField(
      controller: c,
      style: const TextStyle(color: Colors.black),
    ),
    const SizedBox(height: 15),
  ],
);
Widget _buildTextField(
  String label,
  TextEditingController controller, {
  TextInputType? keyboardType,
  int? maxLines = 1,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label.isNotEmpty) ...[
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
      ],
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black),
      ),
    ],
  );
}
