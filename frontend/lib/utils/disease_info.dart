import 'package:flutter/material.dart';

class DiseaseInfo {
  final String name;
  final String description;
  final String details;
  final String severity;
  final Color color;

  const DiseaseInfo({
    required this.name,
    required this.description,
    required this.details,
    required this.severity,
    required this.color,
  });
}

const Map<String, DiseaseInfo> diseaseDatabase = {
  'glioma': DiseaseInfo(
    name: 'Glioma',
    description:
        'Glioma is a type of tumor that originates in the glial cells of the brain or spinal cord.',
    details:
        'Gliomas account for about 33% of all brain tumors. On MRI, they appear as irregular, heterogeneous masses with contrast enhancement and surrounding edema.',
    severity: 'Low-grade (slow) to high-grade (aggressive, e.g. glioblastoma)',
    color: Colors.red,
  ),
  'meningioma': DiseaseInfo(
    name: 'Meningioma',
    description:
        'Meningioma is a tumor arising from the meninges — membranes surrounding the brain and spinal cord. Usually benign.',
    details:
        'Most common primary brain tumor (~30%). On MRI: well-defined, homogeneously enhancing extra-axial mass with a "dural tail" sign. Compresses rather than infiltrates brain tissue.',
    severity: 'Mostly benign (WHO Grade I); atypical/malignant variants exist',
    color: Colors.orange,
  ),
  'pituitary': DiseaseInfo(
    name: 'Pituitary Tumor',
    description:
        'Pituitary adenomas are abnormal growths in the pituitary gland at the base of the brain.',
    details:
        'Account for 10-15% of intracranial tumors. Microadenomas (<10mm) appear as hypointense areas within the gland; macroadenomas (>10mm) can compress the optic chiasm.',
    severity: 'Usually benign; may cause hormonal dysfunction or vision problems',
    color: Colors.purple,
  ),
  'notumor': DiseaseInfo(
    name: 'No Tumor Detected',
    description:
        'The MRI scan analysis did not detect any tumor formations in the brain tissue.',
    details:
        'Brain structures appear normal. No characteristic patterns of glioma, meningioma, or pituitary tumors were found. Always confirm with a specialist.',
    severity: 'No tumor pathology detected',
    color: Colors.green,
  ),
  'astrocytoma': DiseaseInfo(
    name: 'Astrocytoma',
    description:
        'A type of glioma that arises from star-shaped glial cells (astrocytes) in the brain.',
    details:
        'Can range from low-grade (pilocytic) to high-grade (anaplastic). Low-grade astrocytomas grow slowly; high-grade variants are more aggressive.',
    severity: 'WHO Grade I-IV depending on type',
    color: Colors.redAccent,
  ),
  'oligodendroglioma': DiseaseInfo(
    name: 'Oligodendroglioma',
    description:
        'A rare tumor arising from oligodendrocytes, the cells that produce myelin in the brain.',
    details:
        'Often found in the frontal or temporal lobes. Characterized by calcifications and a "fried egg" cell appearance on histology.',
    severity: 'WHO Grade II-III; generally better prognosis than astrocytomas',
    color: Color(0xFFE65100),
  ),
  'ependymoma': DiseaseInfo(
    name: 'Ependymoma',
    description:
        'A tumor arising from ependymal cells lining the ventricles of the brain and central canal of the spinal cord.',
    details:
        'More common in children. Can cause hydrocephalus by blocking CSF flow. Typically well-circumscribed.',
    severity: 'WHO Grade I-III; prognosis depends on location and grade',
    color: Color(0xFF1565C0),
  ),
  'craniopharyngioma': DiseaseInfo(
    name: 'Craniopharyngioma',
    description:
        'A rare benign tumor near the pituitary gland that develops from embryonic tissue.',
    details:
        'Despite being benign, can cause significant problems due to proximity to critical structures (optic nerves, hypothalamus, pituitary).',
    severity: 'Benign but locally aggressive; can recur after surgery',
    color: Color(0xFF00838F),
  ),
  'medulloblastoma': DiseaseInfo(
    name: 'Medulloblastoma',
    description:
        'A highly malignant primary brain tumor originating in the cerebellum (posterior fossa).',
    details:
        'Most common malignant brain tumor in children. Fast-growing, can spread through cerebrospinal fluid.',
    severity: 'WHO Grade IV; aggressive but treatable',
    color: Color(0xFFC62828),
  ),
  'schwannoma': DiseaseInfo(
    name: 'Schwannoma',
    description:
        'A benign tumor of the nerve sheath (Schwann cells), most commonly affecting the vestibular nerve (acoustic neuroma).',
    details:
        'Slow-growing, usually well-encapsulated. Vestibular schwannomas can cause hearing loss, tinnitus, and balance problems.',
    severity: 'Almost always benign (WHO Grade I)',
    color: Color(0xFF6A1B9A),
  ),
  'lymphoma': DiseaseInfo(
    name: 'CNS Lymphoma',
    description:
        'A rare, aggressive form of non-Hodgkin lymphoma confined to the central nervous system.',
    details:
        'Appears as homogeneously enhancing periventricular lesions on MRI. More common in immunocompromised patients.',
    severity: 'Aggressive; treated with chemotherapy and radiation',
    color: Color(0xFF4E342E),
  ),
  'hemangioblastoma': DiseaseInfo(
    name: 'Hemangioblastoma',
    description:
        'A benign, highly vascular tumor most commonly found in the cerebellum and spinal cord.',
    details:
        'Can be sporadic or associated with Von Hippel-Lindau disease. Characterized by a cyst with a mural nodule on imaging.',
    severity: 'Benign (WHO Grade I); surgical cure is possible',
    color: Color(0xFFAD1457),
  ),
  'metastatic': DiseaseInfo(
    name: 'Metastatic Brain Tumor',
    description:
        'Tumors that have spread to the brain from cancer elsewhere in the body (lung, breast, melanoma, etc.).',
    details:
        'Most common type of brain tumor in adults. Can be single or multiple. Located at the gray-white matter junction.',
    severity: 'Depends on primary cancer; generally serious prognosis',
    color: Color(0xFF37474F),
  ),
};

List<String> get allDiseaseKeys => diseaseDatabase.keys.toList();

Color getDiseaseColor(String disease) {
  final d = disease.toLowerCase();
  for (final entry in diseaseDatabase.entries) {
    if (d.contains(entry.key)) return entry.value.color;
  }
  if (d.isEmpty || d == 'not specified') return Colors.grey;
  return Colors.blue;
}

DiseaseInfo? getDiseaseInfo(String disease) {
  final d = disease.toLowerCase();
  for (final entry in diseaseDatabase.entries) {
    if (d.contains(entry.key)) return entry.value;
  }
  return null;
}
