import 'package:flutter/material.dart';
import '../../auth/interviewer/SignUpI.dart';
import '../../auth/recruiter/signUpR.dart';
import 'HomePageR.dart';
import 'JobPageR.dart';
import 'candidatesListPageFinalR.dart';
import 'displayJobs.dart';

class BottomNavBarR extends StatefulWidget {
  final dynamic companyUID;

  const BottomNavBarR({super.key, required this.companyUID});

  @override
  _BottomNavBarRState createState() => _BottomNavBarRState();
}

class _BottomNavBarRState extends State<BottomNavBarR> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define _pages here so it can access widget.companyUID
    final List<Widget> _pages = [
      Homepager(UID: widget.companyUID,),
      CompanyJobsPage(companyUID: widget.companyUID), // Pass companyUID here
      DisplayJobsR(UID: widget.companyUID,),
      // const ProfileScreen(),
      CandidatesListPage(jobUID: '-OHJ2Hf-h5MXugJqBQtV',),
      SignUpPageI(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_applications), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.all_inbox_outlined), label: 'All Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.wb_incandescent_rounded), label: 'Selected Application'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Add Recruiter'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile Page', style: TextStyle(fontSize: 24))),
    );
  }
}
