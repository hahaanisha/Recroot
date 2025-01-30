import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:recroot/screens/recruiter/InterviewSchedulePage.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyJobsPage extends StatelessWidget {
  final String companyUID;

  const CompanyJobsPage({super.key, required this.companyUID});

  Future<List<Map<String, dynamic>>> _fetchCompanyJobsFromDatabase() async {
    final DatabaseReference dbRef =
    FirebaseDatabase.instance.ref('jobs/$companyUID');
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      List<Map<String, dynamic>> jobs = [];
      snapshot.children.forEach((job) {
        final jobData = job.value as Map<dynamic, dynamic>;
        jobs.add({
          'key': job.key,
          ...jobData,
        });
      });
      return jobs;
    } else {
      return [];
    }
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
        title: const Text('Posted Jobs'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCompanyJobsFromDatabase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No jobs posted yet.'));
          } else {
            final jobs = snapshot.data!;
            return ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final int remainingDays =
                _calculateRemainingDays(job['deadline'] ?? '9999-12-31');
                return Card(
                  margin:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                            color:
                            remainingDays >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CandidatesPage(
                              companyUID: companyUID,
                              jobKey: job['key'],
                            ),
                          ),
                        );
                      },
                      child: const Text('View'),
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

class CandidatesPage extends StatelessWidget {
  final String companyUID;
  final String jobKey;

  const CandidatesPage(
      {super.key, required this.companyUID, required this.jobKey});

  Future<List<Map<String, dynamic>>> _fetchCandidatesFromDatabase() async {
    final DatabaseReference dbRef =
    FirebaseDatabase.instance.ref('applications/$companyUID/$jobKey');
    final DatabaseReference candidateRef =
    FirebaseDatabase.instance.ref('candidates');
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      List<Map<String, dynamic>> candidates = [];
      for (var application in snapshot.children) {
        final applicationData = application.value as Map<dynamic, dynamic>;
        final candidateUID = applicationData['UID'];
        final candidateSnapshot = await candidateRef.child(candidateUID).get();
        final candidateName = candidateSnapshot.exists
            ? candidateSnapshot.child('name').value as String
            : 'Unknown Candidate';
        candidates.add({
          'applicationId': application.key,
          'name': candidateName,
          ...applicationData,
        });
      }
      candidates.sort((a, b) => (b['atsScore'] ?? 0).compareTo(a['atsScore'] ?? 0));
      return candidates;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applied Candidates'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCandidatesFromDatabase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No candidates have applied yet.'));
          } else {
            final candidates = snapshot.data!;
            return ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                return Card(
                  margin:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(candidate['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Applied On: ${candidate['appliedAt'] ?? 'N/A'}'),
                        Text('Experience: ${candidate['experience'] ?? 'N/A'}'),
                        Text('Skills: ${candidate['skills'] ?? 'N/A'}'),
                        Text('ATS Score: ${candidate['atsScore'] ?? 'N/A'}'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CandidateDetailsPage(
                                candidateDetails: candidate, jobUID: jobKey, companyUID: companyUID,),
                          ),
                        );
                      },
                      child: const Text('View Details'),
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

class CandidateDetailsPage extends StatelessWidget {
  final Map<dynamic, dynamic> candidateDetails;

  final dynamic jobUID;

  final dynamic companyUID;

  const CandidateDetailsPage({super.key, required this.candidateDetails,required this.jobUID,required this.companyUID});

  Future<Map<dynamic, dynamic>> _fetchCandidateDetails() async {
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref('candidates/${candidateDetails['UID']}');
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      return snapshot.value as Map<dynamic, dynamic>;
    } else {
      return {};
    }
  }
  // Future<void> _launchURL(String url) async {
  //   if (await canLaunch(url)) {
  //     await launch(url);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  // }

  Future<void> _launchUrl(String _url) async {
    final Uri uri = Uri.parse(_url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Details'),
      ),
      body: FutureBuilder<Map<dynamic, dynamic>>(
        future: _fetchCandidateDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No details found.'));
          } else {
            final details = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${details['name'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 18)),
                  Text('Email: ${details['email'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 18)),
                  Text('Phone: ${details['phone'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 18)),
                  // Text('UID: ${candidateDetails['UID']}',
                  //     style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Experience: ${candidateDetails['experience']}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Skills: ${candidateDetails['skills']}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Why Suitable: ${candidateDetails['whySuitable']}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Applied At: ${candidateDetails['appliedAt']}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('ATS Score: ${candidateDetails['atsScore']}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  if (candidateDetails['resumeUrl'] != null)
                    GestureDetector(
                      onTap: () {
                        // Add logic to open the resume URL in a browser or download it
                        _launchUrl(candidateDetails['resumeUrl']);
                      },
                      child: ElevatedButton(
                        onPressed: () {
                          _launchUrl(candidateDetails['resumeUrl']);
                        },
                        child: Text(
                          'Resume: Click to View',
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InterviewSchedulePageR(candidateUID: candidateDetails['UID'], jobID: jobUID.toString(), companyUID: companyUID.toString(),)),
                    );
                  },
                      child: Text('Schedule an Interview'))
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
