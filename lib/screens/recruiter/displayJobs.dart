import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DisplayJobsR extends StatelessWidget {
  final String UID;

  const DisplayJobsR({super.key, required this.UID});

  Future<List<Map<String, dynamic>>> _fetchJobsFromDatabase() async {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('jobs');
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> jobs = [];
      snapshot.children.forEach((userJobs) {
        userJobs.children.forEach((job) {
          final jobData = job.value as Map<dynamic, dynamic>;
          jobs.add({
            'key': job.key, // To uniquely identify the job for editing or deleting
            ...jobData,
          });
        });
      });
      return jobs;
    } else {
      return [];
    }
  }

  void _deleteJob(String jobKey, BuildContext context) async {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('jobs/$jobKey');
    await dbRef.remove();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job deleted successfully.')));
  }

  void _editJob(BuildContext context, String jobKey, Map<String, dynamic> jobDetails) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditJobPage(UID: UID, jobKey: jobKey, jobDetails: jobDetails),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate HP'),
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
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editJob(context, job['key'], job),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteJob(job['key'], context),
                        ),
                      ],
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
        title: const Text('Job Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${job['jobTitle'] ?? 'No Title'}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Stipend: ${job['stipend'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Duration: ${job['duration'] ?? 'N/A'} months'),
            const SizedBox(height: 8),
            Text('Role: ${job['jobRole'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('No. of Positions: ${job['noOfPositions'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Location: ${job['location'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Description: ${job['jobDescription'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Skills Required: ${job['skillsRequired'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}

class EditJobPage extends StatefulWidget {
  final String UID;
  final String jobKey;
  final Map<String, dynamic> jobDetails;

  const EditJobPage({
    super.key,
    required this.UID,
    required this.jobKey,
    required this.jobDetails,
  });

  @override
  State<EditJobPage> createState() => _EditJobPageState();
}

class _EditJobPageState extends State<EditJobPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _stipendController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  String _jobRole = '';

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.jobDetails['jobTitle'] ?? '';
    _stipendController.text = widget.jobDetails['stipend'] ?? '';
    _durationController.text = widget.jobDetails['duration']?.toString() ?? '';
    _jobRole = widget.jobDetails['jobRole'] ?? 'Internship';
  }

  void _updateJob() async {
    if (_formKey.currentState!.validate()) {
      final updatedJob = {
        'jobTitle': _titleController.text,
        'stipend': _stipendController.text,
        'duration': int.parse(_durationController.text),
        'jobRole': _jobRole,
      };

      final dbRef = FirebaseDatabase.instance.ref('jobs/${widget.UID}/${widget.jobKey}');
      await dbRef.update(updatedJob);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job updated successfully!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Job'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Job Title'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter job title' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stipendController,
                decoration: const InputDecoration(labelText: 'Stipend'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter stipend' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (in months)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Please enter duration' : null,
              ),
              const SizedBox(height: 16),
              const Text('Job Role:'),
              Row(
                children: [
                  _buildRadioOption('Internship'),
                  _buildRadioOption('Full-time'),
                  _buildRadioOption('Part-time'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateJob,
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String role) {
    return Row(
      children: [
        Radio<String>(
          value: role,
          groupValue: _jobRole,
          onChanged: (value) {
            setState(() {
              _jobRole = value!;
            });
          },
        ),
        Text(role),
      ],
    );
  }
}
