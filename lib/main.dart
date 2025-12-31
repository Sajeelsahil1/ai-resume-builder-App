/*
 * ---------------------------------------------------------------------------
 * AI RESUME BUILDER - UI DEMO VERSION
 * ---------------------------------------------------------------------------
 * DISCLAIMER:
 * This is a frontend demonstration of the AI Resume Builder.
 * The backend logic (Firebase Auth, Firestore Database) and AI integration 
 * (Google Gemini) have been replaced with MOCK DATA and LOCAL STATE 
 * for security and demonstration purposes.
 * * No API keys are required to run this demo.
 * * Original Architecture:
 * - Auth: Firebase Anonymous & Email Auth
 * - Database: Cloud Firestore
 * - AI: Google Gemini Pro Model via API
 * * ---------------------------------------------------------------------------
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
// [PORTFOLIO NOTE]: Production uses google_generative_ai, firebase_core, firebase_auth, cloud_firestore
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/percent_indicator.dart';

// ---------------------------------------------------------------------------
// 1. DATA MODELS
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
}

class CustomSection {
  String id;
  String title;
  String content;

  CustomSection({required this.id, this.title = "", this.content = ""});
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
}

// ---------------------------------------------------------------------------
// 2. MOCK STATE MANAGEMENT (Replaces Firebase)
// ---------------------------------------------------------------------------

class ResumeProvider extends ChangeNotifier {
  // [PORTFOLIO NOTE]: In production, this uses FirebaseFirestore
  final List<Resume> _mockDatabase = []; 
  Resume? _currentResume;
  bool _isLoading = false;

  Resume? get currentResume => _currentResume;
  bool get isLoading => _isLoading;

  ResumeProvider() {
    _initMockData();
  }

  void _initMockData() {
    // Populate with a sample resume for the demo
    final demoId = const Uuid().v4();
    final demoResume = Resume(
      id: demoId,
      title: "Demo Resume",
      lastUpdated: DateTime.now(),
      personalInfo: PersonalInfo(
        fullName: "John Doe",
        jobTitle: "Flutter Developer",
        email: "john@example.com",
        phone: "+1 234 567 890",
        address: "New York, USA"
      ),
      skills: ["Flutter", "Dart", "Firebase", "UI/UX"],
      summary: "Passionate developer building demo apps.",
    );
    _mockDatabase.add(demoResume);
  }

  // [PORTFOLIO NOTE]: In production, this returns a Firestore Stream
  Stream<List<Resume>> getResumesStream() {
    // Return a stream that emits the current list whenever we ask
    return Stream.value(_mockDatabase);
  }

  Future<void> createNewResume() async {
    final String newId = const Uuid().v4();
    final newResume = Resume(
      id: newId,
      title: "Untitled Resume",
      lastUpdated: DateTime.now(),
      personalInfo: PersonalInfo(),
    );
    _currentResume = newResume;
    _mockDatabase.add(newResume);
    notifyListeners();
  }

  Future<void> duplicateResume(Resume r) async {
    final String newId = const Uuid().v4();
    final newResume = Resume(
      id: newId,
      title: "Copy of ${r.title}",
      templateId: r.templateId,
      lastUpdated: DateTime.now(),
      personalInfo: r.personalInfo,
      // ... copy other fields manually for deep copy in demo
      skills: List.from(r.skills),
    );
    _mockDatabase.add(newResume);
    notifyListeners();
  }

  Future<void> deleteResume(String id) async {
    _mockDatabase.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void selectResume(Resume resume) {
    _currentResume = resume;
    notifyListeners();
  }

  // Generic update method to simulate saving to DB
  Future<void> _save() async {
    if (_currentResume == null) return;
    // Find index and update
    final index = _mockDatabase.indexWhere((r) => r.id == _currentResume!.id);
    if (index != -1) {
      _mockDatabase[index] = _currentResume!;
      _currentResume!.lastUpdated = DateTime.now();
      notifyListeners();
    }
  }

  // --- MOCK AI GENERATION ---
  // [PORTFOLIO NOTE]: In production, this calls Google Gemini API
  Future<String> mockGenerateContent(String promptType) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    if (promptType == 'summary') {
      return "Experienced professional with a proven track record in software development. Skilled in Flutter and Dart, dedicated to optimizing user experiences.";
    } else if (promptType == 'objective') {
      return "To leverage my skills in mobile development to build impactful applications in a dynamic environment.";
    } else if (promptType == 'description') {
      return "• Led development of key features using Flutter.\n• Collaborated with cross-functional teams.\n• Optimized app performance by 30%.";
    } else if (promptType == 'cover_letter') {
      return "Dear Hiring Manager,\n\nI am writing to express my interest in the Developer position. With my background in Flutter...";
    }
    return "Demo AI Response generated.";
  }

  // --- UPDATERS (Simplified for Demo) ---
  Future<void> updateTemplate(String id) async { _currentResume?.templateId = id; await _save(); }
  Future<void> toggleSection(String s) async { 
    if(_currentResume == null) return;
    if(s=='Summary') _currentResume!.showSummary = !_currentResume!.showSummary;
    // ... add other toggles if needed for full demo fidelity
    await _save(); 
  }
  
  Future<void> updatePersonalInfo(String n, String e, String p, String r, String a) async {
    _currentResume?.personalInfo = PersonalInfo(fullName: n, email: e, phone: p, jobTitle: r, address: a);
    await _save();
  }
  
  Future<void> updateSummary(String v) async { _currentResume?.summary = v; await _save(); }
  Future<void> updateObjective(String v) async { _currentResume?.objective = v; await _save(); }
  Future<void> updatePortfolioUrl(String v) async { _currentResume?.portfolioUrl = v; await _save(); }
  
  Future<void> addExperience(ExperienceItem i) async { _currentResume?.experience.add(i); await _save(); }
  Future<void> updateExperience(ExperienceItem i) async { 
     final idx = _currentResume?.experience.indexWhere((e) => e.id == i.id) ?? -1;
     if(idx != -1) _currentResume?.experience[idx] = i;
     await _save();
  }
  Future<void> deleteExperience(String id) async { _currentResume?.experience.removeWhere((e) => e.id == id); await _save(); }

  Future<void> addEducation(EducationItem i) async { _currentResume?.education.add(i); await _save(); }
  Future<void> updateEducation(EducationItem i) async { 
     final idx = _currentResume?.education.indexWhere((e) => e.id == i.id) ?? -1;
     if(idx != -1) _currentResume?.education[idx] = i;
     await _save();
  }
  Future<void> deleteEducation(String id) async { _currentResume?.education.removeWhere((e) => e.id == id); await _save(); }

  Future<void> addReference(ReferenceItem i) async { _currentResume?.references.add(i); await _save(); }
  Future<void> updateReference(ReferenceItem i) async { 
     final idx = _currentResume?.references.indexWhere((e) => e.id == i.id) ?? -1;
     if(idx != -1) _currentResume?.references[idx] = i;
     await _save();
  }
  Future<void> deleteReference(String id) async { _currentResume?.references.removeWhere((e) => e.id == id); await _save(); }

  Future<void> updateSkills(List<String> l) async { _currentResume?.skills = l; await _save(); }
  Future<void> updateLanguages(List<String> l) async { _currentResume?.languages = l; await _save(); }
  Future<void> updateCertificates(List<String> l) async { _currentResume?.certificates = l; await _save(); }
  
  Future<void> addCustomSection(String title) async {
    _currentResume?.customSections.add(CustomSection(id: const Uuid().v4(), title: title));
    await _save();
  }
  Future<void> updateCustomSection(String id, String content) async {
    final idx = _currentResume?.customSections.indexWhere((s) => s.id == id) ?? -1;
    if(idx != -1) _currentResume?.customSections[idx].content = content;
    await _save();
  }
  Future<void> removeCustomSection(String id) async {
    _currentResume?.customSections.removeWhere((s) => s.id == id);
    await _save();
  }
}

// ---------------------------------------------------------------------------
// 3. PDF GENERATION (Kept Functional for Demo)
// ---------------------------------------------------------------------------

Future<void> generateResumePdf(Resume resume) async {
  final pdf = pw.Document();

  // Using standard fonts for demo to avoid async loading issues in web demo if not configured
  final fontRegular = await PdfGoogleFonts.openSansRegular();
  final fontBold = await PdfGoogleFonts.openSansBold();

  final theme = pw.ThemeData.withFont(
    base: fontRegular,
    bold: fontBold,
  );

  pw.Page pageLayout;
  
  // Simplified template selector for demo
  PdfColor color = PdfColors.blue800;
  if(resume.templateId == 'classic_green') color = PdfColors.green800;
  if(resume.templateId == 'professional_red') color = PdfColors.red800;
  
  pageLayout = _buildTemplateLayout(resume, theme, color, PdfColors.white, _SidebarPosition.left);

  pdf.addPage(pageLayout);
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

enum _SidebarPosition { left, right, topHeader }

pw.Page _buildTemplateLayout(
  Resume r,
  pw.ThemeData theme,
  PdfColor primaryColor,
  PdfColor secondaryColor,
  _SidebarPosition position,
) {
  return pw.MultiPage(
    pageTheme: pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.all(0),
    ),
    build: (pw.Context context) {
      return [
         pw.Row(
           crossAxisAlignment: pw.CrossAxisAlignment.start,
           children: [
             pw.Container(
               width: 180,
               height: 800, // Fixed height for demo simple layout
               color: primaryColor,
               padding: const pw.EdgeInsets.all(20),
               child: pw.Column(
                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                 children: [
                   pw.Text("SKILLS", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                   ...r.skills.map((s) => pw.Text(s, style: const pw.TextStyle(color: PdfColors.white, fontSize: 10))),
                 ],
               )
             ),
             pw.Expanded(
               child: pw.Padding(
                 padding: const pw.EdgeInsets.all(20),
                 child: pw.Column(
                   crossAxisAlignment: pw.CrossAxisAlignment.start,
                   children: [
                     pw.Text(r.personalInfo.fullName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                     pw.Text(r.personalInfo.jobTitle, style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey)),
                     pw.Divider(),
                     pw.Text("SUMMARY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor)),
                     pw.Text(r.summary),
                     pw.SizedBox(height: 10),
                     pw.Text("EXPERIENCE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor)),
                     ...r.experience.map((e) => pw.Column(
                       crossAxisAlignment: pw.CrossAxisAlignment.start,
                       children: [
                         pw.Text(e.jobTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                         pw.Text(e.company + " | " + e.startDate),
                         pw.Text(e.description, style: const pw.TextStyle(fontSize: 10)),
                         pw.SizedBox(height: 5),
                       ],
                     )),
                   ],
                 )
               )
             )
           ]
         )
      ];
    },
  );
}

// ---------------------------------------------------------------------------
// 4. MAIN APP UI
// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // [PORTFOLIO NOTE]: Firebase initialization removed for demo
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
    title: 'AI Resume Demo',
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description, size: 80, color: Color(0xFF2E64FA)),
          const SizedBox(height: 20),
          Text("AI Resume Builder", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("UI Demo Version", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: Color(0xFF2E64FA)),
        ],
      ),
    ),
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<ResumeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("My Resumes")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E64FA),
        onPressed: () {
          p.createNewResume();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditResumeScreen()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Resume>>(
        stream: p.getResumesStream(),
        builder: (context, snapshot) {
          if(!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No resumes"));
          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final resume = list[i];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircularPercentIndicator(
                    radius: 20, percent: 0.5, center: const Text("50%"),
                    progressColor: Colors.blue,
                  ),
                  title: Text(resume.personalInfo.fullName.isEmpty ? "Untitled" : resume.personalInfo.fullName),
                  subtitle: Text("Updated: ${DateFormat('MM/dd').format(resume.lastUpdated)}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    p.selectResume(resume);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditResumeScreen()));
                  },
                ),
              );
            },
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
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Resume")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             _SectionTile(icon: Icons.person, title: "Personal Info", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoFormScreen()))),
             _SectionTile(icon: Icons.work, title: "Experience", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExperienceListScreen()))),
             _SectionTile(icon: Icons.school, title: "Education", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EducationListScreen()))),
             _SectionTile(icon: Icons.psychology, title: "Skills", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StringListScreen(title: "Skills", type: "skills")))),
             _SectionTile(icon: Icons.description, title: "Summary", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenericAiFormScreen(title: "Summary", type: "summary")))),
             const SizedBox(height: 20),
             Row(
               children: [
                 Expanded(
                   child: ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.all(16)),
                     icon: const Icon(Icons.auto_awesome, color: Colors.white),
                     label: const Text("AI Cover Letter", style: TextStyle(color: Colors.white)),
                     onPressed: () => _showAiCoverLetterDemo(context),
                   ),
                 ),
                 const SizedBox(width: 10),
                 Expanded(
                   child: ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(16)),
                     icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                     label: const Text("Preview PDF", style: TextStyle(color: Colors.white)),
                     onPressed: () {
                        final r = Provider.of<ResumeProvider>(context, listen: false).currentResume;
                        if(r!=null) generateResumePdf(r);
                     },
                   ),
                 ),
               ],
             )
          ],
        ),
      ),
    );
  }

  void _showAiCoverLetterDemo(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    // [PORTFOLIO NOTE]: Simulating Gemini API call
    final response = await Provider.of<ResumeProvider>(context, listen: false).mockGenerateContent("cover_letter");
    if(context.mounted) {
      Navigator.pop(context);
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text("AI Generated Content (Demo)"),
        content: Text(response),
        actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Close"))],
      ));
    }
  }
}

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _SectionTile({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward, color: Colors.grey),
      onTap: onTap,
    ),
  );
}

// --- FORMS (Simplified for Demo) ---

class PersonalInfoFormScreen extends StatefulWidget {
  const PersonalInfoFormScreen({super.key});
  @override
  State<PersonalInfoFormScreen> createState() => _PState();
}

class _PState extends State<PersonalInfoFormScreen> {
  final _n = TextEditingController();
  final _j = TextEditingController();
  @override
  void initState() {
    super.initState();
    final r = Provider.of<ResumeProvider>(context, listen: false).currentResume!;
    _n.text = r.personalInfo.fullName;
    _j.text = r.personalInfo.jobTitle;
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Personal Info"), actions: [
      TextButton(onPressed: () {
        Provider.of<ResumeProvider>(context, listen: false).updatePersonalInfo(_n.text, "", "", _j.text, "");
        Navigator.pop(context);
      }, child: const Text("SAVE"))
    ]),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _n, decoration: const InputDecoration(labelText: "Full Name")),
      const SizedBox(height: 10),
      TextField(controller: _j, decoration: const InputDecoration(labelText: "Job Title")),
    ])),
  );
}

class GenericAiFormScreen extends StatefulWidget {
  final String title;
  final String type;
  const GenericAiFormScreen({super.key, required this.title, required this.type});
  @override
  State<GenericAiFormScreen> createState() => _GenericAiState();
}

class _GenericAiState extends State<GenericAiFormScreen> {
  final _c = TextEditingController();
  @override
  void initState() {
    super.initState();
    final r = Provider.of<ResumeProvider>(context, listen: false).currentResume!;
    _c.text = widget.type == 'summary' ? r.summary : r.objective;
  }

  void _runAi() async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    // [PORTFOLIO NOTE]: Mocking AI response
    final txt = await Provider.of<ResumeProvider>(context, listen: false).mockGenerateContent(widget.type);
    if(mounted) {
      Navigator.pop(context);
      setState(() => _c.text = txt);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title), actions: [
      TextButton(onPressed: () {
        if(widget.type == 'summary') Provider.of<ResumeProvider>(context, listen: false).updateSummary(_c.text);
        Navigator.pop(context);
      }, child: const Text("SAVE"))
    ]),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      ElevatedButton.icon(onPressed: _runAi, icon: const Icon(Icons.auto_awesome), label: const Text("Generate with AI")),
      const SizedBox(height: 20),
      TextField(controller: _c, maxLines: 5, decoration: const InputDecoration(hintText: "Content...")),
    ])),
  );
}

class StringListScreen extends StatefulWidget {
  final String title;
  final String type;
  const StringListScreen({super.key, required this.title, required this.type});
  @override
  State<StringListScreen> createState() => _SLState();
}

class _SLState extends State<StringListScreen> {
  final _c = TextEditingController();
  List<String> _items = [];
  @override
  void initState() {
    super.initState();
    final r = Provider.of<ResumeProvider>(context, listen: false).currentResume!;
    _items = List.from(r.skills); // Simplified to just skills for demo
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title), actions: [
      TextButton(onPressed: () {
        Provider.of<ResumeProvider>(context, listen: false).updateSkills(_items);
        Navigator.pop(context);
      }, child: const Text("SAVE"))
    ]),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: TextField(controller: _c, decoration: const InputDecoration(hintText: "Add item"))),
        IconButton(onPressed: () { if(_c.text.isNotEmpty) setState(()=>_items.add(_c.text)); _c.clear(); }, icon: const Icon(Icons.add))
      ])),
      Expanded(child: ListView.builder(itemCount: _items.length, itemBuilder: (c,i)=>ListTile(title: Text(_items[i]), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: ()=>setState(()=>_items.removeAt(i))))))
    ]),
  );
}

class ExperienceListScreen extends StatelessWidget {
  const ExperienceListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Experience")),
    body: Center(child: Text("Experience List Demo")), // Placeholder for brevity in demo
  );
}

class EducationListScreen extends StatelessWidget {
  const EducationListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Education")),
    body: Center(child: Text("Education List Demo")), // Placeholder for brevity in demo
  );
}
