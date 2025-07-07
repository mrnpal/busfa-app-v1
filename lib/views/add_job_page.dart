import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busfa_app/utils/lottie_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  String _type = 'Full-time'; // Default value
  String _location = '';
  String _description = '';
  List<String> _requirements = [];
  DateTime? _postedDate;
  DateTime? _deadline;
  String? _salary;
  String? _phoneContact;
  String? _emailContact;

  final List<String> _jobTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
    'Remote',
  ];

  File? _logoFile;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadLogo(File file) async {
    try {
      final fileName =
          'jobs_images/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      _requirements =
          _requirementControllers
              .where((controller) => controller.text.isNotEmpty)
              .map((controller) => controller.text)
              .toList();

      String? logoUrl;
      if (_logoFile != null) {
        logoUrl = await _uploadLogo(_logoFile!);
      }

      final newJob = {
        'title': _title,
        'company': _company,
        'companyLogo': logoUrl,
        'type': _type,
        'location': _location,
        'description': _description,
        'requirements': _requirements,
        'postedDate': _postedDate ?? DateTime.now(),
        'deadline': _deadline,
        'salary': _salary,
        'phoneContact': _phoneContact,
        'emailContact': _emailContact,
      };

      try {
        await FirebaseFirestore.instance.collection('jobs').add(newJob);

        // Pakai showLottieToast untuk sukses
        showLottieToast(
          context: context,
          message: 'Pekerjaan berhasil di posting!',
          success: true,
        );
        Future.delayed(Duration(seconds: 3), () {
          if (mounted) Get.back();
        });

        _formKey.currentState!.reset();
        setState(() {
          _requirementControllers.clear();
          _requirementControllers.add(TextEditingController());
          _postedDate = null;
          _deadline = null;
        });
      } catch (e) {
        // Pakai showLottieToast untuk error
        showLottieToast(
          context: context,
          message: 'Gagal memposting pekerjaan: $e',

          success: false,
        );
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
        title: const Text('Tambah Lowongan Kerja'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Informasi Lowongan Kerja',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: GestureDetector(
                            onTap: _pickLogo,
                            child:
                                _logoFile != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _logoFile!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blueAccent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.add_a_photo,
                                            size: 36,
                                            color: Colors.blueAccent,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Upload Logo',
                                            style: TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildTextField(
                          label: 'Nama Lowongan Kerja*',
                          onSaved: (val) => _title = val!,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Nama Perusahaan*',
                          onSaved: (val) => _company = val!,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 14),
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
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Lokasi*',
                          onSaved: (val) => _location = val!,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 14),
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
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Persyaratan',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._requirementControllers.asMap().entries.map((entry) {
                          int i = entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
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
                                const SizedBox(width: 6),
                                if (_requirementControllers.length > 1)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _removeRequirementField(i),
                                  ),
                              ],
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: _addRequirementField,
                            icon: const Icon(
                              Icons.add,
                              color: Colors.blueAccent,
                            ),
                            label: const Text(
                              "Tambah",
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.blueAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Tanggal Posting & Deadline',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildDateTile(
                          context,
                          label:
                              _postedDate == null
                                  ? 'Pilih Tanggal Posting (optional)'
                                  : 'Posted: 	${DateFormat.yMMMd().format(_postedDate!)}',
                          onTap: () => _selectDate(context, true),
                        ),
                        const Divider(),
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
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Gaji (optional)',
                          prefixText: 'Rp ',
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
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Kontak Perusahaan',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Nomor Telpon/WA*',
                          onSaved: (val) => _phoneContact = val!,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Email*',
                          onSaved: (val) => _emailContact = val!,
                          validator: _requiredValidator,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: const Text(
                      'Post',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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
