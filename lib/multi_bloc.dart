import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nimmys_crm/dependency_injection/locator.dart';
import 'package:nimmys_crm/features/authentication/cubit/login/login_cubit.dart';
import 'package:nimmys_crm/features/authentication/cubit/logout/logout_cubit.dart';
import 'package:nimmys_crm/features/authentication/cubit/session/session_cubit.dart';
import 'package:nimmys_crm/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:nimmys_crm/features/duties/cubit/tasks_cubit.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/profile/cubit/company/company_profile_cubit.dart';
import 'package:nimmys_crm/features/profile/cubit/profile/profile_cubit.dart';
import 'package:nimmys_crm/features/staff/cubit/staff/staff_cubit.dart';

class MultiBlocWrapper extends StatelessWidget {
  final Widget child;
  const MultiBlocWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginCubit>(create: (_) => locator<LoginCubit>()),
        BlocProvider<LogoutCubit>(create: (_) => locator<LogoutCubit>()),
        BlocProvider<SessionCubit>(create: (_) => locator<SessionCubit>()),
        BlocProvider<ProfileCubit>(create: (_) => locator<ProfileCubit>()),
        BlocProvider<StaffCubit>(create: (_) => locator<StaffCubit>()),
        BlocProvider<LeadsCubit>(create: (_) => locator<LeadsCubit>()),
        BlocProvider<CompanyProfileCubit>(
          create: (_) => locator<CompanyProfileCubit>(),
        ),
        BlocProvider<TasksCubit>(create: (_) => locator<TasksCubit>()),
        BlocProvider<DashboardCubit>(create: (_) => locator<DashboardCubit>()),
      ],
      child: child,
    );
  }
}
