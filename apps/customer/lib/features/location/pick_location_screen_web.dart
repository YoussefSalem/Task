import 'package:customer/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:task_design/task_design.dart';
import 'package:web/web.dart' as web;

import '../address/address_repository.dart';
import '../booking/booking_state.dart';
import 'location_provider.dart';
import 'pick_location_common.dart';

const String _mapsKey = 'AIzaSyBYeBkqiWJTiP-VPebzE3EWFt4MptMOqgA';

/// Web location picker — embeds an interactive Google Maps iframe and syncs the
/// map center with Flutter via `postMessage`.
class PickLocationScreen extends ConsumerStatefulWidget {
  const PickLocationScreen({super.key});

  static const String routePath = '/pick-location';
  static const String routeName = 'pick-location';

  @override
  ConsumerState<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends ConsumerState<PickLocationScreen> {
  bool _detecting = false;
  bool _mapDragging = false;
  double? _pinLat;
  double? _pinLng;
  String _pinAddress = '';
  bool _addressLoading = false;
  StreamSubscription<web.MessageEvent>? _messageSub;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    final loc = ref.read(locationProvider);
    _pinLat = loc.lat ?? 29.9602;
    _pinLng = loc.lng ?? 31.2569;
    _pinAddress = loc.address;
    _listenForMapMessages();
  }

  void _listenForMapMessages() {
    _messageSub = web.EventStreamProviders.messageEvent
        .forTarget(web.window)
        .listen((web.MessageEvent event) {
      try {
        final raw = event.data;
        if (raw == null) return;
        String jsonStr;
        if (raw.typeofEquals('string')) {
          jsonStr = (raw as JSString).toDart;
        } else {
          return;
        }
        final Map<String, dynamic> msg =
            jsonDecode(jsonStr) as Map<String, dynamic>;
        final String? type = msg['type'] as String?;
        if (type == 'mapCenter') {
          final lat = (msg['lat'] as num).toDouble();
          final lng = (msg['lng'] as num).toDouble();
          final address = msg['address'] as String? ?? '';
          if (!mounted) return;
          setState(() {
            _pinLat = lat;
            _pinLng = lng;
            if (address.isNotEmpty) {
              _pinAddress = address;
              _addressLoading = false;
            } else {
              _addressLoading = true;
            }
          });
        } else if (type == 'geocodeResult') {
          final address = msg['address'] as String? ?? '';
          if (address.isNotEmpty && mounted) {
            setState(() {
              _pinAddress = address;
              _addressLoading = false;
            });
          }
        } else if (type == 'dragStart') {
          if (mounted) setState(() => _mapDragging = true);
        } else if (type == 'dragEnd') {
          if (mounted) setState(() => _mapDragging = false);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  void _confirmLocation() {
    if (_pinLat == null || _pinLng == null) return;
    ref
        .read(locationProvider.notifier)
        .setFromPinDrop(_pinLat!, _pinLng!, _pinAddress);
    context.pop();
  }

  Future<void> _detectLocation() async {
    setState(() => _detecting = true);
    try {
      final geo = web.window.navigator.geolocation;
      final completer = Completer<web.GeolocationPosition>();
      geo.getCurrentPosition(
        ((web.GeolocationPosition p) => completer.complete(p)).toJS,
        ((web.GeolocationPositionError err) {
          if (!completer.isCompleted) completer.completeError(err);
        }).toJS,
        web.PositionOptions(
          enableHighAccuracy: true,
          timeout: 15000,
          maximumAge: 0,
        ),
      );
      final pos =
          await completer.future.timeout(const Duration(seconds: 20));
      final lat = pos.coords.latitude.toDouble();
      final lng = pos.coords.longitude.toDouble();
      final accuracy = pos.coords.accuracy.toDouble();
      web.console.log(
          'Geolocation: $lat, $lng  (accuracy ±${accuracy.round()} m)'.toJS);
      if (!mounted) return;
      setState(() {
        _pinLat = lat;
        _pinLng = lng;
        _addressLoading = true;
      });
      _panMapTo(lat, lng);
      if (accuracy > 500) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(
                'Approximate location (±${accuracy.round()} m). Drag the map to fine-tune.'),
          ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).couldNotDetectLocation),
        ));
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  void _panMapTo(double lat, double lng) {
    final iframe =
        web.document.querySelector('iframe') as web.HTMLIFrameElement?;
    if (iframe == null) return;
    final msg = jsonEncode({'type': 'panTo', 'lat': lat, 'lng': lng});
    iframe.contentWindow?.postMessage(msg.toJS, '*'.toJS);
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationProvider);
    final text = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Full-screen interactive map
          _InteractiveMap(
            lat: loc.lat ?? 29.9602,
            lng: loc.lng ?? 31.2569,
          ),

          // Fixed center pin + ground shadow
          CenterPin(dragging: _mapDragging),
          PinShadow(dragging: _mapDragging),

          // Back button
          Positioned(
            top: mq.padding.top + AppSpacing.md,
            left: AppSpacing.lg,
            child: PointerInterceptor(
              child: LocationBackButton(onTap: () => context.pop()),
            ),
          ),

          // My location FAB
          Positioned(
            top: mq.padding.top + AppSpacing.md,
            right: AppSpacing.lg,
            child: PointerInterceptor(
              child: MyLocationFab(
                detecting: _detecting,
                onTap: _detectLocation,
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PointerInterceptor(
              child: LocationBottomPanel(
                address: _pinAddress,
                addressLoading: _addressLoading,
                text: text,
                bottomPadding: mq.padding.bottom,
                onConfirm: _confirmLocation,
                savedAddresses:
                    ref.watch(savedAddressesProvider).valueOrNull ??
                        const <SavedAddress>[],
                onSavedTap: (SavedAddress a) {
                  ref
                      .read(locationProvider.notifier)
                      .setFromSavedCoords(a.label, a.line, a.lat, a.lng);
                  context.pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Interactive map (Maps JavaScript API via custom HTML)
// ---------------------------------------------------------------------------
class _InteractiveMap extends StatelessWidget {
  const _InteractiveMap({required this.lat, required this.lng});
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final viewType = 'interactive-map-$lat-$lng';

    final html = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden}
  #map{position:absolute;top:0;left:0;width:100%;height:100%;z-index:0}
  #search-wrap{
    position:absolute;top:12px;left:60px;right:60px;z-index:10;
    pointer-events:auto;
  }
  #search-input{
    width:100%;box-sizing:border-box;
    height:44px;padding:0 16px 0 42px;
    background:rgba(17,24,39,0.85);
    backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);
    border:1px solid rgba(255,255,255,0.1);
    border-radius:22px;
    color:#fff;font-size:14px;font-family:system-ui,-apple-system,sans-serif;
    outline:none;
    transition:all 0.25s cubic-bezier(0.4,0,0.2,1);
    box-shadow:0 4px 16px rgba(0,0,0,0.3);
  }
  #search-input::placeholder{color:rgba(255,255,255,0.45)}
  #search-input:focus{
    border-color:rgba(124,58,237,0.6);
    box-shadow:0 4px 20px rgba(0,0,0,0.4),0 0 0 3px rgba(124,58,237,0.15);
    background:rgba(17,24,39,0.95);
  }
  #search-icon{
    position:absolute;left:14px;top:50%;transform:translateY(-50%);
    width:18px;height:18px;pointer-events:none;
    opacity:0.45;transition:opacity 0.2s;
  }
  #search-input:focus~#search-icon{opacity:0.8}
  #clear-btn{
    position:absolute;right:10px;top:50%;transform:translateY(-50%);
    width:28px;height:28px;border:none;background:rgba(255,255,255,0.1);
    border-radius:50%;cursor:pointer;display:none;
    color:rgba(255,255,255,0.6);font-size:14px;line-height:28px;text-align:center;
    transition:background 0.15s;
  }
  #clear-btn:hover{background:rgba(255,255,255,0.18)}
  .pac-container{
    z-index:9999!important;
    pointer-events:auto!important;
    background:rgba(17,24,39,0.95)!important;
    backdrop-filter:blur(16px);-webkit-backdrop-filter:blur(16px);
    border:1px solid rgba(255,255,255,0.1)!important;
    border-radius:16px!important;
    box-shadow:0 8px 32px rgba(0,0,0,0.5)!important;
    margin-top:8px!important;
    padding:6px!important;
    font-family:system-ui,-apple-system,sans-serif!important;
    animation:dropIn 0.2s cubic-bezier(0.2,0,0,1)!important;
    transform-origin:top center!important;
  }
  @keyframes dropIn{from{opacity:0;transform:translateY(-8px) scale(0.97)}to{opacity:1;transform:translateY(0) scale(1)}}
  .pac-container:after{display:none!important}
  .pac-item{
    background:transparent!important;
    border:none!important;
    border-radius:10px!important;
    padding:10px 14px!important;
    color:rgba(255,255,255,0.85)!important;
    font-size:13px!important;
    line-height:1.4!important;
    cursor:pointer!important;
    pointer-events:auto!important;
    transition:background 0.15s!important;
  }
  .pac-item:hover,.pac-item-selected{
    background:rgba(124,58,237,0.15)!important;
  }
  .pac-item-query{
    color:#fff!important;font-weight:600!important;
    font-size:14px!important;
  }
  .pac-matched{color:#a78bfa!important}
  .pac-icon,.pac-icon-marker{
    filter:brightness(0) invert(1) opacity(0.4)!important;
    margin-right:10px!important;
  }
  .pac-item span:last-child{
    color:rgba(255,255,255,0.4)!important;
    font-size:12px!important;
  }
</style>
</head>
<body>
<div id="map"></div>
<div id="search-wrap">
  <input id="search-input" type="text" placeholder="${AppLocalizations.of(context).searchForAddress}" autocomplete="off"/>
  <svg id="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color:rgba(255,255,255,0.7)"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
  <button id="clear-btn" type="button">&#x2715;</button>
</div>
<script>
function initMap(){
  var geocoder=new google.maps.Geocoder();
  var debounceTimer=null;
  var map=new google.maps.Map(document.getElementById("map"),{
    center:{lat:$lat,lng:$lng},
    zoom:16,
    disableDefaultUI:true,
    zoomControl:true,
    zoomControlOptions:{position:google.maps.ControlPosition.RIGHT_CENTER},
    gestureHandling:"greedy",
    styles:[
      {elementType:"geometry",stylers:[{color:"#1d2c4d"}]},
      {elementType:"labels.text.stroke",stylers:[{color:"#1a3646"}]},
      {elementType:"labels.text.fill",stylers:[{color:"#8ec3b9"}]},
      {featureType:"water",elementType:"geometry",stylers:[{color:"#17263c"}]},
      {featureType:"road",elementType:"geometry",stylers:[{color:"#304a7d"}]},
      {featureType:"road",elementType:"geometry.stroke",stylers:[{color:"#255d6a"}]},
      {featureType:"road.highway",elementType:"geometry",stylers:[{color:"#2c6675"}]},
      {featureType:"poi",elementType:"geometry",stylers:[{color:"#283d6a"}]},
      {featureType:"transit",elementType:"geometry",stylers:[{color:"#2f3948"}]}
    ]
  });
  var input=document.getElementById("search-input");
  var clearBtn=document.getElementById("clear-btn");
  var autocomplete=new google.maps.places.Autocomplete(input,{
    fields:["geometry","formatted_address","name"],
    types:["geocode","establishment"]
  });
  autocomplete.bindTo("bounds",map);
  input.addEventListener("input",function(){
    clearBtn.style.display=input.value.length>0?"block":"none";
  });
  clearBtn.addEventListener("click",function(){
    input.value="";clearBtn.style.display="none";input.focus();
  });
  autocomplete.addListener("place_changed",function(){
    var place=autocomplete.getPlace();
    if(!place.geometry||!place.geometry.location)return;
    input.blur();input.value="";clearBtn.style.display="none";
    map.panTo(place.geometry.location);
    if(place.geometry.viewport){
      setTimeout(function(){map.fitBounds(place.geometry.viewport);},300);
    } else {
      map.setZoom(17);
    }
  });
  function post(obj){window.parent.postMessage(JSON.stringify(obj),"*");}
  function shortenAddr(full){
    var p=full.split(",").map(function(s){return s.trim();});
    return p.length<=2?full:p[0]+", "+p[1];
  }
  function reverseGeocode(lat,lng){
    geocoder.geocode({location:{lat:lat,lng:lng}},function(results,status){
      if(status!=="OK"||!results||!results.length)return;
      var best=null;
      for(var i=0;i<results.length;i++){
        var types=results[i].types||[];
        if(types.indexOf("plus_code")!==-1)continue;
        var dominated=false;
        for(var j=0;j<types.length;j++){
          if(types[j]==="plus_code"){dominated=true;break;}
        }
        if(dominated)continue;
        best=results[i];break;
      }
      if(!best)best=results[0];
      post({type:"geocodeResult",address:shortenAddr(best.formatted_address)});
    });
  }
  window.addEventListener("message",function(e){
    try{
      var d=JSON.parse(e.data);
      if(d.type==="panTo"){map.panTo({lat:d.lat,lng:d.lng});map.setZoom(17);}
    }catch(ex){}
  });
  map.addListener("dragstart",function(){post({type:"dragStart"});});
  map.addListener("dragend",function(){post({type:"dragEnd"});});
  map.addListener("idle",function(){
    var c=map.getCenter();
    var lat=c.lat(),lng=c.lng();
    post({type:"mapCenter",lat:lat,lng:lng,address:""});
    clearTimeout(debounceTimer);
    debounceTimer=setTimeout(function(){reverseGeocode(lat,lng);},400);
  });
}
</script>
<script src="https://maps.googleapis.com/maps/api/js?key=$_mapsKey&libraries=places&callback=initMap" async defer></script>
</body>
</html>
''';

    final dataUrl =
        'data:text/html;charset=utf-8,${Uri.encodeComponent(html)}';

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
      final iframe =
          web.document.createElement('iframe') as web.HTMLIFrameElement
            ..src = dataUrl
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allow = 'fullscreen';
      return iframe;
    });

    return HtmlElementView(viewType: viewType);
  }
}
