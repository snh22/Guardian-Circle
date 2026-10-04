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
      prefixIcon:
          icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF1F3A5F),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F3A5F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conditionCheckbox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      contentPadding: EdgeInsets.zero,
      controlAffinity:
          ListTileControlAffinity.leading,
    );
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elderly Profile'),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    // ==================================================
                    // BASIC INFORMATION
                    // ==================================================

                    _sectionTitle(
                      'Basic Information',
                      Icons.person_outline,
                    ),

                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        'Name',
                        hint: 'Enter full name',
                        icon:
                            Icons.person_outline,
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

                    TextFormField(
                      controller: _ageController,
                      keyboardType:
                          TextInputType.number,
                      decoration: _inputDecoration(
                        'Age',
                        hint: 'Enter age',
                        icon:
                            Icons.cake_outlined,
                      ),
                    ),

                    const SizedBox(height: 12),

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
                          _selectedGender =
                              value;
                        });
                      },
                    ),

                    // ==================================================
                    // MEDICAL INFORMATION
                    // ==================================================

                    _sectionTitle(
                      'Medical Information',
                      Icons
                          .medical_information_outlined,
                    ),

                    TextFormField(
                      controller:
                          _medicalConditionsController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        'Medical Conditions',
                        hint:
                            'Enter general medical information',
                        icon: Icons
                            .health_and_safety_outlined,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _conditionCheckbox(
                      'Alzheimer\'s / Dementia',
                      _alzheimer,
                      (value) {
                        setState(() {
                          _alzheimer =
                              value ?? false;
                        });
                      },
                    ),

                    _conditionCheckbox(
                      'Diabetes',
                      _diabetes,
                      (value) {
                        setState(() {
                          _diabetes =
                              value ?? false;
                        });
                      },
                    ),

                    _conditionCheckbox(
                      'Hypertension',
                      _hypertension,
                      (value) {
                        setState(() {
                          _hypertension =
                              value ?? false;
                        });
                      },
                    ),

                    _conditionCheckbox(
                      'Arthritis',
                      _arthritis,
                      (value) {
                        setState(() {
                          _arthritis =
                              value ?? false;
                        });
                      },
                    ),

                    TextFormField(
                      controller:
                          _otherConditionController,
                      decoration: _inputDecoration(
                        'Other',
                        hint:
                            'Other medical condition',
                        icon: Icons
                            .add_circle_outline,
                      ),
                    ),

                    // ==================================================
                    // MEDICATION
                    // ==================================================

                    _sectionTitle(
                      'Medication',
                      Icons.medication_outlined,
                    ),

                    TextFormField(
                      controller:
                          _medicinesController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        'Current Medicines',
                        hint:
                            'Enter medicines and dosage details',
                        icon:
                            Icons.medication_outlined,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller:
                          _medicationNotesController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        'Important Medication Notes',
                        hint:
                            'Enter important medication instructions',
                        icon:
                            Icons.notes_outlined,
                      ),
                    ),

                    // ==================================================
                    // EMERGENCY
                    // ==================================================

                    _sectionTitle(
                      'Emergency Information',
                      Icons.emergency_outlined,
                    ),

                    TextFormField(
                      controller:
                          _emergencyContactController,
                      keyboardType:
                          TextInputType.phone,
                      decoration: _inputDecoration(
                        'Emergency Contact',
                        hint:
                            'Enter emergency contact number',
                        icon:
                            Icons.phone_outlined,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller:
                          _doctorController,
                      decoration: _inputDecoration(
                        'Doctor',
                        hint:
                            'Enter doctor name',
                        icon: Icons
                            .local_hospital_outlined,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller:
                          _doctorContactController,
                      keyboardType:
                          TextInputType.phone,
                      decoration: _inputDecoration(
                        'Doctor Contact',
                        hint:
                            'Enter doctor contact number',
                        icon:
                            Icons.phone_outlined,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller:
                          _allergiesController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'Allergies',
                        hint:
                            'Enter known allergies',
                        icon: Icons
                            .warning_amber_outlined,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller:
                          _importantInstructionsController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Important Instructions',
                        hint:
                            'Enter important care instructions',
                        icon:
                            Icons.info_outline,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // SAVE BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isSaving
                                ? null
                                : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.save_outlined,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Save Profile',
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}