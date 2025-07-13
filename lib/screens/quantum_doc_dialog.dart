import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
// Import SelectedGateType if it's in its own file, otherwise ignore or copy its definition
// import 'package:quantumquiz/selected_gate_type.dart';

class QuantumDocDialog extends StatelessWidget {
  const QuantumDocDialog({Key? key}) : super(key: key);

  TeXViewInkWell _buildGateDescription(String name, String description, String matrixLatex) {
    return TeXViewInkWell(
      id: r"id_0",
      child: TeXViewColumn(children: [
        TeXViewDocument(
          name,
          style: TeXViewStyle(
              padding: const TeXViewPadding.all(4),
              borderRadius: TeXViewBorderRadius.all(4),
              textAlign: TeXViewTextAlign.center,
              // width: 250,
              margin: const TeXViewMargin.zeroAuto(),
              backgroundColor: Colors.blueGrey[700],
              contentColor: Colors.white,),
        ),
        TeXViewDocument(description, style: const TeXViewStyle(margin: TeXViewMargin.only(top: 10), contentColor: Colors.white)),
        TeXViewDocument(matrixLatex, style: const TeXViewStyle(margin: TeXViewMargin.only(top:10, bottom: 10), contentColor: Colors.white)),
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
                      // borderRadius: TeXViewBorderRadius.all(10),
                      // border: TeXViewBorder.all(TeXViewBorderDecoration(
                      //     borderWidth: 1,
                      //     borderStyle: TeXViewBorderStyle.groove,
                      //     borderColor: Color(0xFF4D4D5C)))
                  ),
                  children: [
                    _buildGateDescription(
                        r"<h3>Pauli-X (\( X \))</h3>",
                        r"<p>Performs a bit flip, equivalent to a rotation of \( \pi \) radians around the X-axis of the Bloch sphere.</p>",
                        r"<p>$$X = \begin{pmatrix} 0 & 1 \\ 1 & 0 \end{pmatrix} \Rightarrow \begin{cases} X|0\rangle = |1\rangle \\ X|1\rangle = |0\rangle \end{cases}$$</p>"
                    ),
                    _buildGateDescription(
                        r"<h3>Pauli-Y (\( Y \))</h3>",
                        r"<p>Performs a rotation of \( \pi \) radians around the Y-axis of the Bloch sphere.</p>",
                        r"<p>$$Y = \begin{pmatrix} 0 & -i \\ i & 0 \end{pmatrix} \Rightarrow \begin{cases} Y|0\rangle = i|1\rangle \\ Y|1\rangle = -i|0\rangle \end{cases}$$</p>"
                    ),
                    _buildGateDescription(
                        r"<h3>Pauli-Z (\( Z \))</h3>",
                        r"<p>Performs a rotation of \( \pi \) radians around the Z-axis of the Bloch sphere.</p>",
                        r"<p>$$Z = \begin{pmatrix} 1 & 0 \\ 0 & -1 \end{pmatrix} \Rightarrow \begin{cases} Z|0\rangle = |0\rangle \\ Z|1\rangle = -|1\rangle \end{cases}$$</p>"
                    ),
                    _buildGateDescription(
                        r"<h3>Hadamard (H)</h3>",
                        r"<p>Creates an equal superposition of \( |0\rangle \) and \( |1\rangle \).</p>",
                        r"<p>$$H = \frac{1}{\sqrt{2}}\begin{pmatrix} 1 & 1 \\ 1 & -1 \end{pmatrix} \Rightarrow \begin{cases} H|0\rangle = \frac{1}{\sqrt{2}}(|0\rangle + |1\rangle) \\ H|1\rangle = \frac{1}{\sqrt{2}}(|0\rangle - |1\rangle) \end{cases}$$</p>"
                    ),
                    _buildGateDescription(
                        r"<h3>Controlled-NOT (\( CNOT \) or \( CX \))</h3>",
                        r"<p>A two-qubit gate. Flips the target qubit if the control qubit is in the \( |1\rangle \) state. If control is \( |0\rangle \), the target is unchanged. Creates entanglement between the control and target qubits.</p>",
                        r"<p>$$CNOT = \begin{pmatrix} 1 & 0 & 0 & 0 \\ 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 1 \\ 0 & 0 & 1 & 0 \end{pmatrix}\Rightarrow \begin{cases} CNOT|00\rangle = |00\rangle \\ CNOT|01\rangle = |01\rangle \\ CNOT|10\rangle = |11\rangle \\ CNOT|11\rangle = |10\rangle \end{cases}$$</p>"
                    ),
                    _buildGateDescription(
                        r"<h3>Phase S (\( Z¹/² \))</h3>",
                        r"<p>A Z-axis rotation by \( \pi / 2 \) radians. Maps \( |0\rangle \) to \( |0\rangle \) and \( |1\rangle \) to \( i|1\rangle \).</p>",
                        r"<p>$$S = \begin{pmatrix} 1 & 0 \\ 0 & i \end{pmatrix} \Rightarrow \begin{cases} S|0\rangle = |0\rangle \\ S|1\rangle = i|1\rangle \end{cases}$$</p>"
                    ),
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
          child: Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}