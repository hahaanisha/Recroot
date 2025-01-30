import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class InterviewForm extends StatefulWidget {
  final String candidateId;
  final String candidateName;
  final String jobUID;

  InterviewForm({required this.candidateId, required this.candidateName, required this.jobUID});

  @override
  _InterviewFormState createState() => _InterviewFormState();
}

class _InterviewFormState extends State<InterviewForm> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("completed_interviews");
  final DatabaseReference _appRef = FirebaseDatabase.instance.ref("applications");
  final DatabaseReference _intRef = FirebaseDatabase.instance.ref("interviews");

  Map<String, double> scores = {
    "Communication": 5.0,
    "Technical Knowledge": 5.0,
    "Problem-Solving": 5.0,
    "Confidence": 5.0,
    "Overall Impression": 5.0,
  };

  String? resumeUrl;
  String? applicationKey;

  @override
  void initState() {
    super.initState();
    fetchResumeUrl();
  }

  Future<void> fetchResumeUrl() async {
    try {
      final snapshot = await _appRef.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        for (var recruiterKey in data.keys) {
          for (var jobKey in data[recruiterKey].keys) {
            for (var appKey in data[recruiterKey][jobKey].keys) {
              var application = data[recruiterKey][jobKey][appKey];
              if (application["UID"] == widget.candidateId) {
                setState(() {
                  resumeUrl = application["resumeUrl"];
                  applicationKey = "/$recruiterKey/$jobKey/$appKey";
                });
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching resume URL: $e");
    }
  }

  void submitInterview() {
    double total = scores.values.reduce((a, b) => a + b);
    double avgScore = total / scores.length;

    String interviewKey = widget.candidateId + "_" + widget.jobUID;

    _dbRef.child(interviewKey).set({
      "candidateName": widget.candidateName,
      "candidateUID": widget.candidateId,
      "jobUID": widget.jobUID,
      "avgScore": avgScore,
    }).then((_) {
      if (applicationKey != null) {
        _intRef.child(applicationKey!).remove().then((_) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Interview Submitted and Candidate Data Removed!")));
          Navigator.pop(context);
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error removing candidate data: $error")));
        });
      }
    });
  }

  Future<void> _openResume() async {
    if (resumeUrl != null && await canLaunchUrl(Uri.parse(resumeUrl!))) {
      await launchUrl(Uri.parse(resumeUrl!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid or missing resume URL")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Interview Form")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Candidate: ${widget.candidateName}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            if (resumeUrl != null)
              ElevatedButton(
                onPressed: _openResume,
                child: Text("View Resume"),
              )
            else
              Text("Loading resume link..."),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: scores.keys.map((criterion) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(criterion, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Slider(
                        value: scores[criterion]!,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: scores[criterion]!.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            scores[criterion] = value;
                          });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: submitInterview,
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
