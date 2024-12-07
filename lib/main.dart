import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // For Phone permission
import 'package:url_launcher/url_launcher.dart'; // For phone call and WhatsApp functionality
import 'services/student_service.dart'; // Assumed to be a custom service for fetching student data

void main() {
  runApp(const StudentDataApp());
}

class StudentDataApp extends StatelessWidget {
  const StudentDataApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Data App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const StudentHomePage(),
    );
  }
}

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({Key? key}) : super(key: key);

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final TextEditingController _studentIdController = TextEditingController();
  String? studentName;
  String? studentPhone;
  String? parentPhone;
  String? errorMessage;
  bool isLoading = false;

  Future<void> fetchStudentData() async {
    final studentId = _studentIdController.text.trim();

    if (studentId.isEmpty) {
      setState(() {
        errorMessage = "Please enter a valid Student ID.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await StudentService.fetchStudentData(studentId);

    setState(() {
      isLoading = false;
      if (result != null) {
        studentName = result['student_name'];
        studentPhone = result['student_phone'];
        parentPhone = result['parent_phone'];
        errorMessage = null;
      } else {
        studentName = null;
        studentPhone = null;
        parentPhone = null;
        errorMessage = "Student not found or an error occurred.";
      }
    });
  }

  Future<void> callPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await Permission.phone.isGranted) {
      try {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone call permission denied')),
      );
    }
  }

  Future<void> sendWhatsAppMessage(String phoneNumber) async {
    // Ensure the phone number starts with a plus sign for international calls
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+91$phoneNumber'; // Prepend +91 for India specifically
    }

    // Validate phone number format (optional but recommended)
    final phoneRegExp = RegExp(r'^\+?[0-9]{10,13}$');
    if (!phoneRegExp.hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number format. Please enter a valid phone number.')),
      );
      return;
    }

    // WhatsApp URL
    final whatsappUri = Uri.parse("https://wa.me/$phoneNumber");

    try {
      bool canLaunch = await canLaunchUrl(whatsappUri);
      if (canLaunch) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed or cannot handle this URL')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Data App'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'Student ID',
                  hintText: 'Enter student ID',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchStudentData,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blueAccent,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Fetch Student Data', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              if (studentName != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Name: $studentName',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildPhoneInfoRow('Student Phone', studentPhone),
                    const SizedBox(height: 16),
                    _buildPhoneInfoRow('Parent Phone', parentPhone),
                    const SizedBox(height: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildPhoneInfoRow(String label, String? phone) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: $phone',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            if (phone != null) {
              callPhone(phone);
            }
          },
          icon: const Icon(Icons.phone),
          label: const Text('Call'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            if (phone != null) {
              sendWhatsAppMessage(phone);
            }
          },
          icon: const Icon(Icons.message),
          label: const Text('WhatsApp'),
        ),
      ],
    );
  }
}
