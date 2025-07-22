import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Only need FirebaseAuth

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController(); // Will be collected but not saved by this code
  final _addressController = TextEditingController(); // Will be collected but not saved by this code
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Firebase Auth instance only
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // No Firestore instance needed

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Helper to show SnackBar ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Signup Logic (Auth Only) ---
  void _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; });

    try {
      // 1. Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? newUser = userCredential.user;
      if (newUser != null) {
        // 2. (Optional but recommended) Update Display Name in Firebase Auth profile
        // This is a best-effort update. We won't block navigation if it fails silently.
        try {
          await newUser.updateDisplayName(_nameController.text.trim());
          // Optional: Reload user data if you need immediate access to the updated name
          // await newUser.reload();
          // newUser = _auth.currentUser; // Refresh the user object
        } catch (displayNameError) {
          // Log this internally if desired, but don't show to user usually
          // logger.w("Could not update display name: $displayNameError");
          print("Warning: Could not update display name: $displayNameError"); // Using print temporarily as placeholder
        }

        // 3. Navigate to home screen on success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signup successful!'),
              backgroundColor: Colors.green,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if(mounted) {
            // Clear navigation stack and go to home
            Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
          }
        }
      } else {
        _showErrorSnackBar('User creation failed unexpectedly. Please try again.');
      }

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      String errorMessage = 'Signup failed. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      // Handle other general errors
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
      print("Signup Error: $e"); // Print for debugging unexpected errors
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- UI Code remains largely the same ---
    // The fields for Mobile and Address will still appear and be validated,
    // but their values won't be saved by the _signup function.

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color primaryColor = colorScheme.primary;
    final Color hintColor = Colors.grey;
    final Color lightFillColor = Colors.grey.shade100;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Signup Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name Field (Value used for Auth Display Name)
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter your full name',
                          filled: true, fillColor: lightFillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter your name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field (Value used for Auth Email)
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email address',
                          filled: true, fillColor: lightFillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter your email';
                          if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) return 'Please enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mobile Field (Value NOT saved in this version)
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number (Optional)', // Indicate it might not be saved/used
                          hintText: 'Enter your phone number',
                          filled: true, fillColor: lightFillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.phone_outlined, color: primaryColor),
                        ),
                        // Keep validator for UI feedback, but data isn't stored by _signup
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter your mobile number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address Field (Value NOT saved in this version)
                      TextFormField(
                        controller: _addressController,
                        keyboardType: TextInputType.streetAddress,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Address (Optional)', // Indicate it might not be saved/used
                          hintText: 'Enter your address',
                          filled: true, fillColor: lightFillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.home_outlined, color: primaryColor),
                        ),
                        // Keep validator for UI feedback, but data isn't stored by _signup
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter your address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field (Value used for Auth Password)
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password', hintText: 'Enter your password', filled: true, fillColor: lightFillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: hintColor),
                            onPressed: () { setState(() { _obscurePassword = !_obscurePassword; }); },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your password';
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: _isLoading ? null : _signup,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password', hintText: 'Re-enter your password', filled: true, fillColor: lightFillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: hintColor),
                            onPressed: () { setState(() { _obscureConfirmPassword = !_obscureConfirmPassword; }); },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please confirm your password';
                          if (value != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Signup Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an Account? ", style: TextStyle(color: hintColor)),
                    TextButton(
                      onPressed: _isLoading ? null : () { Navigator.pushReplacementNamed(context, '/login'); },
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                      child: Text('Login', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}