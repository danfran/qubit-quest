import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class QuantumTaskDialog extends StatelessWidget {
  final String taskDescription;

  const QuantumTaskDialog({
    Key? key,
    required this.taskDescription, // Level is now required
  }) : super(key: key);

  TeXViewInkWell _buildTaskDescription(String name, String description) {
    return TeXViewInkWell(
      id: r"id_0",
      child: TeXViewColumn(children: [
        TeXViewDocument(
          name,
          style: TeXViewStyle(
              padding: const TeXViewPadding.all(10),
              borderRadius: TeXViewBorderRadius.all(10),
              textAlign: TeXViewTextAlign.center,
              // width: 250,
              margin: const TeXViewMargin.zeroAuto(),
              backgroundColor: Colors.blueGrey[700],
              contentColor: Colors.white,),
        ),
        TeXViewDocument(description, style: const TeXViewStyle(margin: TeXViewMargin.only(top: 10), contentColor: Colors.green)),
      ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This build method returns the AlertDialog widget
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      // title: Text("Quantum Gates List"),
      content: Container( // Wrap content in Container for size constraints if needed
        width: double.maxFinite, // Allow content to take max width available in dialog
        child: SingleChildScrollView( // Add scrolling for the content
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0),
            child: TeXView(
              child: TeXViewColumn(
                  style: const TeXViewStyle(
                      margin: TeXViewMargin.all(10),
                      padding: TeXViewPadding.all(10),
                      borderRadius: TeXViewBorderRadius.all(10),
                      border: TeXViewBorder.all(TeXViewBorderDecoration(
                          borderWidth: 4,
                          borderStyle: TeXViewBorderStyle.groove,
                          borderColor: Colors.yellowAccent))
                  ),
                  children: [
                    _buildTaskDescription(
                        r"<h2>Task</h2>",
                        taskDescription
                    ),
                  ]),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}