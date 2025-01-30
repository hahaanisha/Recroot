import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Homepagec extends StatelessWidget {
  final String UID;

  Homepagec({super.key, required this.UID});

  final cloudinary = Cloudinary.signedConfig(
    apiKey: '858715427839214',
    apiSecret: '9ag4M0yqcaJMAY2oSPQ0j6BDehE',
    cloudName: 'dzvaf0hgm',
  );

  Future<List<Map<String, dynamic>>> _fetchJobsFromDatabase() async {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('jobs');
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> jobs = [];
      snapshot.children.forEach((userJobs) {
        userJobs.children.forEach((job) {
          final jobData = job.value as Map<dynamic, dynamic>;
          jobs.add({
            'key': job.key,
            'companyUID': userJobs.key,
            ...jobData,
          });
        });
      });
      return jobs;
    } else {
      return [];
    }
  }

  Future<String?> _uploadFileToCloudinary(File file) async {
    final response = await cloudinary.upload(
      file: file.path,
      resourceType: CloudinaryResourceType.auto,
      folder: 'resumes',
    );

    if (response.isSuccessful) {
      return response.secureUrl;
    } else {
      return null;
    }
  }

  Future<double?> _getAtsScore(String resumeUrl) async {
    const String apiUrl = "https://flask-hello-world-d1ep.onrender.com/ats-score"; // Update with your API endpoint

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
      "resume_url": resumeUrl,
      "job_desc": "Software Engineer with Python experience"
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["ats_score"]; // Ensure your API returns `ats_score`
    } else {
      return null;
    }
  }

  Future<void> _applyForJob(BuildContext context, String companyUID, String jobKey) async {
    final TextEditingController whySuitableController = TextEditingController();
    final TextEditingController skillsController = TextEditingController();
    final TextEditingController experienceController = TextEditingController();
    File? selectedResume;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Apply for Job"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: whySuitableController,
                  decoration: const InputDecoration(
                    labelText: "Why are you suitable for this job?",
                  ),
                ),
                TextField(
                  controller: skillsController,
                  decoration: const InputDecoration(
                    labelText: "What relevant skills do you have?",
                  ),
                ),
                TextField(
                  controller: experienceController,
                  decoration: const InputDecoration(
                    labelText: "Any past experience related to this job?",
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'doc', 'docx'],
                    );
                    if (result != null && result.files.single.path != null) {
                      selectedResume = File(result.files.single.path!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Resume Selected: ${result.files.single.name}")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No file selected.")),
                      );
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Resume"),
                ),
                if (selectedResume != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Selected File: ${selectedResume!.path.split('/').last}",
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (selectedResume == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please upload your resume before submitting.")),
                  );
                  return;
                }

                // Upload file to Cloudinary
                final uploadedUrl = await _uploadFileToCloudinary(selectedResume!);
                if (uploadedUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to upload resume. Please try again.")),
                  );
                  return;
                }

                // Get ATS Score from API
                final atsScore = await _getAtsScore(uploadedUrl);
                if (atsScore == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to retrieve ATS score.")),
                  );
                  return;
                }

                // Save application details in Firebase
                final DatabaseReference dbRef = FirebaseDatabase.instance.ref(
                    'applications/$companyUID/$jobKey');
                await dbRef.push().set({
                  'UID': UID,
                  'whySuitable': whySuitableController.text,
                  'skills': skillsController.text,
                  'experience': experienceController.text,
                  'resumeUrl': uploadedUrl,
                  'atsScore': atsScore, // Store ATS score in Firebase
                  'appliedAt': DateTime.now().toIso8601String(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Applied successfully!")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  int _calculateRemainingDays(String deadline) {
    final DateTime deadlineDate = DateFormat('yyyy-MM-dd').parse(deadline);
    final DateTime currentDate = DateTime.now();
    return deadlineDate.difference(currentDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Homepage'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchJobsFromDatabase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No jobs available.'));
          } else {
            final jobs = snapshot.data!;
            return ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final int remainingDays = _calculateRemainingDays(job['deadline'] ?? '9999-12-31');
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(job['jobTitle'] ?? 'No Title'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stipend: ${job['stipend'] ?? 'N/A'}'),
                        Text('Duration: ${job['duration'] ?? 'N/A'} months'),
                        Text('Role: ${job['jobRole'] ?? 'N/A'}'),
                        Text('Remaining Days: ${remainingDays >= 0 ? remainingDays : 'Deadline Passed'}'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: remainingDays >= 0
                          ? () => _applyForJob(context, job['companyUID'], job['key'])
                          : null,
                      child: const Text("Apply"),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
