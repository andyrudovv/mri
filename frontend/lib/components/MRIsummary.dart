import 'package:flutter/material.dart';


class MRIsummary extends StatelessWidget {
  const MRIsummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(13)
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          """Here’s an example of a **brain MRI summary** based on a typical scenario:
      
        ---
      
        **Brain MRI Summary:**
      
        **Patient:** [Name]
        **Date:** [Date]
        **Indication:** Headache, dizziness, or routine evaluation
      
        **Technique:** MRI of the brain was performed with T1, T2, FLAIR, DWI, and contrast-enhanced sequences.
      
        **Findings:**
      
        * **Brain parenchyma:** Normal brain volume and signal intensity. No evidence of acute infarct, hemorrhage, or mass lesion.
        * **Ventricles and CSF spaces:** Normal in size and configuration. No hydrocephalus or abnormal CSF collections.
        * **Gray-white matter differentiation:** Preserved. No abnormal signal changes.
        * **Cerebellum and brainstem:** Appears normal. No lesions identified.
        * **Sinuses:** Clear. No significant sinus disease.
        * **Vascular structures:** No flow void abnormalities. Major intracranial vessels appear patent.
        * **Other findings:** No extra-axial fluid collections. No abnormal enhancement after contrast.
      
        **Impression:**
      
        * Normal brain MRI. No evidence of acute or chronic intracranial pathology.
      
        ---
      
        If you want, I can also generate a **more detailed “realistic” MRI summary with subtle age-related changes or common small findings** so it looks like an actual radiology report. Do you want me to do that?
        """,
          style: TextStyle(
            color: Colors.black
          ),
        ),
      ),
    );
  }
}