import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddJobPage extends StatefulWidget {
  @override
  _AddJobPageState createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _requirementControllers = [
    TextEditingController(),
  ];

  // Job fields
  String _title = '';
  String _company = '';
  String? _companyLogo;
  String _type = 'Full-time'; // Default value
  String _location = '';
  String _description = '';
  List<String> _requirements = [];
  DateTime? _postedDate;
  DateTime? _deadline;
  String? _salary;

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
    'Remote',
  ];

  Future<void> _selectDate(BuildContext context, bool isPostedDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isPostedDate) {
          _postedDate = picked;
        } else {
          _deadline = picked;
        }
      });
    }
  }

  void _addRequirementField() {
    setState(() {
      _requirementControllers.add(TextEditingController());
    });
  }

  void _removeRequirementField(int index) {
    if (_requirementControllers.length > 1) {
      setState(() {
        _requirementControllers.removeAt(index);
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Collect requirements from all text fields
      _requirements =
          _requirementControllers
              .where((controller) => controller.text.isNotEmpty)
              .map((controller) => controller.text)
              .toList();

      final newJob = {
        'title': _title,
        'company': _company,
        'companyLogo': _companyLogo,
        'type': _type,
        'location': _location,
        'description': _description,
        'requirements': _requirements,
        'postedDate': _postedDate ?? DateTime.now(),
        'deadline': _deadline,
        'salary': _salary,
      };

      try {
        // Simpan ke Firestore
        await FirebaseFirestore.instance.collection('jobs').add(newJob);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Job posted successfully!')));

        // Clear the form after submission
        _formKey.currentState!.reset();
        setState(() {
          _requirementControllers.clear();
          _requirementControllers.add(TextEditingController());
          _postedDate = null;
          _deadline = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post job: $e')));
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _requirementControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Lowongan Kerja'),
        actions: [
          IconButton(icon: Icon(Icons.save_rounded), onPressed: _submitForm),
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(
                        label: 'Nama Lowongan Kerja*',
                        onSaved: (val) => _title = val!,
                        validator: _requiredValidator,
                      ),
                      SizedBox(height: 12),
                      _buildTextField(
                        label: 'Nama Perusahaan*',
                        onSaved: (val) => _company = val!,
                        validator: _requiredValidator,
                      ),
                      SizedBox(height: 12),
                      _buildTextField(
                        label: 'Logo Perusahaan (URL)',
                        onSaved:
                            (val) =>
                                _companyLogo =
                                    val?.trim().isEmpty ?? true ? null : val,
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Tipe Pekerjaan*'),
                        value: _type,
                        items:
                            _jobTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                        onChanged: (val) => setState(() => _type = val!),
                      ),
                      SizedBox(height: 12),
                      _buildTextField(
                        label: 'Lokasi*',
                        onSaved: (val) => _location = val!,
                        validator: _requiredValidator,
                      ),
                      SizedBox(height: 12),
                      _buildTextField(
                        label: 'Deskripsi*',
                        onSaved: (val) => _description = val!,
                        validator: _requiredValidator,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Persyaratan', style: theme.textTheme.titleMedium),
                      SizedBox(height: 12),
                      ..._requirementControllers.asMap().entries.map((entry) {
                        int i = entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: entry.value,
                                  decoration: _inputDecoration(
                                    'Persyaratan ${i + 1}',
                                  ),
                                  validator: (val) {
                                    if (i == 0 &&
                                        (val == null || val.isEmpty)) {
                                      return 'Setidaknya satu persyaratan dibutuhkan';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeRequirementField(i),
                              ),
                            ],
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _addRequirementField,
                          icon: Icon(Icons.add),
                          label: Text("Tambah"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDateTile(
                        context,
                        label:
                            _postedDate == null
                                ? 'Pilih Tanggal Posting (optional)'
                                : 'Posted: ${DateFormat.yMMMd().format(_postedDate!)}',
                        onTap: () => _selectDate(context, true),
                      ),
                      Divider(),
                      _buildDateTile(
                        context,
                        label:
                            _deadline == null
                                ? 'Pilih Tanggal Deadline*'
                                : 'Deadline: ${DateFormat.yMMMd().format(_deadline!)}',
                        onTap: () => _selectDate(context, false),
                      ),
                      if (_deadline == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tolong pilih tanggal deadline',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                      _buildTextField(
                        label: 'Gaji (optional)',
                        prefixText: '\$',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onSaved: (val) => _salary = val,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: Icon(Icons.send_rounded, color: Colors.white),
                  label: Text('Post', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  String? _requiredValidator(String? val) {
    return (val == null || val.trim().isEmpty)
        ? 'This field is required'
        : null;
  }

  Widget _buildTextField({
    required String label,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      decoration: _inputDecoration(label, prefixText: prefixText),
      maxLines: maxLines,
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }

  Widget _buildDateTile(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0),
      title: Text(label),
      trailing: Icon(Icons.calendar_month_outlined, color: Colors.grey[600]),
      onTap: onTap,
    );
  }
}
