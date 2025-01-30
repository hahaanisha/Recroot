import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class CandidatesListPage extends StatefulWidget {
  final String jobUID;

  CandidatesListPage({required this.jobUID});

  @override
  _CandidatesListPageState createState() => _CandidatesListPageState();
}

class _CandidatesListPageState extends State<CandidatesListPage> {
  final DatabaseReference _completedInterviewsRef =
  FirebaseDatabase.instance.ref("completed_interviews");

  List<Map<String, dynamic>> candidates = [];

  @override
  void initState() {
    super.initState();
    fetchCandidates();
  }

  Future<void> fetchCandidates() async {
    final snapshot = await _completedInterviewsRef.once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

    List<Map<String, dynamic>> fetchedCandidates = [];

    if (data != null) {
      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic> &&
            value["jobUID"] == widget.jobUID) {
          fetchedCandidates.add({
            "candidateName": value["candidateName"],
            "candidateUID": value["candidateUID"],
            "data": Map<String, dynamic>.from(value), // Ensure proper casting here
          });
        }
      });
    }

    setState(() {
      candidates = fetchedCandidates;
    });
  }

  void viewCandidateData(Map<String, dynamic> candidateData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CandidateDetailPage(candidateData: candidateData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Candidates for Job: ${widget.jobUID}"),
      ),
      body: candidates.isEmpty
          ? Center(child: Text("No candidates found"))
          : ListView.builder(
        itemCount: candidates.length,
        itemBuilder: (context, index) {
          final candidate = candidates[index];
          return ListTile(
            title: Text(candidate["candidateName"]),
            trailing: ElevatedButton(
              onPressed: () => viewCandidateData(candidate["data"]),
              child: Text("View"),
            ),
          );
        },
      ),
    );
  }
}

class CandidateDetailPage extends StatelessWidget {
  final Map<String, dynamic> candidateData;

  CandidateDetailPage({required this.candidateData});

  Future<void> _generateOfferLetterPDF(String candidateName, String jobTitle,
      String avgScore, String candidateUID) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Offer Letter', style: pw.TextStyle(fontSize: 24)),
                  pw.SizedBox(height: 20),
                  pw.Text('Candidate Name: $candidateName',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Text('Job Title: $jobTitle',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Text('Candidate UID: $candidateUID',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Text('Average Score: $avgScore',
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Congratulations! You are selected for the position.',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/OfferLetter_$candidateName.pdf");
    await file.writeAsBytes(await pdf.save());

    // Open the generated PDF file
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final candidateName = candidateData["candidateName"] ?? "N/A";
    final jobTitle = candidateData["jobUID"] ?? "N/A";
    final avgScore = candidateData["avgScore"]?.toString() ?? "N/A";
    final candidateUID = candidateData["candidateUID"] ?? "N/A";

    return Scaffold(
      appBar: AppBar(
        title: Text("Candidate Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: $candidateName",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("UID: $candidateUID"),
            SizedBox(height: 8),
            Text("Job Title: $jobTitle"),
            SizedBox(height: 8),
            Text("Average Score: $avgScore"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _generateOfferLetterPDF(
                    candidateName, jobTitle, avgScore, candidateUID);
              },
              child: Text("Print Offer Letter"),
            ),
          ],
        ),
      ),
    );
  }
}
