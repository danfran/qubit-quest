import 'package:flutter_tex/flutter_tex.dart';
import 'package:quantumquiz/quantum_circuit.dart';
import 'package:quantumquiz/quantum_circuit_painter.dart';
import 'package:quantumquiz/quantum_gate.dart';
import 'package:flutter/material.dart';

class QuantumComposer extends StatefulWidget {
  @override
  _QuantumComposerState createState() => _QuantumComposerState();
}

class _QuantumComposerState extends State<QuantumComposer> {
  final QuantumCircuit circuit = QuantumCircuit();
  String simulationResult = "Run the circuit to see the result";
  SelectedGateType _selectedGateType = SelectedGateType.none;
  int? _cnotControlQubit; // To track the first tap for CNOT


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

  void _runSimulation() {
    circuit.run();
    setState(() {
      simulationResult = "State Vector: ${circuit.currentState.toString()}";
    });
    print('Running simulation.'); // Debug simulation run
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
          title: Text("Quantum Gates List"),
          content: Container( // Wrap content in Container for size constraints if needed
            width: double.maxFinite, // Allow content to take max width available in dialog
            child: SingleChildScrollView( // Add scrolling for the content
              child: ListBody( // Use ListBody to arrange children in a vertical column
                children: <Widget>[
                  _buildGateDescription(
                      r"<h2>Pauli-X (\( X \))</h2>",
                      r"<p>Performs a bit flip, equivalent to a rotation of \( \pi \) radians around the X-axis of the Bloch sphere. Maps \( |0\rangle \) to \( |1\rangle \) and \( |1\rangle \) to \( |0\rangle \).</p>",
                      r"<p>$$ X = \begin{pmatrix} 0 & 1 \\ 1 & 0 \end{pmatrix} $$</p>"
                  ),
                  // _buildGateDescription(
                  //     "Pauli-Y (Y)",
                  //     "Performs a rotation of \$ \\pi \$ radians around the Y-axis of the Bloch sphere. Maps \$ |0\\rangle \\to i|1\\rangle \$ and \$ |1\\rangle \\to -i|0\\rangle \$.",
                  //     "\\begin{pmatrix} 0 & -i \\\\ i & 0 \\end{pmatrix}"
                  // ),
                  // _buildGateDescription(
                  //     "Pauli-Z (Z)",
                  //     "Performs a rotation of \$ \\pi \$ radians around the Z-axis of the Bloch sphere. Maps \$ |0\\rangle \\to |0\\rangle \$ and \$ |1\\rangle \\to -|1\\rangle \$. Introduces a phase difference.",
                  //     "\\begin{pmatrix} 1 & 0 \\\\ 0 & -1 \\end{pmatrix}"
                  // ),
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
                ],
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

  Widget _buildGateDescription(String name, String description, String matrixLatex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TeXView(
            child: TeXViewInkWell(
                id: r"id_0",
                child: TeXViewColumn(children: [
                  TeXViewDocument(name),
                  TeXViewDocument(description),
                  TeXViewDocument(matrixLatex),
                  ]
                ),
            )
          ),

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
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("2-Qubit Composer (Landscape)"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: GestureDetector(
                key: _gestureDetectorKey,
                onTapDown: _handleCircuitTap,
                child: SizedBox(
                  width: circuit.gates.length * QuantumCircuitPainter.gateSpacing + QuantumCircuitPainter.padding * 2 + QuantumCircuitPainter.gateSpacing * 2,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: QuantumCircuitPainter(circuit),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Add Gates:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Styled Hadamard Button
                      ElevatedButton(
                        onPressed: () => _selectGateForPlacement(SelectedGateType.hadamard),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize), // Make it square
                          padding: EdgeInsets.zero, // Remove default padding
                          backgroundColor: Colors.blue[700], // Darker blue like IBM Composer for Clifford gates
                          foregroundColor: Colors.white, // White text
                          shape: RoundedRectangleBorder( // Optional: make it slightly rounded
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        child: Text(
                          'H',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Styled CNOT Button
                      ElevatedButton(
                        onPressed: () => _selectGateForPlacement(SelectedGateType.cnot),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize), // Make it square
                          padding: EdgeInsets.zero, // Remove default padding
                          backgroundColor: Colors.blue[700], // Darker blue for Clifford gates
                          foregroundColor: Colors.white, // White text
                          shape: RoundedRectangleBorder( // Optional: make it slightly rounded
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        child: Text(
                          'CNOT', // Or just 'C' or a symbol if you prefer
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // Adjust font size for CNOT
                        ),
                      ),
                      // Add styled buttons for other gates here
                      // Example: Pauli-X (Often green in composers)
                      // SizedBox(width: 8),
                      // ElevatedButton(
                      //   onPressed: () => _selectGateForPlacement(SelectedGateType.pauliX),
                      //   style: ElevatedButton.styleFrom(
                      //      minimumSize: Size(QuantumCircuitPainter.gateSize, QuantumCircuitPainter.gateSize),
                      //      padding: EdgeInsets.zero,
                      //      backgroundColor: Colors.green[700], // Green for Pauli gates
                      //      foregroundColor: Colors.white,
                      //       shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(4.0),
                      //     ),
                      //   ),
                      //   child: Text(
                      //     'X',
                      //     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      //   ),
                      // ),
                      ElevatedButton.icon(
                        onPressed: _showGateListDialog,
                        icon: Icon(Icons.info_outline),
                        label: Text('Info'),
                        style: ElevatedButton.styleFrom(
                          // You can style this button differently if you like
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _runSimulation,
                  child: Text('Run Simulation'),
                ),
                ElevatedButton(
                  onPressed: _clearCircuit,
                  child: Text('Clear Circuit'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(simulationResult),
          ),
        ],
      ),
    );
  }
}