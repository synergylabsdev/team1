import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/permissions_service.dart';
import '../../widgets/terms_and_conditions_dialog.dart';
import '../../widgets/age_verification_dialog.dart';

class ProfileEditScreen extends StatefulWidget {
  final bool isOnboarding;
  
  const ProfileEditScreen({
    super.key,
    this.isOnboarding = false,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  DateTime? _selectedDate;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _verifiedAge = false;
  bool _locationPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  String? _zipCode;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkPermissions();
  }

  void _loadUserData() {
    final user = AuthService().currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _usernameController.text = user.username;
      _selectedDate = user.dob;
      _acceptedTerms = true; // Already accepted if editing
      _verifiedAge = true; // Already verified if editing
    } else {
      final authUser = SupabaseService.currentUser;
      if (authUser != null) {
        _emailController.text = authUser.email ?? '';
      }
    }
  }

  Future<void> _checkPermissions() async {
    final locationGranted = await PermissionsService.checkLocationPermission();
    final notificationGranted = await PermissionsService.checkNotificationPermission();
    
    setState(() {
      _locationPermissionGranted = locationGranted;
      _notificationPermissionGranted = notificationGranted;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final granted = await PermissionsService.requestLocationPermission();
    setState(() {
      _locationPermissionGranted = granted;
    });
    
    if (!granted && mounted) {
      _showZipCodeDialog();
    }
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await PermissionsService.requestNotificationPermission();
    setState(() {
      _notificationPermissionGranted = granted;
    });
    
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission denied. You can enable it in Settings.'),
        ),
      );
    }
  }

  void _showZipCodeDialog() {
    final zipController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter ZIP Code'),
        content: TextField(
          controller: zipController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'ZIP Code',
            hintText: 'Enter your ZIP code',
          ),
          maxLength: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (zipController.text.length == 5) {
                setState(() {
                  _zipCode = zipController.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TermsAndConditionsDialog(
        onAccept: () {
          setState(() {
            _acceptedTerms = true;
          });
          Navigator.pop(context);
        },
        onDecline: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAgeVerificationDialog() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth first'),
        ),
      );
      return;
    }

    final age = DateTime.now().difference(_selectedDate!).inDays ~/ 365;
    if (age < 21) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be 21 or older to verify age'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AgeVerificationDialog(
        onVerified: () {
          setState(() {
            _verifiedAge = true;
          });
          Navigator.pop(context);
        },
        onDeclined: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept Terms & Conditions'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Check if age verification is needed (if accessing 21+ categories)
    if (_selectedDate != null) {
      final age = DateTime.now().difference(_selectedDate!).inDays ~/ 365;
      if (age >= 21 && !_verifiedAge) {
        _showAgeVerificationDialog();
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().updateUserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        dob: _selectedDate,
      );

      // Reload user profile to get updated data
      await AuthService().loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        if (widget.isOnboarding) {
          // Navigate to home if onboarding
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboarding ? 'Complete Your Profile' : 'Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // First Name
              TextFormField(
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Last Name
              TextFormField(
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: widget.isOnboarding, // Can't change email after signup
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!EmailValidator.validate(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '(123) 456-7890',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Date of Birth
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth (MM/DD/YYYY) *',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    suffixIcon: _selectedDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                              });
                            },
                          )
                        : null,
                  ),
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('MM/dd/yyyy').format(_selectedDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _selectedDate != null
                          ? AppTheme.textPrimary
                          : AppTheme.textTertiary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              if (_selectedDate != null)
                Text(
                  'Age: ${DateTime.now().difference(_selectedDate!).inDays ~/ 365} years',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              
              const SizedBox(height: 16),
              
              // Username
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < AppConstants.minUsernameLength) {
                    return 'Username must be at least ${AppConstants.minUsernameLength} characters';
                  }
                  if (value.length > AppConstants.maxUsernameLength) {
                    return 'Username must be at most ${AppConstants.maxUsernameLength} characters';
                  }
                  return null;
                },
              ),
              
              if (widget.isOnboarding) ...[
                const SizedBox(height: 16),
                
                // Password (only during onboarding)
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < AppConstants.minPasswordLength) {
                      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Terms & Conditions
              Card(
                color: _acceptedTerms
                    ? AppTheme.successColor.withOpacity(0.1)
                    : null,
                child: CheckboxListTile(
                  title: const Text('I accept the Terms & Conditions'),
                  value: _acceptedTerms,
                  onChanged: (value) {
                    if (value == true) {
                      _showTermsDialog();
                    } else {
                      setState(() {
                        _acceptedTerms = false;
                      });
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: TextButton(
                    onPressed: _showTermsDialog,
                    child: const Text('View Terms'),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Age Verification (if 21+)
              if (_selectedDate != null &&
                  DateTime.now().difference(_selectedDate!).inDays ~/ 365 >= 21)
                Card(
                  color: _verifiedAge
                      ? AppTheme.successColor.withOpacity(0.1)
                      : null,
                  child: CheckboxListTile(
                    title: const Text('I confirm I am 21 years or older'),
                    subtitle: const Text('Required for age-restricted categories'),
                    value: _verifiedAge,
                    onChanged: (value) {
                      if (value == true) {
                        _showAgeVerificationDialog();
                      } else {
                        setState(() {
                          _verifiedAge = false;
                        });
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Permissions Section
              _buildSectionHeader('Permissions'),
              
              // Location Permission
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                  title: const Text('Location Access'),
                  subtitle: Text(
                    _locationPermissionGranted
                        ? 'Location access granted'
                        : _zipCode != null
                            ? 'Using ZIP code: $_zipCode'
                            : 'Required for event discovery',
                  ),
                  trailing: _locationPermissionGranted
                      ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                      : ElevatedButton(
                          onPressed: _requestLocationPermission,
                          child: const Text('Enable'),
                        ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Notification Permission
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications, color: AppTheme.primaryColor),
                  title: const Text('Push Notifications'),
                  subtitle: const Text(
                    'For event reminders, check-ins, and rewards',
                  ),
                  trailing: _notificationPermissionGranted
                      ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                      : ElevatedButton(
                          onPressed: _requestNotificationPermission,
                          child: const Text('Enable'),
                        ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(widget.isOnboarding ? 'Complete Profile' : 'Save Changes'),
              ),
              
              if (widget.isOnboarding) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // "Didn't get a code?" - redirect to support
                    // For now, show a dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Need Help?'),
                        content: const Text(
                          'If you didn\'t receive a verification code, please contact support.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Open support page
                              Navigator.pop(context);
                              // TODO: Open support URL
                            },
                            child: const Text('Contact Support'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Didn\'t get a code? Contact Support'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

