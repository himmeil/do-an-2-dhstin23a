import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    required this.onSubmit,
    this.onContinueAsGuest,
    this.promptMessage,
    super.key,
  });

  final Future<void> Function({
    required String email,
    required String password,
    required bool register,
  })
  onSubmit;
  final VoidCallback? onContinueAsGuest;
  final String? promptMessage;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _register = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        email: _emailController.text,
        password: _passwordController.text,
        register: _register,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error.code));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Không thể đăng nhập lúc này: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(String code) => switch (code) {
    'invalid-email' => 'Email không hợp lệ.',
    'user-disabled' => 'Tài khoản này đã bị vô hiệu hóa.',
    'user-not-found' ||
    'invalid-credential' ||
    'wrong-password' => 'Email hoặc mật khẩu không đúng.',
    'email-already-in-use' => 'Email này đã được đăng ký.',
    'weak-password' => 'Mật khẩu cần có ít nhất 6 ký tự.',
    'operation-not-allowed' =>
      'Đăng nhập email/mật khẩu chưa được bật trong Firebase Authentication.',
    'network-request-failed' => 'Không có kết nối mạng. Hãy thử lại.',
    _ => 'Đăng nhập thất bại ($code).',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const lotusBlue = Color(0xFF2879A8);
    const lotusPink = Color(0xFFD96F96);
    const lotusSky = Color(0xFFE8F4FB);
    const lotusBlush = Color(0xFFFFEDF3);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa điểm quanh đây'),
        backgroundColor: const Color(0xFFF1F8FC),
        foregroundColor: const Color(0xFF245A78),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE1F1FA), Color(0xFFFFEDF3), Color(0xFFF5FAF6)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 28,
              left: 20,
              child: Icon(
                Icons.local_florist_outlined,
                size: 58,
                color: lotusPink.withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 32,
              child: Icon(
                Icons.spa_outlined,
                size: 70,
                color: lotusBlue.withValues(alpha: 0.19),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 8,
                    shadowColor: lotusBlue.withValues(alpha: 0.18),
                    color: const Color(0xFFFFFEFE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SignInHero(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _register ? 'Tạo tài khoản' : 'Đăng nhập',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lưu địa điểm yêu thích, tìm kiếm và xem ảnh '
                                  'vệ tinh. Bạn vẫn có thể vào xem với tư cách khách.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                if (widget.promptMessage != null) ...[
                                  const SizedBox(height: 12),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [lotusSky, lotusBlush],
                                      ),
                                      border: Border.all(
                                        color: lotusBlue.withValues(
                                          alpha: 0.20,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        widget.promptMessage!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: lotusBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  onFieldSubmitted: (_) =>
                                      _passwordFocusNode.requestFocus(),
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: lotusBlue,
                                    ),
                                    filled: true,
                                    fillColor: lotusSky,
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      value == null || !value.contains('@')
                                      ? 'Nhập email hợp lệ.'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: _hidePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  autofillHints: [
                                    _register
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: lotusPink,
                                    ),
                                    filled: true,
                                    fillColor: lotusBlush,
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      tooltip: _hidePassword
                                          ? 'Hiện mật khẩu'
                                          : 'Ẩn mật khẩu',
                                      onPressed: () => setState(
                                        () => _hidePassword = !_hidePassword,
                                      ),
                                      icon: Icon(
                                        _hidePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                    ),
                                  ),
                                  validator: (value) => (value?.length ?? 0) < 6
                                      ? 'Mật khẩu cần có ít nhất 6 ký tự.'
                                      : null,
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    style: TextStyle(color: colors.error),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 18),
                                FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: lotusBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _busy
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _register ? 'Đăng ký' : 'Đăng nhập',
                                        ),
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(() {
                                          _register = !_register;
                                          _error = null;
                                        }),
                                  style: TextButton.styleFrom(
                                    foregroundColor: lotusPink,
                                  ),
                                  child: Text(
                                    _register
                                        ? 'Đã có tài khoản? Đăng nhập'
                                        : 'Chưa có tài khoản? Đăng ký',
                                  ),
                                ),
                                if (widget.onContinueAsGuest != null)
                                  OutlinedButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : widget.onContinueAsGuest,
                                    icon: const Icon(Icons.visibility_outlined),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: lotusBlue,
                                      side: const BorderSide(color: lotusPink),
                                      backgroundColor: lotusBlush,
                                    ),
                                    label: const Text(
                                      'Tiếp tục xem với tư cách khách',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInHero extends StatelessWidget {
  const _SignInHero();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 174,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/splash/launch.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0, 0.34),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xE62D816A),
                const Color(0xB8D96F96),
                const Color(0xA62D816A),
              ],
            ),
          ),
        ),
        Positioned(
          right: -25,
          top: -50,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 20,
              ),
            ),
          ),
        ),
        Positioned(
          right: 28,
          top: 24,
          child: Icon(
            Icons.local_florist_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.82),
          ),
        ),
        Positioned(
          right: 78,
          top: 58,
          child: Icon(
            Icons.circle,
            size: 10,
            color: const Color(0xFFFFD6E4).withValues(alpha: 0.9),
          ),
        ),
        Positioned(
          left: 24,
          right: 20,
          bottom: 22,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ĐI ĐÂU HÔM NAY?',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Khám phá Cao Lãnh',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
