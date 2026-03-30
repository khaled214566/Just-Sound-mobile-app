import 'package:flutter/material.dart';
import 'package:idgaf/common/widgets/button/basic_app_button.dart';
import 'package:idgaf/core/configs/assets/app_images.dart';
import 'package:idgaf/core/configs/assets/app_vectors.dart';
import 'package:idgaf/core/configs/theme/app_colors.dart';
import 'package:idgaf/presentation/choose_mode/pages/choose_mode.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fill,
                image: AssetImage(AppImages.introBG),
              ),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(AppVectors.logo, width: 150, height: 150),
                ),
                Spacer(),
                Text(
                  'Enjoy Listening To Music Without Ads',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 21),
                Padding(
                  padding: EdgeInsets.only(left: 30, right: 30, bottom: 100),
                  child: BasicAppButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChooseModePage(),
                        ),
                      );
                    },
                    title: 'Get Started',
                    buttonColor: AppColors.primary,
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
