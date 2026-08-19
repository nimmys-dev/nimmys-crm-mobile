// company_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nimmys_crm/core/theme/app_colors.dart'; // for AppColors.red
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/profile/cubit/company/company_profile_cubit.dart';
import 'package:nimmys_crm/features/profile/model/company_details_model.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  bool _isEditing = false;
  bool _isUpdating = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  File? _logoFile;
  String? _currentLogoUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CompanyProfileCubit>().getCompanyProfile();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _populateControllers(CompanyProfileData? data) {
    if (data == null) return;
    _nameController.text = data.name ?? '';
    _addressController.text = data.addressLine ?? '';
    _cityController.text = data.city ?? '';
    _stateController.text = data.state ?? '';
    _postalController.text = data.postalCode ?? '';
    _countryController.text = data.country ?? '';
    _phoneController.text = data.phone ?? '';
    _emailController.text = data.email ?? '';
    _currentLogoUrl = data.logo;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    _isUpdating = true;
    final cubit = context.read<CompanyProfileCubit>();
    cubit.updateCompanyProfile(
      name: _nameController.text.trim(),
      addressLine: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalController.text.trim(),
      country: _countryController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      logo: _logoFile,
    );
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _logoFile = null;
      final data = context
          .read<CompanyProfileCubit>()
          .state
          .companyProfileUIState
          ?.data;
      if (data != null) {
        _populateControllers(data.data);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: context.palette.surface,
          // Subtle bottom divider that adapts to light/dark
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(
              height: 0.5,
              color: context.palette.line.withOpacity(0.3),
            ),
          ),
          title: Text(
            'Company Profile',
            style: context.type.screenTitle.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: context.palette.ink, // adapts to theme
            ),
          ),
          actions: [
            if (_isEditing)
              IconButton(
                padding: const EdgeInsets.all(8),
                icon: const Icon(Icons.close_rounded, size: 24),
                color: context.palette.muted, // adapts to theme
                onPressed: _cancelEditing,
              ),
            BlocBuilder<CompanyProfileCubit, CompanyProfileState>(
              builder: (context, state) {
                final isUpdating =
                    state.companyProfileUIState?.status == Status.LOADING;
                return IconButton(
                  padding: const EdgeInsets.all(8),
                  icon: Icon(
                    _isEditing ? Icons.save_rounded : Icons.edit_rounded,
                    size: 24,
                    color:
                        AppColors.red, // brand accent, visible in both themes
                  ),
                  onPressed: isUpdating
                      ? null
                      : () {
                          if (_isEditing) {
                            _saveProfile();
                          } else {
                            final data = state.companyProfileUIState?.data;
                            if (data != null) {
                              setState(() {
                                _isEditing = true;
                                _populateControllers(data.data);
                              });
                            } else {
                              ToastMessages.error(
                                message: 'No company data to edit',
                              );
                            }
                          }
                        },
                );
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: BlocConsumer<CompanyProfileCubit, CompanyProfileState>(
          listener: (context, state) {
            final uiState = state.companyProfileUIState;
            if (uiState?.status == Status.SUCCESS) {
              if (_isEditing) {
                setState(() {
                  _isEditing = false;
                  _logoFile = null;
                });
              }
              if (_isUpdating) {
                _isUpdating = false; // reset
                ToastMessages.success(message: 'Profile updated successfully');
                // Exit edit mode after successful update
                if (_isEditing) {
                  setState(() {
                    _isEditing = false;
                    _logoFile = null;
                  });
                }
              }
            } else if (uiState?.status == Status.ERROR) {
              final error =
                  uiState?.errorType?.getText(context) ?? 'Update failed';
              ToastMessages.error(message: error);
            }
          },
          builder: (context, state) {
            final uiState = state.companyProfileUIState;

            if (uiState?.status == Status.LOADING && uiState?.data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (uiState?.status == Status.ERROR && uiState?.data == null) {
              final error =
                  uiState?.errorType?.getText(context) ??
                  'Failed to load profile';
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: context.palette.muted,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      error,
                      style: context.type.bodyMuted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPrimaryButton(
                      label: 'RETRY',
                      onPressed: () => context
                          .read<CompanyProfileCubit>()
                          .getCompanyProfile(force: true),
                    ),
                  ],
                ),
              );
            }

            final data = uiState?.data?.data;
            if (data == null) {
              return const Center(child: Text('No company data available'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: _isEditing
                  ? _buildEditForm(context, data)
                  : _buildViewMode(context, data),
            );
          },
        ),
      ),
    );
  }

  // ---------- View Mode ----------
  Widget _buildViewMode(BuildContext context, CompanyProfileData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _buildLogoDisplay(context, data.logo, size: 120)),
        const SizedBox(height: AppSpacing.lg),
        CompanyProfileDetailRow(
          icon: Icons.business,
          label: 'Name',
          value: data.name,
        ),
        CompanyProfileDetailRow(
          icon: Icons.location_on,
          label: 'Address',
          value: data.addressLine,
        ),
        CompanyProfileDetailRow(
          icon: Icons.location_city,
          label: 'City',
          value: data.city,
        ),
        CompanyProfileDetailRow(
          icon: Icons.map,
          label: 'State',
          value: data.state,
        ),
        CompanyProfileDetailRow(
          icon: Icons.pin_drop,
          label: 'Postal Code',
          value: data.postalCode,
        ),
        CompanyProfileDetailRow(
          icon: Icons.flag,
          label: 'Country',
          value: data.country,
        ),
        CompanyProfileDetailRow(
          icon: Icons.phone,
          label: 'Phone',
          value: data.phone,
        ),
        CompanyProfileDetailRow(
          icon: Icons.email,
          label: 'Email',
          value: data.email,
        ),
      ],
    );
  }

  Widget _buildLogoDisplay(
    BuildContext context,
    String? url, {
    double size = 80,
  }) {
    return ClipOval(
      child: SizedBox.fromSize(
        size: Size(size, size),
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, _, _) =>
                    Icon(Icons.business, size: size * 0.5),
              )
            : Icon(
                Icons.business,
                size: size * 0.5,
                color: context.palette.muted,
              ),
      ),
    );
  }

  // ---------- Edit Form ----------
  Widget _buildEditForm(BuildContext context, CompanyProfileData data) {
    final isUpdating =
        context
            .watch<CompanyProfileCubit>()
            .state
            .companyProfileUIState
            ?.status ==
        Status.LOADING;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                _logoFile != null
                    ? ClipOval(
                        child: Image.file(
                          _logoFile!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _buildLogoDisplay(context, data.logo, size: 120),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    // FIXED: use brand red (visible in both themes)
                    backgroundColor: AppColors.red,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickLogo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildTextField(_nameController, 'Company Name', Icons.business),
          _buildTextField(
            _addressController,
            'Address Line',
            Icons.location_on,
          ),
          _buildTextField(_cityController, 'City', Icons.location_city),
          _buildTextField(_stateController, 'State', Icons.map),
          _buildTextField(_postalController, 'Postal Code', Icons.pin_drop),
          _buildTextField(_countryController, 'Country', Icons.flag),
          _buildTextField(_phoneController, 'Phone', Icons.phone),
          _buildTextField(
            _emailController,
            'Email',
            Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: 'SAVE',
                  icon: Icons.save,
                  isLoading: isUpdating,
                  onPressed: isUpdating ? null : _saveProfile,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppOutlineButton(
                  label: 'CANCEL',
                  onPressed: isUpdating ? null : _cancelEditing,
                ),
              ),
            ],
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (label == 'Email' &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),
    );
  }
}

/// One labelled row of the company profile (view‑only).
/// Renders an em dash when the value is null, so the row stays visible.
class CompanyProfileDetailRow extends StatelessWidget {
  const CompanyProfileDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final shown = value ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: context.palette.muted),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 110,
            child: Text(label, style: context.type.bodyMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              shown.isEmpty ? '—' : shown,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.type.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
