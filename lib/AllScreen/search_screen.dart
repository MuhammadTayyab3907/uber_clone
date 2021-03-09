import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:uber/Assistants/request_assistants.dart';
import 'package:uber/Model/address.dart';
import 'package:uber/Model/place_prediction.dart';
import 'package:uber/all_widget/divider_widget.dart';
import 'package:uber/all_widget/progress_dialog.dart';
import 'package:uber/data_handler/AppData.dart';

import '../config.dart';

class SearchScreen extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<SearchScreen> {
  TextEditingController pickuplocation = TextEditingController();
  TextEditingController whereTolocation = TextEditingController();
  List<PlacePredictions> placePredictionList = [];

  @override
  Widget build(BuildContext context) {
    String placeAddress =
        Provider.of<AppData>(context).pickUpLocation.placeName ?? '';
    pickuplocation.text = placeAddress;

    return Scaffold(
        body: Column(
      children: <Widget>[
        Container(
          height: 215,
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
                color: Colors.black,
                blurRadius: 6.0,
                spreadRadius: .5,
                offset: Offset(0.7, 0.7))
          ]),
          child: Padding(
            padding: EdgeInsets.only(left: 25, right: 25, top: 25, bottom: 20),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 5,
                ),
                Stack(
                  children: [
                    GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back)),
                    Center(
                      child: Text(
                        'Set Drop Off',
                        style:
                            TextStyle(fontSize: 18, fontFamily: 'Brand-Bold'),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 16,
                ),
                Row(
                  children: <Widget>[
                    Image.asset(
                      'images/pickicon.png',
                      height: 16,
                      width: 16,
                    ),
                    SizedBox(
                      width: 18,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(5.0)),
                        child: Padding(
                          padding: EdgeInsets.all(3.0),
                          child: TextField(
                            controller: pickuplocation,
                            decoration: InputDecoration(
                                hintText: 'pickup location...',
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                    left: 11, top: 8, bottom: 8)),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: <Widget>[
                    Image.asset(
                      'images/desticon.png',
                      height: 16,
                      width: 16,
                    ),
                    SizedBox(
                      width: 18,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(5.0)),
                        child: Padding(
                          padding: EdgeInsets.all(3.0),
                          child: TextField(
                            onChanged: (val) {
                              findPlace(val);
                            },
                            controller: whereTolocation,
                            decoration: InputDecoration(
                                hintText: 'Where to?...',
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(
                                    left: 11, top: 8, bottom: 8)),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        (placePredictionList.length > 0)
            ? Expanded(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      return PredictionTile(
                        placePredictions: placePredictionList[index],
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return DividerWidget();
                    },
                    itemCount: placePredictionList.length,
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                  ),
                ),
            )
            : Container()
      ],
    ));
  }

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autoComUrl =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:pk';

      var res = await RequestAssistants.getRequest(autoComUrl);

      if (res == 'failed') {
        return;
      }

      if (res['status'] == 'OK') {
        var predictions = res['predictions'];
        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();
        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePredictions placePredictions;

  PredictionTile({Key key, this.placePredictions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: (){
        getplacedAddressDetail(placePredictions.place_id, context);
      },
      child: Container(
          child: Column(children: <Widget>[
        SizedBox(
          width: 10,
        ),
        Row(
          children: <Widget>[
            Icon(Icons.add_location),
            SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    placePredictions.secondary_text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  Text(
                    placePredictions.main_text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                ],
              ),
            )
          ],
        ),
        SizedBox(
          width: 10,
        )
      ])),
    );
  }
  void getplacedAddressDetail(String placeId,BuildContext context) async
  {
    showDialog(context: context,builder: (BuildContext context)=> ProgressDialog(message: 'Setting DropOff,Please wait...',));
    
    String placeDetailUrl = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey';

    var res = await RequestAssistants.getRequest(placeDetailUrl);

    Navigator.pop(context);
    if (res == 'failed') {
      return;
    }

    if (res['status'] == 'OK') {
     Address address = Address();
     address.placeName = res['result']['name'];
     address.placeId = placeId ;
     address.latitude = res['result']['geometry']['location']['lat'];
     address.longitude = res['result']['geometry']['location']['lng'];
     
     Provider.of<AppData>(context,listen: false).updateDropOffLocationAddress(address);
     Navigator.pop(context,'obtainDirection');
    }
  }
}
