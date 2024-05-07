library rhd_service_unilink;
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rhd_core/rhd_core.dart' as RhdCore;
import 'package:rhd_core/rhd_util.dart' as RhdUtil;
import 'package:uni_links/uni_links.dart';

class UniLinkService extends RhdCore.RhdSettingsService{
  final String? appUrlKey;
  StreamSubscription? _sub_uni_links;
  final  Function(Uri? uri, RhdCore.Settings _set)? elaborateUniLink;


  UniLinkService({this.appUrlKey, this.elaborateUniLink}) : super('UniLinkService','rhd_service_unilink');
  
  @override
  Future<void> init({RhdCore.Settings? set}) async{
    if(set==null) return;
    //AppLink.AppUrlKey = this.rhdSettings!.uniLinksUrlKey;

    // ... check initialLink
    try {
      Uri? initialUri = await getInitialUri();
      // Parse the link and warn the user, if it is not correct,
      // but keep in mind it could be `null`.
      if(initialUri!=null){
        set.doLog('UniLink received on startup (' + initialUri.toString()+ ') ',type:RhdCore.AlertType.info,loglevel: RhdCore.LogLevel.info);
        if(elaborateUniLink!=null){
          this.elaborateUniLink!(initialUri,set);
        }else {
          this.elabUniLink(initialUri, set);
        }
      }

    } on PlatformException {
      // Handle exception by warning the user their action did not succeed
      // return?
    }
    // Attach a listener to the stream
    _sub_uni_links = getUriLinksStream().listen((Uri? uri) {
      // Use the uri and warn the user, if it is not correct
      set.doLog('UniLink received (' + uri.toString()+ ') ',type:RhdCore.AlertType.info,loglevel: RhdCore.LogLevel.info);
      if(elaborateUniLink!=null){
        this.elaborateUniLink!(uri,set);
      }else {
        this.elabUniLink(uri, set);
      }
    }, onError: (err) {
      // Handle exception by warning the user their action did not succeed
      set.doLog('UniLink error (' + err.toString()+ ') ',type:RhdCore.AlertType.error,loglevel: RhdCore.LogLevel.error);
    });
  }

  @override
  void dispose({RhdCore.Settings? set}){
    _sub_uni_links?.cancel();
  }


  @override
  Future<void> onAfterServiceInit({RhdCore.Settings? set,RhdCore.RhdSettingsService? service}) async{


  }


  /// cancella apertura automatica dell 'istanza RHD
  @override
  RhdCore.Item? filterAutoItemOpen({RhdCore.Settings? set,RhdCore.Item? item}) {


    return item;

  }
  
  /// This method returns the settings of the service that are included in the general settings page

  @override
  Map<String,Map<String, dynamic>>? getMessages({RhdCore.Settings? set}) {
    return {
      "en":{
        "os_user_id": "OS user id",
        "pushsec": "Push notifications",
      },
      "it":{
        "os_user_id": RhdUtil.MessageLookupByLibrary.simpleMessage( "OS user id"),
        "pushsec": "Notifiche push",
      },
    };
  }

  @override
  Map<String, Map<String,dynamic>>? getGeneralSettings({RhdCore.Settings? set}){

    return null;

    /* es:  return {
      "qrcodesec" : { 'type':'boolean','section':'view', 'show': set?.experimental, 'state': true, 'save':true, 'default': false, 'reset':false },
      "pushsec" : { 'type':'boolean','section':'view', 'show': set?.experimental, 'state': true, 'save':true, 'default': false, 'reset':false },
      "timesheetsCacheSeconds"  : { 'type':'integer-slider-boolean','section':'view', 'show':true, 'state':true, 'save':true, 'default': set?.property("timesheetsCacheSeconds")??0,'min': 0,'max': 20000,  },
      "projectsCacheSeconds"  : { 'type':'integer-slider-boolean','section':'view', 'show':true, 'state':true, 'save':true, 'default': set?.property("timesheetsCacheSeconds")??3600,'min': 0,'max': 20000,  },
      "holidaysCacheSeconds"  : { 'type':'integer-slider-boolean','section':'view', 'show':true, 'state':true, 'save':true, 'default': set?.property("timesheetsCacheSeconds")??3600,'min': 0,'max': 20000,  },
      "increasemonthsinterval"  : { 'type':'integer-slider-boolean','section':'view', 'show':true, 'state':true, 'save':true, 'default': set?.property("increaseMonthsInterval")??3,'min': 0,'max': 10,  },
    };*/
    return null;
  }

  /// This method returns the settings of the service that are included in the item settings page

  @override
  Map<String, Map<String,dynamic>>? getSettings({String? itemAppId,RhdCore.Settings? set}){
    if( itemAppId==null || set==null || itemAppId == RhdCore.Settings.myCloudRHDAppId ){
      // || _item.access_token!= Settings.myCloudRHDAccessTokenDefault
      return null;
    }

    /* es:  return {
      "qrcodesec" : { 'type':'boolean','section':'view', 'show': set?.experimental, 'state': true, 'save':true, 'default': false, 'reset':false },
      "pushsec" : { 'type':'boolean','section':'view', 'show': set?.experimental, 'state': true, 'save':true, 'default': false, 'reset':false },
      "timesheetsCacheSeconds"  : { 'type':'integer-slider-boolean','section':'view', 'show':true, 'state':true, 'save':true, 'default': set?.property("timesheetsCacheSeconds")??0,'min': 0,'max': 20000,  },
      "projectsCacheSeconds"  : { 'type':'integer-slider-boolean','section':'view', 'show':true, 'state':true, 'save':true, 'default': set?.property("timesheetsCacheSeconds")??3600,'min': 0,'max': 20000,  },
      "holidaysCacheSeconds"  : { 'type':'integer-slider-boolean','section':'view', 'show':true, 'state':true, 'save':true, 'default': set?.property("timesheetsCacheSeconds")??3600,'min': 0,'max': 20000,  },
      "increasemonthsinterval"  : { 'type':'integer-slider-boolean','section':'view', 'show':true, 'state':true, 'save':true, 'default': set?.property("increaseMonthsInterval")??3,'min': 0,'max': 10,  },
    };*/
    return null;
  }

  Future<void> _evalQueryParameters(Map addDt,RhdCore.Settings _set) async {
    RhdCore.Item? itm;
    String? title = "";
    String? body = "";
    String? appId = "";
    String? tabId = "";
    String? module = "";
    String? command = "";
    String? code = "";
    String? icon = "";
    //Map<String,dynamic> addDt = notification.notification.additionalData;




    if(addDt.containsKey("b64")){
      var x = base64.decode(addDt["b64"]);
      String y = utf8.decode(x);
      Map jsp = json.decode(y);
      //print(jsp);

      //Item.fromJson(njson, i)

      RhdCore.Item _item = RhdCore.Item(
          -1, jsp["appId"],
          jsp["name"],
          jsp["user_id"],
          jsp["refresh_token"],
          jsp["tokenurl"]);
      _item.navigate_url = jsp["navigate_url"];
      _item.url = jsp["url"];
      _item.instance = jsp["instance"];
      //_item.userNickName = jsp["userName"];
      _item.user_id = jsp["user_id"];

      _item.userFirstName =
          jsp['userFirstName'] ?? '';
      _item.userLastName =
          jsp['userLastName'] ?? '';
      _item.userLocale =
          jsp['userLocale'] ?? 'it';

      _item.pcolor =
          jsp['pcolor'] ?? '' as Color?;
      _item.scolor =
          jsp['scolor'] ?? '' as Color?;
      _item.totpssec =
          jsp['totpssec'] ?? '';
      _item.image = jsp['image'] ?? '';
      _item.cutomername =
          jsp['customername'] ?? '';

      _item.token = jsp["jSessionID"];
      _item.appId = jsp["appId"];

      _item.notifications_url = jsp["notifications_url"] ?? '';
      _item.alt_udid = jsp["alt_udid"];
      _item.access_token = jsp["access_token"];
      _item.needAuth = false;
      _item.error = "";
      RhdCore.ItemsRepository ir = RhdCore.ItemsRepository();
      ir.addIstanceWithCheck(_item);
      ir.save();

      Timer(const Duration(milliseconds: 50), () {
        _set.pushSignalStateForward(
            _item,
            appId: _item.appId,
            icon: null,
            body: null,
            title: null,
            force:true);
      });

    }

    if (addDt.containsKey("appId")) {
      appId = addDt["appId"];

      List<RhdCore.Item> _items = _set.getItems();
      _items.forEach((RhdCore.Item itx) {
        if (itx.appId == appId) {
          itm = itx;
        }
      });
    }
    if (addDt.containsKey("body")) {
      body = addDt["body"];
    }
    if (addDt.containsKey("title")) {
      title = addDt["title"];
    }
    if (addDt.containsKey("tabId")) {
      tabId = addDt["tabId"];
    }
    if (addDt.containsKey("module")) {
      module = addDt["module"];
    }
    if (addDt.containsKey("command")) {
      command = addDt["command"];
    }
    if (addDt.containsKey("code")) {
      code = addDt["code"];
    }
    if (addDt.containsKey("icon")) {
      icon = addDt["icon"];
    }

    if(addDt.containsKey("d")){
      String barcode = addDt["d"];
      String mmsg = '';
      bool toverwrite;
      RhdCore.Item _titem;
      try {
        Uint8List barcodeUL =  base64.decode(barcode);
        String barcodeCl = utf8.decode(barcodeUL);
        Map jsp = json.decode(barcodeCl);

        _set.doLog(barcode,type:RhdCore.AlertType.info,loglevel: RhdCore.LogLevel.debug);
        _titem = RhdCore.Item(-1,jsp["appId"], jsp["name"], jsp["user_id"], jsp["refresh_token"],jsp["tokenurl"]);

        if(_titem!=null){

          String xtitle = title??'';
          if(xtitle==''){
            xtitle = RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'linknot_title_received');
          }

          String xbody = body??'';
          if(xbody == ''){
            xbody = RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'linknot_body_received');
          }
          Icon? icc;
          Color cp = _titem.pcolor??Theme.of(RhdUtil.Utils.homeAppKey.currentContext!).colorScheme.secondary;

          if(icon!=null && icon !=''){
            IconData? ic = RhdUtil.ContentHelper.getFontAwesomeIcon(name:icon);
            if(ic!=null){
              //icc =Icon(ic);
              icc = Icon(
                  ic,
                  size: 28,
                  color: cp
              );
            }
          }
          RhdUtil.Utils.showFlushbar(
            context: RhdUtil.Utils.homeAppKey.currentContext!,
            title: xtitle,
            message: xbody,
            onPressed: () async {

              String? tok = await _set.getBarcodeToken(barcodeCl, _titem, disableCertificate: false); //this.disableCertificate

              // tok="";
              if ( tok==null || tok == "") {
                mmsg = RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'home_noreach', [_titem.instance ?? '']);

                if (_titem.error != null && _titem.error != '') {
                  mmsg = _titem.error??'';
                }
              } else {
                toverwrite = RhdCore.ItemsRepository().checkIstanceExist(_titem);
                //bool res = true;
                if (toverwrite) {
                  mmsg = RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'home_server_exists', [_titem.instance ?? '']);
                }

                //this._item = _titem;
                //this.disableCertificate = _titem.disableSSLCertificate;
                if (_titem.disableSSLCertificate) {
                  if (mmsg != "") mmsg += "\n";
                  mmsg += RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'home_sslcert_error');
                  if ((_titem.error ?? "") != "") {
                    mmsg += "\n" + (_titem.error ?? "");
                  }
                  mmsg += "\n" + RhdUtil.RHDLocalizations.of(
                      RhdUtil.Utils.homeAppKey.currentContext!, 'home_sslcert_confirm'); //"errore cert";;
                }

              }
              // faccio vedere

              bool res = await (RhdUtil.Utils.showModalDialog(
                RhdUtil.Utils.homeAppKey.currentContext!,
                onClose: (){
                  _titem.frozen = false;
                },
                item:_titem,
                //image: _titem.image,
                title: _titem.instance ?? '',
                child: RhdUtil.RhdInstanceCard(item:_titem),
                content: RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'text_rhd_add'),
                actions: <Widget>[
                  TextButton(
                      onPressed: () async {
                        _titem.status = 1;

                        RhdCore.ItemsRepository ir = RhdCore.ItemsRepository();

                        RhdCore.Item? nitm = ir.addIstanceWithCheck(_titem);
                        if(nitm!=null) {
                          ir.save();
                          Navigator.of(RhdUtil.Utils.homeAppKey.currentContext!).pop(false); //chiude la modale
                          //TODO lancia RHD
                          Timer(const Duration(milliseconds: 50), () {
                            _set.pushSignalStateForward(
                                nitm,
                                appId: appId,
                                tabId:tabId,
                                module: module,
                                command: command,
                                code: code,
                                icon: icon,
                                body: null,
                                title: null,
                                force: true);
                          });
                        }
                      },
                      child: Text(RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'butt_confirm'))),
                  TextButton(
                    onPressed: () {
                      Navigator.of(RhdUtil.Utils.homeAppKey.currentContext!).pop(false);
                    },
                    child: Text(RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'butt_cancel')),
                  )
                ],
              ) as FutureOr<bool>);

            },
            mainButtonText: Text(
              RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'pushnot_open'),
              //  style: TextStyle(color: cp),
            ),
            icon: icc,
            leftBarIndicatorColor: cp,
          );
        }

      } on FormatException {
        if (barcode != "") {
          mmsg = RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'home_qrcode_noread');

        }
      } catch (e) {
        mmsg = RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'home_qrcode_norecognized'); //"QRcode non riconosciuto";  //TODO
        barcode = "";
      }

    }

    if(itm!=null){
      String xtitle = title??'';
      if(xtitle==''){
        xtitle = RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'linknot_title_received');;
      }

      String xbody = body??'';
      if(xbody == ''){
        xbody = RhdUtil.RHDLocalizations.of(RhdUtil.Utils.homeAppKey.currentContext!, 'linknot_body_received');
      }
      Icon? icc;
      Color cp = itm?.pcolor??Theme.of(RhdUtil.Utils.homeAppKey.currentContext!).colorScheme.secondary;

      if(icon!=null && icon !=''){
        IconData? ic = RhdUtil.ContentHelper.getFontAwesomeIcon(name:icon);
        if(ic!=null){
          //icc =Icon(ic);
          icc = Icon(
              ic,
              size: 28,
              color: cp
          );
        }
      }
      //Color cp = itm.pcolor;
      RhdUtil.Utils.showFlushbar(
        context: RhdUtil.Utils.homeAppKey.currentContext!,
        title: xtitle,
        message: xbody,
        mainButton: TextButton(
          child: Text(
            RhdUtil.RHDLocalizations.of(
                RhdUtil.Utils.homeAppKey.currentContext!, 'pushnot_open'),
            style: TextStyle(color: cp),
          ),
          onPressed: () async {
            // await this._cleanup();
            // Navigator.of(context).pop(true);
            Timer(const Duration(milliseconds: 50), () {
              _set.pushSignalStateForward(
                  itm,
                  appId:appId,
                  tabId:tabId,
                  module:module,
                  command: command,
                  code:code,
                  icon: icon,
                  body: null,
                  title: null,
                  force: true);
            });
          },
        ),
        icon: icc,
        leftBarIndicatorColor: cp,
      );
    }
  }


   void elabUniLink(Uri? uri,RhdCore.Settings _set){

    if(uri!=null){
      Map queryP = Map.from(uri.queryParameters);

      if(uri.scheme=="https"){
        if(queryP!=null) {
          _evalQueryParameters(queryP,_set);
        }
      }
      if(uri.scheme==this.appUrlKey){
        switch(uri.host){
          case "item":
            if(queryP!=null){
              _evalQueryParameters(queryP,_set);
            }
            break;
        }
      }
      /*switch(uri.scheme){
          case "https":  //ios Universal Links  , Android App Links
            if(queryP!=null) {
              _evalQueryParameters(queryP,_set);
            }
            break;
          case AppLink.AppUrlKey:  //ios Custom URL schemes , Android Deep Links
            switch(uri.host){
              case "item":
                if(queryP!=null){
                  _evalQueryParameters(queryP,_set);
                }
                break;


            }

            break;

        }*/


    }

  }


}
