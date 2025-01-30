import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class InterviewSchedulePageR extends StatefulWidget {
  final String candidateUID;
  final String jobID;
  final String companyUID;

  const InterviewSchedulePageR({
    super.key,
    required this.candidateUID,
    required this.jobID,
    required this.companyUID,
  });

  @override
  State<InterviewSchedulePageR> createState() => _InterviewSchedulePageRState();
}

class _InterviewSchedulePageRState extends State<InterviewSchedulePageR> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedInterviewer;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Function to pick a date
  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  /// Function to pick a time
  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }
  Future<List<Map<String, String>>> _fetchInterviewers() async {
    DataSnapshot snapshot = await _dbRef.child('interviewers').get();
    if (snapshot.exists && snapshot.value is Map) {
      Map<dynamic, dynamic> interviewers = snapshot.value as Map<dynamic, dynamic>;
      return interviewers.entries.map((entry) {
        return {
          'uid': entry.key.toString(), // Convert to String
          'name': entry.value['name'].toString(), // Convert to String
        };
      }).toList();
    }
    return [];
  }

  /// Function to submit the interview schedule
  Future<void> _submitSchedule() async {
    if (_selectedDate == null || _selectedTime == null || _selectedInterviewer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    String formattedDate = "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}";
    String formattedTime = "${_selectedTime!.hour}:${_selectedTime!.minute}";

    // Firebase Realtime Database Path: interviews/companyUID/jobUID
    DatabaseReference interviewRef = _dbRef
        .child('interviews')
        .child(widget.companyUID)
        .child(widget.jobID)
        .push(); // Generates a unique ID for each interview

    await interviewRef.set({
      'candidateUID': widget.candidateUID,
      'jobUID': widget.jobID,
      'interviewerUID': _selectedInterviewer,
      'date': formattedDate,
      'time': formattedTime,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Interview scheduled successfully!')),
    );

    Navigator.pop(context); // Go back after scheduling
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Interview')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Picker
            ElevatedButton(
              onPressed: () => _pickDate(context),
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}',
              ),
            ),

            const SizedBox(height: 10),

            // Time Picker
            ElevatedButton(
              onPressed: () => _pickTime(context),
              child: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : '${_selectedTime!.hour}:${_selectedTime!.minute}',
              ),
            ),

            const SizedBox(height: 10),

            // Fetch Interviewers from Firebase Realtime Database
            FutureBuilder<List<Map<String, String>>>(
              future: _fetchInterviewers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                return DropdownButton<String>(
                  hint: const Text('Select Interviewer'),
                  value: _selectedInterviewer,
                  onChanged: (value) {
                    setState(() {
                      _selectedInterviewer = value;
                    });
                  },
                  items: snapshot.data!.map((interviewer) {
                    return DropdownMenuItem(
                      value: interviewer['uid'],
                      child: Text(interviewer['name']!),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _submitSchedule,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
