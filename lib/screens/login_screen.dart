import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Ensure this path points to your SocialLoginButton widget
import '../../widgets/social_login_button.dart'; // Adjust path if needed

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Helper to show SnackBar ---
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // --- Email/Password Login ---
  void _loginWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;
    _dismissKeyboard(); // Dismiss keyboard
    setState(() { _isLoading = true; });
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') { errorMessage = 'Invalid email or password.'; }
      else if (e.code == 'invalid-email') { errorMessage = 'Invalid email format.'; }
      else if (e.code == 'user-disabled') { errorMessage = 'User account disabled.'; }
      else { errorMessage = e.message ?? errorMessage; } // Use Firebase message if available
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred.');
      debugPrint("Login Error: $e");
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // --- Google Sign-In ---
  void _signInWithGoogle() async {
    _dismissKeyboard();
    setState(() { _isGoogleLoading = true; });
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) { if (mounted) setState(() { _isGoogleLoading = false; }); return; }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      await _auth.signInWithCredential(credential);
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar('Google Sign-In failed: ${e.message ?? "An error occurred."}');
      debugPrint("Google Sign-In Error: $e");
    } catch (e) {
      _showErrorSnackBar('An unexpected Google Sign-In error occurred.');
      debugPrint("Google Sign-In Error: $e");
    } finally {
      if (mounted) setState(() { _isGoogleLoading = false; });
    }
  }

  // --- Forgot Password ---
  void _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) { _showErrorSnackBar('Please enter a valid email address.'); return; }
    _dismissKeyboard();
    // --- Confirmation Dialog ---
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password?'),
        content: Text('Send password reset link to $email?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Send')),
        ],
      ),
    );
    if (confirm != true) return;
    // --- End Confirmation Dialog ---
    setState(() { _isLoading = true; }); // Use main loading indicator
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset link sent to $email.'), backgroundColor: Colors.green,));
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Could not send reset link.';
      if (e.code == 'user-not-found') errorMessage = 'No user found for this email.';
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred sending reset link.');
      debugPrint("Forgot Password Error: $e");
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // --- Keyboard Dismissal Helper ---
  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get Theme info
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hintColor = theme.hintColor;
    // Determine brightness for logo selection
    final bool isDarkMode = theme.brightness == Brightness.dark;

    // --- Select Correct TEXT Logo Asset Path ---
    final String textLogoAssetPath = isDarkMode
        ? 'assets/images/logo/occaziologo1.png' // White logo for Dark Mode
        : 'assets/images/logo/occaziologo1P.png';  // Purple logo for Light Mode

    // --- Select Icon Logo Path (Doesn't change based on theme per request) ---
    const String iconLogoAssetPath = 'assets/images/logo/occaziologo2.png';

    // Define sizes
    final screenWidth = MediaQuery.of(context).size.width;
    final logoTextWidth = screenWidth * 0.65; // Width for occaziologo1/P
    final logoIconSize = 100.0; // Adjusted diameter for the circular icon background

    return Scaffold(
      body: GestureDetector( // Background tap dismisses keyboard
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // Nicer scroll physics
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30), // Adjusted top space

                  // --- === Logo Section === ---
                  Center(
                    child: Column(
                      children: [
                        // --- Circular Background for Icon Logo ---
                        Container(
                          height: logoIconSize,
                          width: logoIconSize,
                          padding: const EdgeInsets.all(20), // Adjusted padding
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08), // Consistent subtle bg
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            iconLogoAssetPath, // Uses static path
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.event_note, color: colorScheme.primary, size: 40), // Fallback
                          ),
                        ), // --- End Circular Background ---

                        const SizedBox(height: 24), // Spacing

                        // --- Text Logo (Switches based on theme) ---
                        Image.asset(
                          textLogoAssetPath, // <<< USES THEMED PATH
                          width: logoTextWidth,
                          fit: BoxFit.contain,
                          semanticLabel: 'Occazio Logo',
                          errorBuilder: (context, error, stackTrace) => Text('Occazio', style: theme.textTheme.displaySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                        ), // --- End Text Logo ---

                        const SizedBox(height: 10),

                        // --- EVENT MANAGEMENT Subtitle ---
                        Text(
                          'EVENT MANAGEMENT',
                          style: theme.textTheme.bodySmall?.copyWith( // Use theme style
                            letterSpacing: 2.5,
                            color: hintColor.withValues(alpha: isDarkMode ? 0.7 : 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ), // --- === END Logo Section === ---

                  const SizedBox(height: 40), // Spacing before Login Header

                  // --- Login Header ---
                  Text('Login', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Add your details to login', style: theme.textTheme.titleMedium?.copyWith(color: hintColor)),
                  const SizedBox(height: 32),

                  // --- Login Form ---
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration( // Relies on InputDecorationTheme from ThemeProvider
                            labelText: 'Email', // Use labelText instead of hintText if desired
                            prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary.withValues(alpha: 0.8)),
                          ),
                          validator: (value) { if (value == null || value.trim().isEmpty) { return 'Please enter your email'; } if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) { return 'Please enter a valid email'; } return null; },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: _isLoading || _isGoogleLoading ? null : _loginWithEmailPassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary.withValues(alpha: 0.8)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: hintColor),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              tooltip: _obscurePassword ? "Show password" : "Hide password",
                            ),
                          ),
                          validator: (value) { if (value == null || value.isEmpty) { return 'Please enter your password'; } if (value.length < 6) { return 'Password must be at least 6 characters'; } return null; },
                        ),
                      ],
                    ),
                  ), // End Form

                  const SizedBox(height: 10),

                  // --- Forgot Password ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading || _isGoogleLoading ? null : _forgotPassword,
                      child: const Text('Forgot your password?'), // Let TextButtonTheme handle styling
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Login Button ---
                  ElevatedButton(
                    onPressed: _isLoading || _isGoogleLoading ? null : _loginWithEmailPassword,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), // Full width
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) // Keep explicit white loader
                        : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Keep explicit text style
                  ),
                  const SizedBox(height: 24),

                  // --- Or Login With Divider ---
                  Row(children: [ const Expanded(child: Divider()), Padding( padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or Login With', style: TextStyle(color: hintColor)),), const Expanded(child: Divider()), ],),
                  const SizedBox(height: 24),

                  // --- Social Login Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible( // Allow buttons to shrink if needed
                        child: SocialLoginButton(
                          icon: Icons.facebook,
                          color: const Color(0xFF1877F2), // FB Blue
                          label: 'Facebook',
                          onPressed: _isLoading || _isGoogleLoading ? null : () => _showErrorSnackBar('Facebook Login coming soon!'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible( // Allow buttons to shrink
                        child: SizedBox( // SizedBox to contain Stack
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SocialLoginButton(
                                icon: Icons.g_mobiledata_outlined, // Find a better Google icon later
                                color: const Color(0xFFDB4437), // Google Red
                                label: 'Google',
                                onPressed: _isLoading || _isGoogleLoading ? null : _signInWithGoogle,
                              ),
                              if (_isGoogleLoading) // Loader Overlay
                                Container( decoration: BoxDecoration( color: Colors.black45, borderRadius: BorderRadius.circular(8)), child: const Center( child: SizedBox( height: 24, width: 24, child: CircularProgressIndicator( valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2.5,),),),)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ), // End Social Buttons Row
                  const SizedBox(height: 32),

                  // --- Sign Up Link ---
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [ Text("Don't have an Account? ", style: TextStyle(color: hintColor)), TextButton( onPressed: _isLoading || _isGoogleLoading ? null : () => Navigator.pushReplacementNamed(context, '/signup'), style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(0,0), tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text('Sign Up'),), ],),
                  const SizedBox(height: 20), // Bottom padding

                ],
              ),
            ),
          ),
        ),
      ), // End GestureDetector
    ); // End Scaffold
  } // End build
} // End _LoginScreenState