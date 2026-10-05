import 'package:flutter/material.dart';

import '../../../../core/network/api_service.dart';

class ElderlyProfileScreen extends StatefulWidget {
  const ElderlyProfileScreen({super.key});

  @override
  State<ElderlyProfileScreen> createState() =>
      _ElderlyProfileScreenState();
}

class _ElderlyProfileScreenState
    extends State<ElderlyProfileScreen> {
  // ==================================================
  // ELDERLY USER
  // ==================================================

  // Backend database:
  // user_id = 3 → Elderly Test
  static const int elderlyUserId = 3;

  // ==================================================
  // FORM
  // ==================================================

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _medicalConditionsController =
      TextEditingController();
  final _otherConditionController =
      TextEditingController();
  final _medicinesController =
      TextEditingController();
  final _medicationNotesController =
      TextEditingController();
  final _emergencyContactController =
      TextEditingController();
  final _doctorController =
      TextEditingController();
  final _doctorContactController =
      TextEditingController();
  final _allergiesController =
      TextEditingController();
  final _importantInstructionsController =
      TextEditingController();

  String? _selectedGender;

  bool _alzheimer = false;
  bool _diabetes = false;
  bool _hypertension = false;
  bool _arthritis = false;

  // ==================================================
  // STATE
  // ==================================================

  bool _isLoading = true;
  bool _isSaving = false;

  // ==================================================
  // LIFECYCLE
  // ==================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _medicalConditionsController.dispose();
    _otherConditionController.dispose();
    _medicinesController.dispose();
    _medicationNotesController.dispose();
    _emergencyContactController.dispose();
    _doctorController.dispose();
    _doctorContactController.dispose();
    _allergiesController.dispose();
    _importantInstructionsController.dispose();
    super.dispose();
  }

  // ==================================================
  // LOAD PROFILE
  // ==================================================

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile =
          await ApiService.getElderlyProfile(
        elderlyUserId,
      );

      _populateProfile(profile);
    } catch (e) {
      // The profile should already exist because we verified:
      // profile_id=1 | user_id=3 | caretaker_id=1
      //
      // If it does not exist for some reason, try linking it.
      try {
        await ApiService.linkElderlyProfile(
          elderlyUserId,
        );

        final profile =
            await ApiService.getElderlyProfile(
          elderlyUserId,
        );

        _populateProfile(profile);
      } catch (linkError) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to load elderly profile: $linkError',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==================================================
  // POPULATE FORM
  // ==================================================

  void _populateProfile(
    Map<String, dynamic> profile,
  ) {
    _nameController.text =
        profile['full_name']?.toString() ?? '';

    _ageController.text =
        profile['age']?.toString() ?? '';

    _selectedGender =
        profile['gender']?.toString();

    _medicalConditionsController.text =
        profile['medical_conditions']?.toString() ?? '';

    _medicinesController.text =
        profile['current_medicines']?.toString() ?? '';

    _medicationNotesController.text =
        profile['medication_notes']?.toString() ?? '';

    _emergencyContactController.text =
        profile['emergency_contact']?.toString() ?? '';

    _doctorController.text =
        profile['doctor_name']?.toString() ?? '';

    _doctorContactController.text =
        profile['doctor_contact']?.toString() ?? '';

    _allergiesController.text =
        profile['allergies']?.toString() ?? '';

    _importantInstructionsController.text =
        profile['important_instructions']?.toString() ?? '';

    // The backend stores medical conditions in one TEXT field.
    // We therefore detect the checkbox conditions from that text.
    final medicalText =
        _medicalConditionsController.text.toLowerCase();

    setState(() {
      _alzheimer =
          medicalText.contains('alzheimer') ||
          medicalText.contains('dementia');

      _diabetes =
          medicalText.contains('diabetes');

      _hypertension =
          medicalText.contains('hypertension');

      _arthritis =
          medicalText.contains('arthritis');
    });
  }

  // ==================================================
  // BUILD MEDICAL CONDITIONS TEXT
  // ==================================================

  String _buildMedicalConditions() {
    final conditions = <String>[];

    if (_alzheimer) {
      conditions.add("Alzheimer's / Dementia");
    }

    if (_diabetes) {
      conditions.add('Diabetes');
    }

    if (_hypertension) {
      conditions.add('Hypertension');
    }

    if (_arthritis) {
      conditions.add('Arthritis');
    }

    final generalConditions =
        _medicalConditionsController.text.trim();

    if (generalConditions.isNotEmpty) {
      conditions.add(generalConditions);
    }

    final otherCondition =
        _otherConditionController.text.trim();

    if (otherCondition.isNotEmpty) {
      conditions.add(otherCondition);
    }

    return conditions.join(', ');
  }

  // ==================================================
  // SAVE PROFILE
  // ==================================================

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ageText =
        _ageController.text.trim();

    int? age;

    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);

      if (age == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a valid age.',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.updateElderlyProfile(
        elderlyUserId: elderlyUserId,
        data: {
          'full_name':
              _nameController.text.trim(),

          'age': age,

          'gender':
              _selectedGender,

          'medical_conditions':
              _buildMedicalConditions(),

          'current_medicines':
              _medicinesController.text.trim(),

          'medication_notes':
              _medicationNotesController.text.trim(),

          'emergency_contact':
              _emergencyContactController.text.trim(),

          'doctor_name':
              _doctorController.text.trim(),

          'doctor_contact':
              _doctorContactController.text.trim(),

          'allergies':
              _allergiesController.text.trim(),

          'important_instructions':
              _importantInstructionsController.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Elderly profile saved successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save profile: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ==================================================
  // UI HELPERS
  // ==================================================

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: const Color(0xFF24598B),
            )
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      labelStyle: const TextStyle(
        color: Color(0xFF6D7888),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFA5AFBC),
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE4EAF1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE4EAF1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF24598B),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE6EBF2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF183B60).withValues(alpha: 0.055),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF24598B),
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF183B60),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8994A3),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _conditionCheckbox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFFEAF5EF)
            : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? const Color(0xFFB9DDC8)
              : const Color(0xFFE7ECF2),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            color: value
                ? const Color(0xFF236B45)
                : const Color(0xFF354052),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        activeColor: const Color(0xFF2E8B57),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 1,
        ),
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _profileHeader() {
    final name = _nameController.text.trim().isEmpty
        ? 'Elderly Patient'
        : _nameController.text.trim();

    final age = _ageController.text.trim();
    final gender = _selectedGender;

    final details = <String>[
      if (age.isNotEmpty) '$age years',
      if (gender != null && gender.isNotEmpty) gender,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF163B68),
            Color(0xFF24598B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ELDERLY PROFILE',
                      style: TextStyle(
                        color: Color(0xFFBFD8EE),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      details.isEmpty
                          ? 'Patient information'
                          : details.join('  •  '),
                      style: const TextStyle(
                        color: Color(0xFFD8E7F5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF8FE0B0),
                  size: 17,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Profile information is used for safer patient care',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF24598B),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9AA7B5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(
          _isSaving ? 'Saving Profile...' : 'Save Profile',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF163B68),
        foregroundColor: Colors.white,
        title: const Text(
          'Elderly Profile',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF24598B),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileHeader(),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        20,
                        16,
                        32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionCard(
                            title: 'Personal Information',
                            subtitle:
                                'Basic details about the patient',
                            icon: Icons.person_outline_rounded,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: _inputDecoration(
                                  'Full Name',
                                  hint: 'Enter full name',
                                  icon: Icons.person_outline_rounded,
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Please enter name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _ageController,
                                      keyboardType:
                                          TextInputType.number,
                                      decoration: _inputDecoration(
                                        'Age',
                                        hint: 'Enter age',
                                        icon: Icons.cake_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child:
                                        DropdownButtonFormField<String>(
                                      initialValue: _selectedGender,
                                      decoration: _inputDecoration(
                                        'Gender',
                                        icon: Icons.wc_outlined,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Male',
                                          child: Text('Male'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Female',
                                          child: Text('Female'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Other',
                                          child: Text('Other'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedGender = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          _sectionCard(
                            title: 'Medical Information',
                            subtitle:
                                'Conditions and health information',
                            icon: Icons.medical_information_outlined,
                            children: [
                              TextFormField(
                                controller:
                                    _medicalConditionsController,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  'Medical Conditions',
                                  hint:
                                      'Enter general medical information',
                                  icon:
                                      Icons.health_and_safety_outlined,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Known Conditions',
                                style: TextStyle(
                                  color: Color(0xFF354052),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 9),
                              _conditionCheckbox(
                                'Alzheimer\'s / Dementia',
                                _alzheimer,
                                (value) {
                                  setState(() {
                                    _alzheimer = value ?? false;
                                  });
                                },
                              ),
                              _conditionCheckbox(
                                'Diabetes',
                                _diabetes,
                                (value) {
                                  setState(() {
                                    _diabetes = value ?? false;
                                  });
                                },
                              ),
                              _conditionCheckbox(
                                'Hypertension',
                                _hypertension,
                                (value) {
                                  setState(() {
                                    _hypertension = value ?? false;
                                  });
                                },
                              ),
                              _conditionCheckbox(
                                'Arthritis',
                                _arthritis,
                                (value) {
                                  setState(() {
                                    _arthritis = value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller:
                                    _otherConditionController,
                                decoration: _inputDecoration(
                                  'Other Condition',
                                  hint: 'Add another condition',
                                  icon: Icons.add_circle_outline_rounded,
                                ),
                              ),
                            ],
                          ),

                          _sectionCard(
                            title: 'Medication & Care',
                            subtitle:
                                'Current medicines and instructions',
                            icon: Icons.medication_outlined,
                            children: [
                              TextFormField(
                                controller: _medicinesController,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  'Current Medicines',
                                  hint:
                                      'Enter medicines and dosage details',
                                  icon: Icons.medication_outlined,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller:
                                    _medicationNotesController,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  'Medication Notes',
                                  hint:
                                      'Enter important medication instructions',
                                  icon: Icons.notes_outlined,
                                ),
                              ),
                            ],
                          ),

                          _sectionCard(
                            title: 'Emergency & Doctor Care',
                            subtitle:
                                'Contacts needed during an emergency',
                            icon: Icons.emergency_outlined,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(13),
                                margin:
                                    const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF5F2),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFF3D1C9),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.priority_high_rounded,
                                      color: Color(0xFFD9534F),
                                      size: 20,
                                    ),
                                    SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        'Keep emergency contact details up to date for quick assistance.',
                                        style: TextStyle(
                                          color: Color(0xFF7C3F39),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextFormField(
                                controller:
                                    _emergencyContactController,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                  'Emergency Contact',
                                  hint:
                                      'Enter emergency contact number',
                                  icon: Icons.phone_outlined,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _doctorController,
                                decoration: _inputDecoration(
                                  'Doctor Name',
                                  hint: 'Enter doctor name',
                                  icon:
                                      Icons.local_hospital_outlined,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller:
                                    _doctorContactController,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                  'Doctor Contact',
                                  hint:
                                      'Enter doctor contact number',
                                  icon: Icons.phone_outlined,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _allergiesController,
                                maxLines: 2,
                                decoration: _inputDecoration(
                                  'Allergies',
                                  hint: 'Enter known allergies',
                                  icon:
                                      Icons.warning_amber_outlined,
                                ),
                              ),
                            ],
                          ),

                          _sectionCard(
                            title: 'Important Care Instructions',
                            subtitle:
                                'Information the caretaker should remember',
                            icon: Icons.info_outline_rounded,
                            children: [
                              TextFormField(
                                controller:
                                    _importantInstructionsController,
                                maxLines: 5,
                                decoration: _inputDecoration(
                                  'Care Instructions',
                                  hint:
                                      'Enter important care instructions',
                                  icon: Icons.edit_note_rounded,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),
                          _saveButton(),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

}