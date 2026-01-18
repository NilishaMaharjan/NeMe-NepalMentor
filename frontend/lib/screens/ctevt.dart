import 'package:flutter/material.dart';
import 'common_bottom_navigation.dart';
import 'mentor_search_page.dart'; // Ensure MentorSearchPage is defined

/// CTEVTLevelHome displays a list of CTEVT levels.
/// Tapping a level navigates to CTEVTGradeSubjectsNavigationPage.
class CTEVTLevelHome extends StatelessWidget {
  const CTEVTLevelHome({Key? key}) : super(key: key);

  // Map of CTEVT levels to their subjects.
  static const Map<String, List<String>> gradeSubjects = {
    'Level 1': [
      'English',
      'Mathematics',
      'ICT Basics',
      'Workshop Practices',
      'Technical Drawing'
    ],
    'Level 2': [
      'English',
      'Mathematics',
      'Electrical Fundamentals',
      'Basic Electronics',
      'Mechanics & Machines'
    ],
    'Level 3': [
      'English',
      'Mathematics',
      'Advanced Mechanics',
      'Automation & Control',
      'Project Management'
    ],
  };

  /// Helper method to build a row-styled card.
  static Widget buildCard(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w400, color: Colors.teal),
          ),
          const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.teal),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The AppBar is provided by CommonBottomNavigation.
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: gradeSubjects.keys.length,
          itemBuilder: (context, index) {
            String level = gradeSubjects.keys.elementAt(index);
            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to the subjects page for the selected level.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CTEVTGradeSubjectsNavigationPage(
                          grade: level,
                          subjects: gradeSubjects[level]!,
                        ),
                      ),
                    );
                  },
                  child: buildCard(level),
                ),
                if (index < gradeSubjects.keys.length - 1)
                  Divider(color: Colors.grey[300]),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// CTEVTGradeSubjectsContent displays the list of subjects for a selected CTEVT level.
class CTEVTGradeSubjectsContent extends StatelessWidget {
  final String grade;
  final List<String> subjects;

  const CTEVTGradeSubjectsContent({
    Key? key,
    required this.grade,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Here we simply use the grade as provided.
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          String subject = subjects[index];
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to MentorSearchPage for the selected subject.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MentorSearchPage(
                        category: "CTEVT",
                        classLevel: grade, // using level as classLevel
                        subject: subject,
                      ),
                    ),
                  );
                },
                child: CTEVTLevelHome.buildCard(subject),
              ),
              if (index < subjects.length - 1) Divider(color: Colors.grey[300]),
            ],
          );
        },
      ),
    );
  }
}

/// CTEVTGradeSubjectsNavigationPage wraps the subjects content in CommonBottomNavigation
/// using section mode. It displays a custom title (e.g. "Level 1 Subjects") along with the subjects list.
/// Once the user taps any bottom navigation item, section mode is disabled.
class CTEVTGradeSubjectsNavigationPage extends StatelessWidget {
  final String grade;
  final List<String> subjects;

  const CTEVTGradeSubjectsNavigationPage({
    Key? key,
    required this.grade,
    required this.subjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent:
          CTEVTGradeSubjectsContent(grade: grade, subjects: subjects),
      sectionTitle: '$grade Subjects',
      startWithSectionContent: true,
    );
  }
}

/// CTEVTLevelPage uses CommonBottomNavigation in section mode so that by default
/// the CTEVT level content (grade list) is shown with a custom title ("CTEVT Level").
/// The bottom navigation always remains the same global set of 4 items.
class CTEVTLevelPage extends StatelessWidget {
  const CTEVTLevelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonBottomNavigation(
      sectionContent: const CTEVTLevelHome(),
      sectionTitle: 'CTEVT Level',
      startWithSectionContent: true,
    );
  }
}