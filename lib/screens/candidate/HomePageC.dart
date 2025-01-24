import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // For date formatting and calculations
import 'package:file_picker/file_picker.dart'; // For file selection
import 'dart:io'; // For working with files

class Homepagec extends StatelessWidget {
  final String UID;

  const Homepagec({super.key, required this.UID});

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
            'companyUID': userJobs.key,// Unique identifier for the job
            ...jobData,
          });
        });
      });
      return jobs;
    } else {
      return [];
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

                final DatabaseReference dbRef = FirebaseDatabase.instance.ref(
                    'applications/$companyUID/$jobKey');
                await dbRef.push().set({
                  'UID': UID,
                  'whySuitable': whySuitableController.text,
                  'skills': skillsController.text,
                  'experience': experienceController.text,
                  'resumePath': selectedResume!.path,
                  'appliedAt': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Applied successfully!")),
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
                        const SizedBox(height: 8),
                        Text(
                          'Remaining Days: ${remainingDays >= 0 ? remainingDays : 'Deadline Passed'}',
                          style: TextStyle(
                            color: remainingDays >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: remainingDays >= 0
                          ? () => _applyForJob(context, job['companyUID'], job['key'])
                          : null,
                      child: const Text("Apply"),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobDetailsPage(job: job),
                        ),
                      );
                    },
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

class JobDetailsPage extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailsPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(job['jobTitle'] ?? 'Job Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Title: ${job['jobTitle'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Stipend: ${job['stipend'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Duration: ${job['duration'] ?? 'N/A'} months'),
            const SizedBox(height: 8),
            Text('Role: ${job['jobRole'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Job Description: ${job['jobDescription'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Deadline: ${job['deadline'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}
