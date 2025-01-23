import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddJobPage extends StatefulWidget {
  const AddJobPage({Key? key}) : super(key: key);

  @override
  State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("jobs");
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _positionsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _stipendController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String _jobRole = "Internship"; // Default job role
  String _location = "Remote"; // Default location

  void _postJob() async {
    if (_formKey.currentState!.validate()) {
      try {
        final User? user = _auth.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to post a job.')),
          );
          return;
        }

        final jobData = {
          'jobTitle': _titleController.text,
          'noOfPositions': int.parse(_positionsController.text),
          'jobDescription': _descriptionController.text,
          'skillsRequired': _skillsController.text,
          'stipend': _stipendController.text,
          'jobRole': _jobRole,
          'location': _location,
          'duration': int.parse(_durationController.text),
        };

        // Push job data to jobs/{UID} node in Firebase Realtime Database
        await _databaseRef.child(user.uid).push().set(jobData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')),
        );

        // Clear the form after successful submission
        _formKey.currentState!.reset();
        _jobRole = "Internship";
        _location = "Remote";
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post job: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Job'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(_titleController, 'Job Title'),
                _buildTextField(
                  _positionsController,
                  'No of Positions',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(_descriptionController, 'Job Description', maxLines: 5),
                _buildTextField(_skillsController, 'Skills Required'),
                _buildTextField(
                  _stipendController,
                  'Stipend',
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  _durationController,
                  'Duration (in months)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Job Role:'),
                Row(
                  children: [
                    _buildRadioOption('Internship', _jobRole, (value) {
                      setState(() {
                        _jobRole = value!;
                      });
                    }),
                    _buildRadioOption('Full-time', _jobRole, (value) {
                      setState(() {
                        _jobRole = value!;
                      });
                    }),
                    _buildRadioOption('Part-time', _jobRole, (value) {
                      setState(() {
                        _jobRole = value!;
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Location:'),
                Row(
                  children: [
                    _buildRadioOption('Remote', _location, (value) {
                      setState(() {
                        _location = value!;
                      });
                    }),
                    _buildRadioOption('Onsite', _location, (value) {
                      setState(() {
                        _location = value!;
                      });
                    }),
                    _buildRadioOption('Hybrid', _location, (value) {
                      setState(() {
                        _location = value!;
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _postJob,
                    child: const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: label,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRadioOption(String label, String groupValue, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        Radio<String>(
          value: label,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        Text(label),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _positionsController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _stipendController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
