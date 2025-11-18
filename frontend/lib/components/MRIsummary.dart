import 'package:flutter/material.dart';

class MRIsummary extends StatelessWidget {
  const MRIsummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: const Text(
            """
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)

            Here’s an example of a brain MRI summary …

            (Your long text unchanged)
            Here’s an example of a brain MRI summary …

            (Your long text unchanged)

            Here’s an example of a brain MRI summary …

            (Your long text unchanged)Here’s an example of a brain MRI summary …

            (Your long text unchanged)
""",
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
