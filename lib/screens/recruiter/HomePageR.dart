import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'AddJobPageR.dart';

class Homepager extends StatelessWidget {
  final String UID;

  const Homepager({super.key, required this.UID});

  Future<String> _fetchNameFromDatabase() async {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('recruiters/$UID');
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      return snapshot.child('name').value.toString();
    } else {
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recruiter's Page"),
      ),
      body: FutureBuilder<String>(
        future: _fetchNameFromDatabase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final name = snapshot.data ?? 'Unknown User';
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, $name',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your UID: $UID',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddJobPage()),
                  );
                }, child: Text('Add Job'))
              ],
            );
          }
        },
      ),
    );
  }
}
