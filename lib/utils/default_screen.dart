import 'package:flutter/material.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/utils/common_widgets.dart';
import 'package:go_router/go_router.dart';

class DefaultScreen extends StatelessWidget {
  const DefaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: genericErrorWidget(
        error: GenericError(),
        onRefresh: (){
          context.push(AppRouteName.splash);
        }
      ),
    );
  }
}
