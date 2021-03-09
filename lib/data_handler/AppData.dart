import 'package:flutter/cupertino.dart';
import 'package:uber/Model/address.dart';

class AppData extends ChangeNotifier
{

  Address pickUpLocation,dropOffLocation;

  void updatePickupLocationAddress(Address pickUpAddress)
  {
    pickUpLocation = pickUpAddress ;
    notifyListeners() ;
  }

  void updateDropOffLocationAddress(Address dropOffAddress)
  {
    dropOffLocation = dropOffAddress ;
    notifyListeners() ;
  }
}