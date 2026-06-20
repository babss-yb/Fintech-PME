import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _completeOnboarding() {
    context.read<SettingsProvider>().completeOnboarding();
    // main.dart will automatically route to LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Subtle background texture/grain effect could be added here
          Container(
            padding: const EdgeInsets.only(bottom: 120),
            child: PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() => isLastPage = index == 2);
              },
              children: [
                _buildPage(
                  context,
                  icon: Icons.timer,
                  title: 'FocusFlow',
                  subtitle: 'Atteignez un état de concentration maximale grâce à la méthode Pomodoro.',
                ),
                _buildPage(
                  context,
                  icon: Icons.list_alt,
                  title: 'Gérez vos tâches',
                  subtitle: 'Organisez votre journée en listant les tâches à accomplir et suivez votre progression.',
                ),
                _buildPage(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Statistiques & Historique',
                  subtitle: 'Visualisez vos performances et améliorez vos habitudes de travail.',
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      spacing: 8,
                      dotWidth: 8,
                      dotHeight: 8,
                      expansionFactor: 3,
                      dotColor: isDark ? Colors.white24 : Colors.black26,
                      activeDotColor: AppTheme.primaryColor,
                    ),
                    onDotClicked: (index) => _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeIn,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    text: isLastPage ? 'C\'est parti !' : 'Continuer',
                    onPressed: () {
                      if (isLastPage) {
                        _completeOnboarding();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.2),
                  AppTheme.secondaryColor.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              icon,
              size: 100,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 64),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
