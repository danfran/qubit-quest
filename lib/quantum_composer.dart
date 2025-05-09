import 'package:complex/complex.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:quantumquiz/probability_histogram.dart';
import 'package:quantumquiz/quantum_circuit.dart';
import 'package:quantumquiz/quantum_circuit_painter.dart';
import 'package:quantumquiz/quantum_gate.dart';
import 'package:flutter/material.dart';

import 'math_utils.dart';

class QuantumComposer extends StatefulWidget {
  @override
  _QuantumComposerState createState() => _QuantumComposerState();
}

class _QuantumComposerState extends State<QuantumComposer> {
  final QuantumCircuit circuit = QuantumCircuit();
  String simulationResult = "Run the circuit to see the result";
  SelectedGateType _selectedGateType = SelectedGateType.none;
  int? _cnotControlQubit; // To track the first tap for CNOT
  List<List<Complex>> overallCircuitMatrix = identityMatrix;
  List<double> measurementProbabilities = [0.0, 0.0, 0.0, 0.0];

  void _selectGateForPlacement(SelectedGateType gateType) {
    setState(() {
      _selectedGateType = gateType;
      _cnotControlQubit = null; // Reset CNOT control on new gate selection
      simulationResult = "Tap on a qubit line to place the gate.";
      if (gateType == SelectedGateType.cnot) {
        simulationResult = "Tap on the control qubit for CNOT.";
      } else if (gateType == SelectedGateType.none) {
        simulationResult = "Run the circuit to see the result";
      }
    });
    print('Selected gate type for placement: $_selectedGateType'); // Debug selected gate
  }

  // ** Add a GlobalKey for the GestureDetector **
  final GlobalKey _gestureDetectorKey = GlobalKey();
  // *****************************************


  void _handleCircuitTap(TapDownDetails details) {
    print('Circuit tapped at global position: ${details.globalPosition.dx}, ${details.globalPosition.dy}');

    // ** Get the RenderBox using the GlobalKey **
    final RenderBox? renderBox = _gestureDetectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      print('Error: Could not find RenderBox for GestureDetector.');
      return; // Exit if RenderBox is not found
    }
    // *****************************************


    print('RenderBox size: ${renderBox.size.width}x${renderBox.size.height}');
    final Offset localTopLeft = renderBox.globalToLocal(Offset.zero);
    print('RenderBox local top-left (should be 0,0): ${localTopLeft.dx}, ${localTopLeft.dy}');
    final Offset globalTopLeft = renderBox.localToGlobal(Offset.zero);
    print('RenderBox global top-left: ${globalTopLeft.dx}, ${globalTopLeft.dy}');


    if (_selectedGateType == SelectedGateType.none) {
      print('No gate selected for placement.');
      return;
    }

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Pass the actual size of the render box to the painter's hit test
    final painter = QuantumCircuitPainter(circuit); // Painter instance
    final tappedQubit = painter.getTappedQubit(localPosition); // Use the painter's method

    if (tappedQubit != null) {
      print('Tapped on Qubit: $tappedQubit');
      if (_selectedGateType == SelectedGateType.hadamard) {
        circuit.addGate(HadamardGate(tappedQubit));
        print('Added Hadamard to Qubit $tappedQubit');
        _selectGateForPlacement(SelectedGateType.none);
      } else if (_selectedGateType == SelectedGateType.cnot) {
        if (_cnotControlQubit == null) {
          _cnotControlQubit = tappedQubit;
          setState(() {
            simulationResult = "Tap on the target qubit for CNOT.";
          });
          print('CNOT control qubit selected: $_cnotControlQubit');
        } else {
          if (_cnotControlQubit != tappedQubit) {
            circuit.addGate(CNOTGate(_cnotControlQubit!, tappedQubit));
            print('Added CNOT from Qubit $_cnotControlQubit to Qubit $tappedQubit');
            _selectGateForPlacement(SelectedGateType.none);
          } else {
            setState(() {
              simulationResult = "Control and target qubits cannot be the same. Tap target qubit.";
            });
            print('CNOT control and target are the same.');
          }
        }
      }
      setState(() {});
    } else {
      print('Tapped outside qubit lines.');
      if (_selectedGateType != SelectedGateType.none) {
        _selectGateForPlacement(SelectedGateType.none);
      }
    }
  }

  void _updateOverallMatrix() {
    overallCircuitMatrix = circuit.getOverallMatrix();
    // No setState here, setState is called in _handleCircuitTap or _clearCircuit
  }

  void _runSimulation() {
    circuit.run();
    measurementProbabilities = circuit.currentState.state.map((amplitude) {
      return amplitude.abs() * amplitude.abs();
    }).toList();

    // ** Add this debug print **
    print("Calculated probabilities: $measurementProbabilities");
    // ************************


    setState(() {
      simulationResult = "State Vector: ${circuit.currentState.toString()}";
    });
  }

  void _clearCircuit() {
    circuit.clearCircuit();
    setState(() {
      simulationResult = "Run the circuit to see the result";
      _selectedGateType = SelectedGateType.none; // Reset any active placement
      _cnotControlQubit = null;
    });
    print('Circuit cleared.'); // Debug circuit clear
  }

  void _showGateListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                              borderWidth: 2,
                              borderStyle: TeXViewBorderStyle.groove,
                              borderColor: Colors.green))),
                      children: [
                _buildGateDescription(
                      r"<h2>Pauli-X (\( X \))</h2>",
                      r"<p>Performs a bit flip, equivalent to a rotation of \( \pi \) radians around the X-axis of the Bloch sphere.</p>",
                      r"<p>$$X = \begin{pmatrix} 0 & 1 \\ 1 & 0 \end{pmatrix} \Rightarrow \begin{cases} X|0\rangle = |1\rangle \\ X|1\rangle = |0\rangle \end{cases}$$</p>"
                  ),
                  _buildGateDescription(
                      r"<h2>Pauli-Y (\( Y \))</h2>",
                      r"<p>Performs a rotation of \( \pi \) radians around the Y-axis of the Bloch sphere.</p>",
                      r"<p>$$Y = \begin{pmatrix} 0 & -i \\ i & 0 \end{pmatrix} \Rightarrow \begin{cases} Y|0\rangle = i|1\rangle \\ Y|1\rangle = -i|0\rangle \end{cases}$$</p>"
                  ),
                  _buildGateDescription(
                      r"<h2>Pauli-Z (\( Z \))</h2>",
                      r"<p>Performs a rotation of \( \\pi \) radians around the Z-axis of the Bloch sphere.</p>",
                      r"<p>$$Z = \begin{pmatrix} 1 & 0 \\ 0 & -1 \end{pmatrix} \Rightarrow \begin{cases} Z|0\rangle = |0\rangle \\ Z|1\rangle = -|1\rangle \end{cases}$$</p>"
                  ),
                  // _buildGateDescription(
                  //     "Hadamard (H)",
                  //     "Creates an equal superposition of \$ |0\\rangle \$ and \$ |1\\rangle \$. Maps \$ |0\\rangle \\to \\frac{1}{\\sqrt{2}}(|0\\rangle + |1\\rangle) \$ and \$ |1\\rangle \\to \\frac{1}{\\sqrt{2}}(|0\\rangle - |1\\rangle) \$. Essential for generating superposition.",
                  //     "\\frac{1}{\\sqrt{2}}\\begin{pmatrix} 1 & 1 \\\\ 1 & -1 \\end{pmatrix}"
                  // ),
                  // _buildGateDescription(
                  //     "Phase (S or Z¹/²)",
                  //     "A Z-axis rotation by \$ \\pi/2 \$ radians. Maps \$ |0\\rangle \\to |0\\rangle \$ and \$ |1\\rangle \\to i|1\\rangle \$.",
                  //     "\\begin{pmatrix} 1 & 0 \\\\ 0 & i \\end{pmatrix}"
                  // ),
                  // _buildGateDescription(
                  //     "\\(\\pi/8\\) (T or S¹/²)",
                  //     "A Z-axis rotation by \$ \\pi/4 \$ radians. Maps \$ |0\\rangle \\to |0\\rangle \$ and \$ |1\\rangle \\to e^{i\\pi/4}|1\\rangle \$. The H and T gates are a universal set.",
                  //     "\\begin{pmatrix} 1 & 0 \\\\ 0 & e^{i\\pi/4} \\end{pmatrix}"
                  // ),
                  // _buildGateDescription(
                  //     "Rotation (R\$_k\$(\$\\theta\$))",
                  //     // Rephrased slightly to avoid \$ k \$-axis directly
                  //     "Performs a rotation around the \$k\$-axis (X, Y, or Z) of the Bloch sphere by an angle \$ \\theta \$. For \$ k=Z \$, the matrix is \$ R_z(\\theta) = \\begin{pmatrix} e^{-i\\theta/2} & 0 \\\\ 0 & e^{i\\theta/2} \\end{pmatrix} \$ (alternative common form).",
                  //     "R_z(\\theta) = \\begin{pmatrix} e^{-i\\theta/2} & 0 \\\\ 0 & e^{i\\theta/2} \\end{pmatrix}"
                  //   // Note: Rx and Ry matrices are different
                  // ),
                  // _buildGateDescription(
                  //     "Controlled-NOT (CNOT or CX)",
                  //     "A two-qubit gate. Flips the target qubit if the control qubit is in the \$ |1\\rangle \$ state. If control is \$ |0\\rangle \$, the target is unchanged. Creates entanglement between the control and target qubits.",
                  //     "\\begin{pmatrix} 1 & 0 & 0 & 0 \\\\ 0 & 1 & 0 & 0 \\\\ 0 & 0 & 0 & 1 \\\\ 0 & 0 & 1 & 0 \\end{pmatrix}"
                  // ),
                  // _buildGateDescription(
                  //     "Controlled-Z (CZ)",
                  //     "A two-qubit gate. Applies the Z gate to the target if the control is \$ |1\\rangle \$. Equivalent to adding a phase of -1 to the \$ |11\\rangle \$ state.",
                  //     "\\begin{pmatrix} 1 & 0 & 0 & 0 \\\\ 0 & 1 & 0 & 0 \\\\ 0 & 0 & 1 & 0 \\\\ 0 & 0 & 0 & -1 \\end{pmatrix}"
                  // ),
                  // _buildGateDescription(
                  //     "Controlled-U (CU)",
                  //     "A two-qubit gate. Applies an arbitrary single-qubit gate \$ U \$ to the target if the control qubit is in the \$ |1\\rangle \$ state.",
                  //     "CU = \\begin{pmatrix} I & 0 \\\\ 0 & U \\end{pmatrix}"
                  // ),
                  // _buildGateDescription(
                  //     "SWAP",
                  //     "A two-qubit gate that swaps the states of two qubits. Maps \$ |01\\rangle \\to |10\\rangle \$ and \$ |10\\rangle \\to |01\\rangle \$, leaving \$ |00\\rangle \$ and \$ |11\\rangle \$ unchanged.",
                  //     "\\begin{pmatrix} 1 & 0 & 0 & 0 \\\\ 0 & 0 & 1 & 0 \\\\ 0 & 1 & 0 & 0 \\\\ 0 & 0 & 0 & 1 \\end{pmatrix}"
                  // ),
                  // _buildGateDescription(
                  //     "Toffoli (CCNOT or CCX)",
                  //     "A three-qubit gate. Flips the target qubit if and only if both control qubits are in the \$ |1\\rangle \$ state. A universal classical gate from which any classical circuit can be built.",
                  //     // 8x8 matrix representation is large, showing block form
                  //     "\\begin{pmatrix} I_6 & 0 \\\\ 0 & X \\end{pmatrix}"
                  // ),
                  // _buildGateDescription(
                  //     "Fredkin (CSWAP)",
                  //     "A three-qubit gate. Swaps the two target qubits if the control qubit is in the \$ |1\\rangle \$ state. It is a universal classical computation gate and is also known as the controlled-SWAP.",
                  //     // 8x8 matrix representation is large, showing block form
                  //     "\\begin{pmatrix} I_6 & 0 \\\\ 0 & SWAP \\end{pmatrix}"
                  // ),
                  // Add other gates here
                ]),
                  // style: const TeXViewStyle(
                  //   margin: TeXViewMargin.all(10),
                  //   elevation: 10,
                  //   borderRadius: TeXViewBorderRadius.all(25),
                  //   border: TeXViewBorder.all(
                  //     TeXViewBorderDecoration(
                  //         borderColor: Colors.blue,
                  //         borderStyle: TeXViewBorderStyle.solid,
                  //         borderWidth: 5),
                  //   ),
                  //   backgroundColor: Colors.white,
                  // ),
                ),
            ),
              ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  TeXViewInkWell _buildGateDescription(String name, String description, String matrixLatex) {
    return TeXViewInkWell(
                id: r"id_0",
                child: TeXViewColumn(children: [
                  TeXViewDocument(
                    name,
                    style: const TeXViewStyle(
                        padding: TeXViewPadding.all(10),
                        // borderRadius: TeXViewBorderRadius.all(10),
                        textAlign: TeXViewTextAlign.center,
                        // width: 250,
                        margin: TeXViewMargin.zeroAuto(),
                        backgroundColor: Colors.green),
                  ),
                  TeXViewDocument(description, style: const TeXViewStyle(margin: TeXViewMargin.only(top: 10))),
                  TeXViewDocument(matrixLatex, style: const TeXViewStyle(margin: TeXViewMargin.only(top:10, bottom: 10))),
                  ]
                ),
            );
          // ),

          // Text(
          //   name,
          //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          // ),
          // SizedBox(height: 4),
          // // Use Math.tex for the description to render inline math
          // // Ensure the description string correctly uses \$ ... \$ for inline math
          // Math.tex(
          //   description,
          //   textStyle: TextStyle(fontSize: 14),
          //   mathStyle: MathStyle.text,
          //   textScaleFactor: 1.0,
          //   // Remove this line if errorBuilder is not defined:
          //   // errorBuilder: (context, error, formula) { ... },
          // ),
          // SizedBox(height: 8),
          // Text(
          //   "Matrix:",
          //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          // ),
          // SizedBox(height: 4),
          // // Use Math.tex for the matrix rendering
          // Math.tex(
          //   matrixLatex,
          //   mathStyle: MathStyle.display,
          //   textScaleFactor: 1.0,
          //   // Remove this line if errorBuilder is not defined:
          //   // errorBuilder: (context, error, formula) { ... },
          // ),
          // Divider(height: 16), // Add a separator
  }

  // Helper to format the overall matrix for display
  String formatMatrix(List<List<Complex>> matrix) {
    String formatted = "";
    for (int i = 0; i < 4; i++) {
      formatted += "[";
      for (int j = 0; j < 4; j++) {
        // Format complex number (e.g., "1.00+0.00i" or "0.71-0.71i")
        String real = matrix[i][j].real.toStringAsFixed(2);
        String imag = matrix[i][j].imaginary.toStringAsFixed(2);
        String complexStr;
        if (matrix[i][j].imaginary == 0) {
          complexStr = real;
        } else if (matrix[i][j].real == 0) {
          complexStr = "${imag}i";
        } else if (matrix[i][j].imaginary > 0) {
          complexStr = "$real+$imag" + "i";
        } else {
          complexStr = "$real$imag" + "i"; // Imaginary part already has '-'
        }

        formatted += complexStr;
        if (j < 3) {
          formatted += ", ";
        }
      }
      formatted += "]\n"; // New line for each row
    }
    return formatted;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Modify the AppBar
      appBar: AppBar(
        title: Text("2-Qubit Composer (Landscape)"),
        // ** Add the actions list here **
        actions: [
          // Info Button (as TextButton.icon)
          TextButton.icon(
            onPressed: _showGateListDialog,
            icon: Icon(Icons.info_outline),
            label: Text('Info'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black, // White icon/text color for contrast on AppBar
              // You might adjust padding if needed to fit
              // padding: EdgeInsets.symmetric(horizontal: 8.0),
            ),
          ),
          // Run Simulation Button (as TextButton)
          TextButton.icon(
            onPressed: _runSimulation,
            icon: Icon(Icons.play_arrow),
            label: Text('Run'), // Shorten text for AppBar
            style: TextButton.styleFrom(
              foregroundColor: Colors.black, // White text color
            ),
          ),
          // Clear Circuit Button (as TextButton)
          TextButton.icon(
            onPressed: _clearCircuit,
            icon: Icon(Icons.cleaning_services),
            label: Text('Clear'), // Shorten text for AppBar
            style: TextButton.styleFrom(
              foregroundColor: Colors.black, // White text color
            ),
          ),
        ],
        // ****************************
      ),
      body: Column( // Main Column stacking the top section and controls
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded( // This Expanded makes the Row take available vertical space
            child: Row( // <-- Main Row for Circuit and Histogram side-by-side
              children: [
                // Circuit Visualization (Left - 70% width)
                Expanded(
                  flex: 7, // Allocate 70% of the Row's width
                  child: Container( // Optional: Add container for visual separation/padding
                    padding: EdgeInsets.all(8.0),
                    child: SingleChildScrollView( // Horizontal scroll for the circuit drawing
                      scrollDirection: Axis.horizontal,
                      child: GestureDetector( // Tap detection for placing gates
                        key: _gestureDetectorKey,
                        onTapDown: _handleCircuitTap,
                        child: SizedBox( // Size the CustomPaint area
                          width: circuit.gates.length * QuantumCircuitPainter.gateSpacing + QuantumCircuitPainter.padding * 2 + QuantumCircuitPainter.gateSpacing * 2, // Dynamic width based on gates
                          height: double.infinity, // Take available height in the Expanded
                          child: CustomPaint(
                            painter: QuantumCircuitPainter(circuit),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Add VerticalDivider here
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 0,
                  endIndent: 0,
                  color: Colors.grey,
                ),

                // Histogram Visualization (Right - 30% width)
                Expanded(
                  flex: 3,
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                            simulationResult,
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gridLinesFontColor),
                          ),
                    ),
                    Divider(),
                    SizedBox(height: 16.0),
                    Container(
                      padding: EdgeInsets.all(8.0),
                      // The histogram content itself is scrollable inside _buildProbabilityHistogram if needed
                      child: SingleChildScrollView( // Scroll the whole histogram section if needed
                        scrollDirection: Axis.vertical,
                        child: AspectRatio(
                          aspectRatio: 2.0,
                          child: ProbabilityHistogram(probabilities: measurementProbabilities),
                        ), // Your histogram helper
                      ),
                    ),
                    // State Vector Display (Below buttons)
                  ]),
                ),
              ],
            ),
          ),

          // Controls Section (Below the Row)

          // Add Gates Buttons (This section remains)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add Gates:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                // SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // ... (Your existing gate buttons like H, CNOT) ...
                      ElevatedButton(
                        onPressed: () => _selectGateForPlacement(SelectedGateType.hadamard),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize),
                          padding: EdgeInsets.zero,
                          backgroundColor: QuantumCircuitPainter.hadamardColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(0.0),),
                        ),
                        child: Text('H', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                      ),
                      // SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () => _selectGateForPlacement(SelectedGateType.cnot),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize),
                          padding: EdgeInsets.zero,
                          backgroundColor: QuantumCircuitPainter.cnotColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(0.0),),
                        ),
                        child: Text('CNOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),),
                      ),
                      // Info button was moved to AppBar
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}