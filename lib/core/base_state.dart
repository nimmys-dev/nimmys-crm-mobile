import 'package:flutter/material.dart';
import 'package:nimmys_crm/utils/custom_log.dart';

abstract class BaseState<T extends StatefulWidget> extends State<T> {


 



  @override
  void dispose() {
    // TODO: implement dispose
    CustomLog.info(this, "Disposed Called");
    super.dispose();
  }

}