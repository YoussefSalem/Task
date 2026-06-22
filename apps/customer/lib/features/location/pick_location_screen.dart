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

import '../booking/booking_state.dart';
import 'location_provider.dart';

const String _mapsKey = 'AIzaSyBkGqJxUaSwTtMdLG6HEArY2Ca_VO0yZKE';

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
      );
      final pos =
          await completer.future.timeout(const Duration(seconds: 10));
      final lat = pos.coords.latitude.toDouble();
      final lng = pos.coords.longitude.toDouble();
      if (!mounted) return;
      ref.read(locationProvider.notifier).setFromCoords(lat, lng);
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content:
              Text('Could not detect location. Check browser permissions.'),
        ));
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
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

          // Fixed center pin
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(
                    0, _mapDragging ? -12 : 0, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 22),
                    ),
                    // Pin stem
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(2)),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pin shadow on ground
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _mapDragging ? 8 : 14,
                height: _mapDragging ? 4 : 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: _mapDragging ? 0.2 : 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: mq.padding.top + AppSpacing.md,
            left: AppSpacing.lg,
            child: PointerInterceptor(
              child: _BackButton(onTap: () => context.pop()),
            ),
          ),

          // My location FAB
          Positioned(
            top: mq.padding.top + AppSpacing.md,
            right: AppSpacing.lg,
            child: PointerInterceptor(
              child: _MyLocationFab(
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
              child: _BottomPanel(
              address: _pinAddress,
              addressLoading: _addressLoading,
              text: text,
              bottomPadding: mq.padding.bottom,
              onConfirm: _confirmLocation,
              savedAddresses: kSavedAddresses,
              onSavedTap: (SavedAddress a) {
                ref
                    .read(locationProvider.notifier)
                    .setFromSaved(a.label, a.line);
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
  <input id="search-input" type="text" placeholder="Search for an address..." autocomplete="off"/>
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

// ---------------------------------------------------------------------------
// Back button
// ---------------------------------------------------------------------------
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background.withValues(alpha: 0.8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child:
            const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My location FAB
// ---------------------------------------------------------------------------
class _MyLocationFab extends StatelessWidget {
  const _MyLocationFab({required this.detecting, required this.onTap});
  final bool detecting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: detecting ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background.withValues(alpha: 0.8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: detecting
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom panel — address + saved + confirm
// ---------------------------------------------------------------------------
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.address,
    required this.addressLoading,
    required this.text,
    required this.bottomPadding,
    required this.onConfirm,
    required this.savedAddresses,
    required this.onSavedTap,
  });

  final String address;
  final bool addressLoading;
  final TextTheme text;
  final double bottomPadding;
  final VoidCallback onConfirm;
  final List<SavedAddress> savedAddresses;
  final ValueChanged<SavedAddress> onSavedTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        bottomPadding + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Grab handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Current pin address
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Service location',
                        style: text.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        )),
                    const SizedBox(height: 2),
                    addressLoading
                        ? Row(
                            children: <Widget>[
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Finding address...',
                                  style: text.bodySmall?.copyWith(
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.5),
                                  )),
                            ],
                          )
                        : Text(
                            address.isNotEmpty ? address : 'Move the map to set location',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            )),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Saved address chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: savedAddresses.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final a = savedAddresses[i];
                return GestureDetector(
                  onTap: () => onSavedTap(a),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(a.icon, size: 15, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(a.label,
                            style: text.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onConfirm,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('Set service location',
                          style: text.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
