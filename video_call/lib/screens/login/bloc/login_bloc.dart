/// Copyright (c) 2011-2020, Zingaya, Inc. All rights reserved.
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:video_call/screens/login/login.dart';
import 'package:video_call/services/auth_service.dart';
import 'package:video_call/utils/notification_helper.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthService _authService = AuthService();

  LoginBloc() : super(LoginInitial()) {
    add(LoadLastUser());
  }

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is LoadLastUser) {
      if (Platform.isAndroid &&
          await NotificationHelper().didNotificationLaunchApp()) {
        print('Launched from notification, skipping autologin');
        return;
      }
      String lastUser = await _authService.getUsername();
      yield LoginLastUserLoaded(lastUser: lastUser);
      bool canUseAccessToken = await _authService.canUseAccessToken();
      if (canUseAccessToken) {
        yield LoginInProgress();
        try {
          await _authService.loginWithAccessToken();
          yield LoginSuccess();
        } on VIException catch (e) {
          yield LoginFailure(errorCode: e.code, errorDescription: e.message);
        }
      }
    }
    if (event is LoginWithPassword) {
      yield LoginInProgress();
      try {
        await _authService.loginWithPassword(
            event.username + '.voximplant.com', event.password);
        yield LoginSuccess();
      } on VIException catch (e) {
        yield LoginFailure(errorCode: e.code, errorDescription: e.message);
      }
    }
  }
}
