import 'package:flutter/material.dart';

import '../recruiter/JobPageR.dart';
import '../recruiter/displayJobs.dart';
import 'HomePageC.dart';


class BottomNavBarC extends StatefulWidget {
  final dynamic candidateUID;

  const BottomNavBarC({super.key, required this.candidateUID});

  @override
  _BottomNavBarCState createState() => _BottomNavBarCState();
}

class _BottomNavBarCState extends State<BottomNavBarC> {
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
      Homepagec(UID: widget.candidateUID,),
      CompanyJobsPage(companyUID: widget.candidateUID), // Pass companyUID here
      DisplayJobsR(UID: widget.candidateUID,),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_applications), label: 'Applications'),
          BottomNavigationBarItem(icon: Icon(Icons.all_inbox_outlined), label: 'All Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
