import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'InterviewForm.dart';

class JobsListI extends StatefulWidget {
  final String UID;

  JobsListI({super.key, required this.UID});

  @override
  _JobsListIState createState() => _JobsListIState();
}

class _JobsListIState extends State<JobsListI> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> interviewsList = [];
  Map<String, Map<String, dynamic>> candidates = {}; // Store candidate data
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCandidates();
  }

  Future<void> fetchCandidates() async {
    final candidateRef = _dbRef.child("candidates");

    candidateRef.once().then((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        Map<String, Map<String, dynamic>> fetchedCandidates = {};
        data.forEach((key, value) {
          fetchedCandidates[key] = {
            "name": value["name"],
            "resumeUrl": value["resumeUrl"] ?? ""
          };
        });

        setState(() {
          candidates = fetchedCandidates;
        });

        fetchInterviews();
      }
    });
  }

  Future<void> fetchInterviews() async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _dbRef.child("interviews").once().then((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, dynamic>> fetchedInterviews = [];

        data.forEach((recruiterId, jobData) {
          jobData.forEach((jobUID, interviewData) {
            interviewData.forEach((interviewUID, details) {
              if (details["interviewerUID"] == userId) {
                fetchedInterviews.add({
                  "candidateId": details["candidateUID"],
                  "candidateName": candidates[details["candidateUID"]]?["name"] ?? "Unknown",
                  "resumeUrl": candidates[details["candidateUID"]]?["resumeUrl"] ?? "",
                  "date": details["date"],
                  "time": details["time"],
                  "jobUID": details["jobUID"],
                });
              }
            });
          });
        });

        setState(() {
          interviewsList = fetchedInterviews;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    });
  }

  Future<void> _openResume(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open resume')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Interviews")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : interviewsList.isEmpty
          ? Center(child: Text("No Interviews Found"))
          : ListView.builder(
        itemCount: interviewsList.length,
        itemBuilder: (context, index) {
          var interview = interviewsList[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Candidate: ${interview['candidateName']}"),
                  if (interview['resumeUrl'].isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        _openResume(interview['resumeUrl']);
                      },
                      child: Text("View Resume"),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Date: ${interview['date']}"),
                  Text("Time: ${interview['time']}"),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InterviewForm(
                        candidateId: interview['candidateId'],
                        candidateName: interview['candidateName'],
                        jobUID: interview['jobUID'],
                      ),
                    ),
                  );
                },
                child: Text("Start"),
              ),
            ),
          );
        },
      ),
    );
  }
}
