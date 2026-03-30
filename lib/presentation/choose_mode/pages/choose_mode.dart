import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:idgaf/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:idgaf/presentation/home/home.dart';

import '../../../common/widgets/button/basic_app_button.dart';
import '../../../core/configs/assets/app_images.dart';
import '../../../core/configs/assets/app_vectors.dart';
import '../../../core/configs/theme/app_colors.dart';

class ChooseModePage extends StatefulWidget {
  const ChooseModePage({super.key});

  @override
  State<ChooseModePage> createState() => _ChooseModePageState();
}

class _ChooseModePageState extends State<ChooseModePage>
    with TickerProviderStateMixin {
  late AnimationController _lightScaleController;
  late AnimationController _darkScaleController;
  late Animation<double> _lightScaleAnimation;
  late Animation<double> _darkScaleAnimation;

  @override
  void initState() {
    super.initState();
    _lightScaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _darkScaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _lightScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _lightScaleController, curve: Curves.easeInOut),
    );
    _darkScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _darkScaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _lightScaleController.dispose();
    _darkScaleController.dispose();
    super.dispose();
  }

  void _selectLight() {
    _lightScaleController.forward().then((_) {
      _lightScaleController.reverse();
    });
    context.read<ThemeCubit>().updateTheme(ThemeMode.light);
  }

  void _selectDark() {
    _darkScaleController.forward().then((_) {
      _darkScaleController.reverse();
    });
    context.read<ThemeCubit>().updateTheme(ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage(AppImages.chooseModeBG),
              ),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(AppVectors.logo, width: 150, height: 150),
                ),
                const Spacer(),
                Text(
                  'Choose Mode',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sora',
                    color: context.watch<ThemeCubit>().state == ThemeMode.light
                        ? Colors.black
                        : Colors.white,
                    fontSize: 35,
                  ),
                ),
                const SizedBox(height: 21),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Light Mode Button
                      _ModeSelector(
                        title: 'Light Mode',
                        vector: AppVectors.sun,
                        isSelected:
                            context.watch<ThemeCubit>().state ==
                            ThemeMode.light,
                        onTap: _selectLight,
                        scaleAnimation: _lightScaleAnimation,
                      ),
                      const SizedBox(width: 50),
                      // Dark Mode Button
                      _ModeSelector(
                        title: 'Dark Mode',
                        vector: AppVectors.moon,
                        isSelected:
                            context.watch<ThemeCubit>().state == ThemeMode.dark,
                        onTap: _selectDark,
                        scaleAnimation: _darkScaleAnimation,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 30,
                    right: 30,
                    bottom: 100,
                  ),
                  child: BasicAppButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Home()),
                      );
                    },
                    title: 'Continue',
                    buttonColor: AppColors.primary,
                    textSize: 25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable Mode Selector Widget
class _ModeSelector extends StatelessWidget {
  final String title;
  final String vector;
  final bool isSelected;
  final VoidCallback onTap;
  final Animation<double> scaleAnimation;

  const _ModeSelector({
    required this.title,
    required this.vector,
    required this.isSelected,
    required this.onTap,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      // Highlight border when selected
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: SvgPicture.asset(vector, fit: BoxFit.fitHeight),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Sora',
            color: isSelected ? AppColors.primary : AppColors.darkGrey,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
