library rhd_service_unilink;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rhd_core/rhd_core.dart' as RhdCore;
import 'package:rhd_core/rhd_util.dart' as RhdUtil;
import 'package:uni_links/uni_links.dart';

class UniLinkService extends RhdCore.RhdSettingsService {
  final String? appUrlKey;
  StreamSubscription? _sub_uni_links;
  final Function(Uri? uri, RhdCore.Settings _set)? elaborateUniLink;

  UniLinkService({
    this.appUrlKey,
    this.elaborateUniLink,
  }) : super('UniLinkService', 'rhd_service_unilink');

  @override
  Future<void> onBeforeServiceInit({RhdCore.Settings? set}) async {}

  @override
  Future<void> init({RhdCore.Settings? set}) async {
    if (set == null) return;

    // ... check initialLink
    try {
      Uri? initialUri = await getInitialUri();
      // Parse the link and warn the user, if it is not correct,
      // but keep in mind it could be `null`.
      if (initialUri != null) {
        set.doLog(
          'UniLink received on startup ($initialUri) ',
          type: RhdCore.AlertType.info,
          loglevel: RhdCore.LogLevel.info,
        );

        if (elaborateUniLink != null) {
          elaborateUniLink!(initialUri, set);
        } else {
          elabUniLink(initialUri, set);
        }
      }
    } on PlatformException {
      // Handle exception by warning the user their action did not succeed
      // return?
    }
    // Attach a listener to the stream
    _sub_uni_links = getUriLinksStream().listen((Uri? uri) {
      // Use the uri and warn the user, if it is not correct
      set.doLog(
        'UniLink received ($uri) ',
        type: RhdCore.AlertType.info,
        loglevel: RhdCore.LogLevel.info,
      );

      if (elaborateUniLink != null) {
        elaborateUniLink!(uri, set);
      } else {
        elabUniLink(uri, set);
      }
    }, onError: (err) {
      // Handle exception by warning the user their action did not succeed
      set.doLog(
        'UniLink error ($err) ',
        type: RhdCore.AlertType.error,
        loglevel: RhdCore.LogLevel.error,
      );
    });
  }

  @override
  void dispose({RhdCore.Settings? set}) {
    _sub_uni_links?.cancel();
  }

  @override
  Future<void> onAfterServiceInit({RhdCore.Settings? set}) async {}

  // Cancella apertura automatica dell 'istanza RHD
  @override
  RhdCore.Item? filterAutoItemOpen({
    RhdCore.Settings? set,
    RhdCore.Item? item,
  }) {
    return item;
  }

  // This method returns the settings of the service that are included in the general settings page
  @override
  Map<String, Map<String, dynamic>>? getMessages({RhdCore.Settings? set}) {
    return {
      'en': {
        'os_user_id': 'OS user id',
        'pushsec': 'Push notifications',
      },
      'it': {
        'os_user_id': RhdUtil.MessageLookupByLibrary.simpleMessage(
          'OS user id',
        ),
        'pushsec': 'Notifiche push',
      },
    };
  }

  @override
  Map<String, Map<String, dynamic>>? getGeneralSettings({
    RhdCore.Settings? set,
  }) {
    return null;
  }

  // This method returns the settings of the service that are included in the item settings page
  @override
  Map<String, Map<String, dynamic>>? getSettings({
    String? itemAppId,
    RhdCore.Settings? set,
  }) {
    if (itemAppId == null ||
        set == null ||
        itemAppId == RhdCore.Settings.myCloudRHDAppId) {
      return null;
    }

    return null;
  }

  Future<void> _evalQueryParameters(Map addDt, RhdCore.Settings set) async {
    RhdCore.Item? itm;
    String? title = '';
    String? body = '';
    String? appId = '';
    String? tabId = '';
    String? module = '';
    String? command = '';
    String? code = '';
    String? icon = '';

    if (addDt.containsKey('b64')) {
      var x = base64.decode(addDt['b64']);
      String y = utf8.decode(x);
      Map jsp = json.decode(y);

      RhdCore.Item item = RhdCore.Item(
        -1,
        jsp['appId'],
        jsp['name'],
        jsp['user_id'],
        jsp['refresh_token'],
        jsp['tokenurl'],
      );
      item.navigate_url = jsp['navigate_url'];
      item.url = jsp['url'];
      item.instance = jsp['instance'];
      item.user_id = jsp['user_id'];
      item.userFirstName = jsp['userFirstName'] ?? '';
      item.userLastName = jsp['userLastName'] ?? '';
      item.userLocale = jsp['userLocale'] ?? 'it';
      item.pcolor = jsp['pcolor'] ?? '' as Color?;
      item.scolor = jsp['scolor'] ?? '' as Color?;
      item.totpssec = jsp['totpssec'] ?? '';
      item.image = jsp['image'] ?? '';
      item.cutomername = jsp['customername'] ?? '';
      item.token = jsp['jSessionID'];
      item.appId = jsp['appId'];
      item.notifications_url = jsp['notifications_url'] ?? '';
      item.alt_udid = jsp['alt_udid'];
      item.access_token = jsp['access_token'];
      item.needAuth = false;
      item.error = '';

      RhdCore.ItemsRepository ir = RhdCore.ItemsRepository();
      ir.addIstanceWithCheck(item);
      ir.save();

      Timer(const Duration(milliseconds: 50), () {
        set.pushSignalStateForward(
          item,
          appId: item.appId,
          icon: null,
          body: null,
          title: null,
          force: true,
        );
      });
    }

    if (addDt.containsKey('appId')) {
      appId = addDt['appId'];

      List<RhdCore.Item> items = set.getItems();

      for (var itx in items) {
        if (itx.appId == appId) itm = itx;
      }
    }

    if (addDt.containsKey('body')) body = addDt['body'];

    if (addDt.containsKey('title')) title = addDt['title'];

    if (addDt.containsKey('tabId')) tabId = addDt['tabId'];

    if (addDt.containsKey('module')) module = addDt['module'];

    if (addDt.containsKey('command')) command = addDt['command'];

    if (addDt.containsKey('code')) code = addDt['code'];

    if (addDt.containsKey('icon')) icon = addDt['icon'];

    if (addDt.containsKey('d')) {
      String barcode = addDt['d'];
      String mmsg = '';
      bool toverwrite;
      RhdCore.Item titem;

      try {
        Uint8List barcodeUL = base64.decode(barcode);
        String barcodeCl = utf8.decode(barcodeUL);
        Map jsp = json.decode(barcodeCl);

        set.doLog(
          barcode,
          type: RhdCore.AlertType.info,
          loglevel: RhdCore.LogLevel.debug,
        );

        titem = RhdCore.Item(
          -1,
          jsp['appId'],
          jsp['name'],
          jsp['user_id'],
          jsp['refresh_token'],
          jsp['tokenurl'],
        );

        String xtitle = title ?? '';

        if (xtitle == '') {
          xtitle = RhdUtil.RHDLocalizations.of(
            RhdUtil.Utils.homeAppKey.currentContext!,
            'linknot_title_received',
          );
        }

        String xbody = body ?? '';

        if (xbody == '') {
          xbody = RhdUtil.RHDLocalizations.of(
            RhdUtil.Utils.homeAppKey.currentContext!,
            'linknot_body_received',
          );
        }

        RhdUtil.Utils.showNotifyBar(
          RhdUtil.Utils.homeAppKey.currentContext!,
          message: xbody,
          buttonText: RhdUtil.RHDLocalizations.of(
            RhdUtil.Utils.homeAppKey.currentContext!,
            'pushnot_open',
          ),
          buttonAction: () async {
            String? tok = await set.getBarcodeToken(
              barcodeCl,
              titem,
              disableCertificate: false,
            );

            if (tok == null || tok == '') {
              mmsg = RhdUtil.RHDLocalizations.of(
                RhdUtil.Utils.homeAppKey.currentContext!,
                'home_noreach',
                [titem.instance ?? ''],
              );

              if (titem.error != null && titem.error != '') {
                mmsg = titem.error ?? '';
              }
            } else {
              toverwrite = RhdCore.ItemsRepository().checkIstanceExist(
                titem,
              );

              if (toverwrite) {
                mmsg = RhdUtil.RHDLocalizations.of(
                  RhdUtil.Utils.homeAppKey.currentContext!,
                  'home_server_exists',
                  [titem.instance ?? ''],
                );
              }

              if (titem.disableSSLCertificate) {
                if (mmsg != '') mmsg += '\n';

                mmsg += RhdUtil.RHDLocalizations.of(
                  RhdUtil.Utils.homeAppKey.currentContext!,
                  'home_sslcert_error',
                );

                if ((titem.error ?? '') != '') {
                  mmsg += '\n${titem.error ?? ''}';
                }

                mmsg += '\n${RhdUtil.RHDLocalizations.of(
                  RhdUtil.Utils.homeAppKey.currentContext!,
                  'home_sslcert_confirm',
                )}';
              }
            }

            // Faccio vedere
            await RhdUtil.Utils.showModalDialog(
              RhdUtil.Utils.homeAppKey.currentContext!,
              onClose: () => titem.frozen = false,
              item: titem,
              title: titem.instance ?? '',
              child: RhdUtil.RhdInstanceCard(item: titem),
              content: RhdUtil.RHDLocalizations.of(
                RhdUtil.Utils.homeAppKey.currentContext!,
                'text_rhd_add',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    titem.status = 1;

                    RhdCore.ItemsRepository ir = RhdCore.ItemsRepository();

                    RhdCore.Item? nitm = ir.addIstanceWithCheck(titem);
                    if (nitm != null) {
                      ir.save();

                      // Chiude la modale
                      Navigator.of(
                        RhdUtil.Utils.homeAppKey.currentContext!,
                      ).pop(false);

                      // TODO: lancia RHD
                      Timer(const Duration(milliseconds: 50), () {
                        set.pushSignalStateForward(
                          nitm,
                          appId: appId,
                          tabId: tabId,
                          module: module,
                          command: command,
                          code: code,
                          icon: icon,
                          body: null,
                          title: null,
                          force: true,
                        );
                      });
                    }
                  },
                  child: Text(
                    RhdUtil.RHDLocalizations.of(
                      RhdUtil.Utils.homeAppKey.currentContext!,
                      'butt_confirm',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      RhdUtil.Utils.homeAppKey.currentContext!,
                    ).pop(false);
                  },
                  child: Text(
                    RhdUtil.RHDLocalizations.of(
                      RhdUtil.Utils.homeAppKey.currentContext!,
                      'butt_cancel',
                    ),
                  ),
                )
              ],
            ) as FutureOr<bool>;
          },
          isError: true,
        );
      } on FormatException {
        if (barcode != '') {
          mmsg = RhdUtil.RHDLocalizations.of(
              RhdUtil.Utils.homeAppKey.currentContext!, 'home_qrcode_noread');
        }
      } catch (e) {
        mmsg = RhdUtil.RHDLocalizations.of(
            RhdUtil.Utils.homeAppKey.currentContext!,
            'home_qrcode_norecognized'); //'QRcode non riconosciuto';  //TODO
        barcode = '';
      }
    }

    if (itm != null) {
      String xtitle = title ?? '';
      if (xtitle == '') {
        xtitle = RhdUtil.RHDLocalizations.of(
            RhdUtil.Utils.homeAppKey.currentContext!, 'linknot_title_received');
        ;
      }

      String xbody = body ?? '';
      if (xbody == '') {
        xbody = RhdUtil.RHDLocalizations.of(
          RhdUtil.Utils.homeAppKey.currentContext!,
          'linknot_body_received',
        );
      }

      RhdUtil.Utils.showNotifyBar(
        RhdUtil.Utils.homeAppKey.currentContext!,
        message: xbody,
        buttonText: RhdUtil.RHDLocalizations.of(
          RhdUtil.Utils.homeAppKey.currentContext!,
          'pushnot_open',
        ),
        buttonAction: () async {
          Timer(const Duration(milliseconds: 50), () {
            set.pushSignalStateForward(
              itm,
              appId: appId,
              tabId: tabId,
              module: module,
              command: command,
              code: code,
              icon: icon,
              body: null,
              title: null,
              force: true,
            );
          });
        },
      );
    }
  }

  void elabUniLink(Uri? uri, RhdCore.Settings set) {
    if (uri != null) {
      Map queryP = Map.from(uri.queryParameters);

      if (uri.scheme == 'https') {
        _evalQueryParameters(queryP, set);
      }

      if (uri.scheme == appUrlKey) {
        switch (uri.host) {
          case 'item':
            _evalQueryParameters(queryP, set);
            break;
        }
      }
    }
  }
}
