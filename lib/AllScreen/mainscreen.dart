/*
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Location extends StatefulWidget {
  static const String idScreen = 'r';
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<Location> {
  GoogleMapController _controller;
  CameraPosition _initialPosition;
  List<Marker> markers = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    updateIu();
  }

  updateIu() {
    markers.add(
      Marker(
        infoWindow: InfoWindow(title: "It's you"),
        position: LatLng(31.520370, 74.358749),
        markerId: MarkerId("MyMarker"),
        draggable: false,
        onTap: () {
          print("marker tap");
        },
      ),
    );
    _initialPosition = CameraPosition(
      target: LatLng(31.520370,74.358749),
      zoom: 15.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.black,
            title: Text(
              "Brant farms",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: GoogleMap(
            initialCameraPosition: _initialPosition,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              setState(() {
                _controller = controller;
              });
            },
            markers: markers.toSet(),
            onTap: (cordinate) {
              _controller.animateCamera(CameraUpdate.newLatLng(cordinate));
              //addMarker(cordinate);
            },
          ),
        ));
  }
}
*/

import 'dart:async';
import 'dart:ui';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber/AllScreen/login_screen.dart';
import 'package:uber/AllScreen/search_screen.dart';
import 'package:uber/Assistants/AssistantMethods.dart';
import 'package:uber/Model/direction_detail.dart';
import 'package:uber/all_widget/divider_widget.dart';
import 'package:uber/all_widget/progress_dialog.dart';
import 'package:uber/data_handler/AppData.dart';

import '../config.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = 'mainScreen';

  @override
  _State createState() => _State();
}

class _State extends State<MainScreen> with TickerProviderStateMixin {
  Position currentPosition;
  var geolocator = Geolocator();
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polyLineSet = {};
  Set<Marker> markerset = {};
  Set<Circle> circleset = {};
  DirectionDetail tripdirectionDetail;

  double riderDetailContainerHeight = 0;
  double searchContainerHeight = 300;
  double requestRideContainerHeight = 0;
  bool drawerOpen = true;

  void resetApp() {
    setState(() {
      searchContainerHeight = 300;
      riderDetailContainerHeight = 0;
      bottomPaddingOfMap = 230;
      drawerOpen = true;
      requestRideContainerHeight = 0;

      polyLineSet.clear();
      markerset.clear();
      circleset.clear();
      pLineCoordinates.clear();
    });
    locatePosition();
  }

  void displayRideDetailController() async {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      riderDetailContainerHeight = 230;
      bottomPaddingOfMap = 230;
      drawerOpen = false;
    });
  }

  void displayrequsetRiderContainer() async {
    await getPlaceDirection();

    setState(() {
      requestRideContainerHeight = 250;
      riderDetailContainerHeight = 0;
      bottomPaddingOfMap = 230;
      drawerOpen = true;
    });
    saveRideRequest();
  }

  void cancelRequest()
  {
    refRideRequest.remove();
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    currentPosition = position;
    LatLng latlngPosition = LatLng(position.latitude, position.longitude);
    CameraPosition cameraPosition =
        new CameraPosition(target: latlngPosition, zoom: 15);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    String address =
        await AssistantMethods.searchCoordinateAddress(position, context);
    print('this is your address' + address);
  }

  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;
  GlobalKey<ScaffoldState> scafoldKey = new GlobalKey<ScaffoldState>();
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  DatabaseReference refRideRequest ;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest()
  {
    refRideRequest = FirebaseDatabase.instance.reference().child('Ride Requests').push();

    var pickUp = Provider.of<AppData>(context,listen: false).pickUpLocation ;
    var dropOff = Provider.of<AppData>(context,listen: false).dropOffLocation ;

    Map pickUpMap =
    {
      "latitude":pickUp.latitude.toString(),
      "longitude":pickUp.longitude.toString(),
    };

    Map dropOffMap =
    {
      "latitude":dropOff.latitude.toString(),
      "longitude":dropOff.longitude.toString(),
    };

    Map rideInfoMap =
    {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpMap,
      "dropoff": dropOffMap,
      "created_at": DateTime.now().toString(),
      "rider_name": currentUserInfo.name,
      "rider_phone": currentUserInfo.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,

    };

    refRideRequest.set(rideInfoMap);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scafoldKey,
      appBar: AppBar(
        title: Text('Main Screen'),
      ),
      drawer: Container(
        color: Colors.white,
        width: 255,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: <Widget>[
                      Image.asset(
                        'images/user_icon.png',
                        width: 65,
                        height: 65,
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Profile Name',
                            style: TextStyle(
                                fontSize: 16, fontFamily: 'Brand-Bold'),
                          ),
                          SizedBox(
                            height: 6,
                          ),
                          Text('Visit Profile'),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(
                height: 12,
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  'History',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  'Visit Profile',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text(
                  'About',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              InkWell(onTap: (){
                FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, LoginScreen.idScreen, (route) => false);
              },
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            polylines: polyLineSet,
            markers: markerset,
            circles: circleset,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
              setState(() {
                bottomPaddingOfMap = 300.0;
              });
              locatePosition();
            },
          ),
          Positioned(
              top: 27,
              left: 22,
              child: GestureDetector(
                onTap: () {
                  (drawerOpen)
                      ? scafoldKey.currentState.openDrawer()
                      : resetApp();
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22.0),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black,
                            blurRadius: 6.0,
                            spreadRadius: .5,
                            offset: Offset(0.7, 0.7))
                      ]),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      (drawerOpen) ? Icons.menu : Icons.close,
                      color: Colors.black,
                    ),
                    radius: 20.0,
                  ),
                ),
              )),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.0),
                        topRight: Radius.circular(18.0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 16.0,
                          spreadRadius: .5,
                          offset: Offset(0.7, 0.7))
                    ]),
                child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 6,
                          ),
                          Text(
                            'Hi there,',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Where to?',
                            style: TextStyle(
                                fontSize: 20, fontFamily: 'Brand-Bold'),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          GestureDetector(
                            onTap: () async {
                              var res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SearchScreen()));
                              if (res == 'obtainDirection') {
                                displayRideDetailController();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5.0),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black,
                                        blurRadius: 6.0,
                                        spreadRadius: .5,
                                        offset: Offset(0.7, 0.7))
                                  ]),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.search,
                                      color: Colors.blueAccent,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text('Search Drop off')
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 24,
                          ),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.home,
                                color: Colors.grey,
                              ),
                              SizedBox(
                                width: 12,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(Provider.of<AppData>(context)
                                                .pickUpLocation !=
                                            null
                                        ? Provider.of<AppData>(context)
                                            .pickUpLocation
                                            .placeName
                                        : 'Add Home'),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      'Your living home address',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 6,
                          ),
                          DividerWidget(),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.work,
                                color: Colors.grey,
                              ),
                              SizedBox(
                                width: 12,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text('Add Work'),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    'Your office address',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  )
                                ],
                              ),
                            ],
                          )
                        ])),
              ),
            ),
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: riderDetailContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 16.0,
                          spreadRadius: .5,
                          offset: Offset(0.7, 0.7))
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: double.infinity,
                                color: Colors.tealAccent,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: <Widget>[
                                      Image.asset(
                                        'images/taxi.png',
                                        width: 70,
                                        height: 80,
                                      ),
                                      SizedBox(
                                        width: 16,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Car',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontFamily: 'Brand Bold'),
                                          ),
                                          Text(
                                            (tripdirectionDetail != null)
                                                ? tripdirectionDetail
                                                    .distanceText
                                                : '',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'Brand Bold',
                                                color: Colors.grey),
                                          ),
                                          ///////////Expanded(child: Container()),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(left: 130),
                                        child: Text(
                                          (tripdirectionDetail != null)
                                              ? '\$${AssistantMethods.calculateFare(tripdirectionDetail)}'
                                              : '',
                                          style: TextStyle(
                                              fontFamily: 'Brand Bold',
                                              fontSize: 20),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      FontAwesomeIcons.moneyCheckAlt,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                    SizedBox(
                                      width: 16,
                                    ),
                                    Text(
                                      'Cash',
                                    ),
                                    SizedBox(
                                      width: 6,
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.black54,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 18,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: RaisedButton(
                                  color: Theme.of(context).accentColor,
                                  onPressed: () {displayrequsetRiderContainer();},
                                  child: Padding(
                                    padding: EdgeInsets.all(17),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          'Request',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Icon(
                                          FontAwesomeIcons.taxi,
                                          size: 26,
                                          color: Colors.white,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
          Positioned(
            bottom: 0.0,
            right: 0.0,
            left: 0.0,
            child: Container(
                height: requestRideContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 16.0,
                          spreadRadius: .5,
                          offset: Offset(0.7, 0.7))
                    ]),
                child: Padding(padding: EdgeInsets.all(0),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ColorizeAnimatedTextKit(
                          onTap: () {
                            print("Tap Event");
                          },
                          text: [
                            "Requesting a Ride...",
                            "Please wait...",
                            "Finding a driver...",
                          ],
                          textStyle:
                              TextStyle(fontSize: 35.0, fontFamily:  "Brand Bold"),
                          colors: [
                            Colors.purple,
                            Colors.blue,
                            Colors.yellow,
                            Colors.red,
                          ],
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        height: 22,
                      ),
                      GestureDetector(
                        onTap: (){
                          cancelRequest();
                              resetApp();
                        },
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(width: 2, color: Colors.grey)),
                          child: Icon(
                            Icons.close,
                            size: 26,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        child: Text(
                          "Cancel Ride",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: "Brand Bold"),
                        ),
                      )
                    ],
                  ),
                )),
          )
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickupLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOfLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: "Please wait...",
            ));

    var details = await AssistantMethods.obtainPlaceDirectionDetail(
        pickupLatLng, dropOfLatLng);

    setState(() {
      tripdirectionDetail = details;
    });

    Navigator.pop(context);
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();
    if (decodedPolyLinePointResult.isNotEmpty) {
      decodedPolyLinePointResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polyLineSet.clear();

    setState(() {
      Polyline polyLine = Polyline(
          color: Colors.pink,
          polylineId: PolylineId('PolylineId'),
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);
      polyLineSet.add(polyLine);
    });
    LatLngBounds latLngBounds;
    if (pickupLatLng.latitude > dropOfLatLng.latitude &&
        pickupLatLng.longitude > dropOfLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOfLatLng, northeast: pickupLatLng);
    } else if (pickupLatLng.longitude > dropOfLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickupLatLng.latitude, dropOfLatLng.longitude),
          northeast: LatLng(dropOfLatLng.latitude, pickupLatLng.longitude));
    } else if (pickupLatLng.latitude > dropOfLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOfLatLng.latitude, pickupLatLng.longitude),
          northeast: LatLng(pickupLatLng.latitude, dropOfLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickupLatLng, northeast: dropOfLatLng);
    }
    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker dropOfflocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: finalPos.placeName, snippet: 'drop off location'),
        position: dropOfLatLng,
        markerId: MarkerId("dropOffId"));

    Marker pickUolocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: initialPos.placeName, snippet: 'my location'),
        position: pickupLatLng,
        markerId: MarkerId("pickupId"));

    setState(() {
      markerset.add(pickUolocMarker);
      markerset.add(dropOfflocMarker);
    });

    Circle pickUplocCircle = Circle(
        fillColor: Colors.blueAccent,
        circleId: CircleId(
          "pickupId",
        ),
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.blueAccent);

    Circle dropOfflocCircle = Circle(
        fillColor: Colors.deepPurple,
        circleId: CircleId(
          "dropOffId",
        ),
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.deepPurple);

    setState(() {
      circleset.add(dropOfflocCircle);
      circleset.add(pickUplocCircle);
    });
  }
}
