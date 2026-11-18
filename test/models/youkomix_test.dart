import 'package:fl_clash/common/link.dart';
import 'package:fl_clash/models/youkomix.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/youkomix_e2ee_server.dart';

void main() {
  group('stripAnnouncementHtml', () {
    test('converts HTML breaks, paragraphs, entities, and strips tags', () {
      const raw =
          '<p>欢迎来到<strong>人间之里</strong>！<br/>节点已更新&nbsp;&amp;&nbsp;优化</p>'
          '<ul><li>香港 IPLC</li><li>日本 BGP</li></ul>';
      final text = stripAnnouncementHtml(raw);
      expect(text, contains('欢迎来到人间之里！'));
      expect(text, contains('节点已更新 & 优化'));
      expect(text, contains('香港 IPLC'));
      expect(text, isNot(contains('<')));
    });

    test('returns empty string for empty input', () {
      expect(stripAnnouncementHtml(''), isEmpty);
    });
  });

  group('YoukoMixMeta', () {
    test('parses backend meta payload and derives fallback URLs', () {
      final meta = YoukoMixMeta.fromJson(const {
        'app_name': '人间之里',
        'login_captcha_enabled': true,
      }, fallbackBaseUrl: 'https://panel.example.com///');
      expect(meta.appName, '人间之里');
      expect(meta.baseUrl, 'https://panel.example.com');
      expect(meta.captchaEnabled, isTrue);
      expect(meta.webAuthUrl, 'https://panel.example.com/user/client-auth');
      expect(meta.registerUrl, 'https://panel.example.com/auth/register');
      expect(meta.passwordResetUrl, 'https://panel.example.com/password/reset');

      final roundTrip = YoukoMixMeta.fromJson(meta.toJson());
      expect(roundTrip, meta);
      expect(roundTrip.hashCode, meta.hashCode);

      final cap = YoukoMixCaptchaChallenge.fromJson(const {
        'captcha_id': 'cch_model_1',
        'image_base64': 'data:image/png;base64,$tinyValidPngBase64',
        'expires_in': 180,
      });
      expect(cap.isValid, isTrue);
      expect(cap.captchaId, 'cch_model_1');
      expect(YoukoMixCaptchaChallenge.fromJson(cap.toJson()), cap);
    });
  });

  group('YoukoMixUser, Traffic, SubscriptionState, Announcement', () {
    test('parses user expiration, money formatting, and equality', () {
      final user = YoukoMixUser.fromJson(const {
        'id': '7',
        'email': 'marisa@example.com',
        'user_name': '雾雨魔理沙',
        'class': 2,
        'class_expire': '2028-05-01 12:00:00',
        'class_expire_days': 500,
        'is_expired': false,
        'money': 18.5,
        'online_ip_count': '2',
        'node_iplimit': 5,
      });
      expect(user.id, 7);
      expect(user.money, '18.50');
      expect(user.onlineIpCount, 2);
      expect(user.classExpireDate, isNotNull);
      expect(YoukoMixUser.parseExpireDate('1970-01-01 00:00:00'), isNull);
      expect(YoukoMixUser.parseExpireDate(''), isNull);

      final roundTrip = YoukoMixUser.fromJson(user.toJson());
      expect(roundTrip, user);
      expect(roundTrip.hashCode, user.hashCode);
    });

    test('computes traffic fallback fields and usageRatio', () {
      final traffic = YoukoMixTraffic.fromJson(const {
        'upload': 100,
        'download': 300,
        'today': 50,
        'total': 1000,
      });
      expect(traffic.used, 400);
      expect(traffic.remaining, 600);
      expect(traffic.usageRatio, closeTo(0.4, 0.001));
      expect(YoukoMixTraffic.fromJson(traffic.toJson()), traffic);
      expect(const YoukoMixTraffic().usageRatio, 0.0);
    });

    test('parses subscription state and announcement markdown preference', () {
      final sub = YoukoMixSubscriptionState.fromJson(const {
        'enabled': 1,
        'exclusive_enabled': 'true',
        'exclusive_title': '专属订阅',
        'active_mode': 'exclusive',
        'update_interval_hours': 12,
      });
      expect(sub.isExclusive, isTrue);
      expect(sub.exclusiveEnabled, isTrue);
      expect(YoukoMixSubscriptionState.fromJson(sub.toJson()), sub);

      final ann = YoukoMixAnnouncement.fromJson(const {
        'id': 3,
        'date': '2026-11-15',
        'title': '维护通知',
        'content': '<p>HTML 内容</p>',
        'markdown': '## 标题\n请开启 **X25519MLKEM768** 并查看 `配置说明`',
        'is_pinned': 1,
      });
      expect(ann.isPinned, isTrue);
      expect(ann.displayBody, '标题\n请开启 X25519MLKEM768 并查看 配置说明');
      expect(ann.displayBody, isNot(contains('##')));
      expect(ann.displayBody, isNot(contains('**')));
      expect(ann.displayBody, isNot(contains('`')));
      expect(YoukoMixAnnouncement.fromJson(ann.toJson()), ann);

      final htmlOnlyAnn = YoukoMixAnnouncement.fromJson(const {
        'id': 4,
        'title': 'HTML 通知',
        'content': '<h2>重要</h2><p>请阅读<strong>说明</strong></p>',
      });
      expect(htmlOnlyAnn.richMarkdownSource, contains('## 重要'));
      expect(htmlOnlyAnn.richMarkdownSource, contains('**说明**'));
    });
  });

  group('YoukoMixBootstrap and YoukoMixSession', () {
    test('maps panel info to links and round-trips session JSON', () {
      final session = YoukoMixSession.fromJson(const {
        'token': 'ymx_secret_token',
        'expires_at': 1999999999,
        'bootstrap': {
          'panel': {
            'name': '人间之里',
            'base_url': 'https://panel.example.com/',
            'user_center_url': 'https://panel.example.com/user',
          },
          'user': {
            'id': 1,
            'email': 'reimu@example.com',
            'user_name': '博丽灵梦',
            'class': 1,
          },
          'traffic': {'upload': 10, 'download': 20, 'total': 100},
          'subscription': {'active_mode': 'exclusive'},
          'announcements': [
            {'id': 1, 'title': '欢迎', 'content': '<p>你好</p>'},
          ],
          'upgrade_notice': {
            'enabled': true,
            'mode': 'scheduled',
            'cutover_at': 1795204020,
            'title': '开启 X25519MLKEM768 更新通知',
            'message': '系统即将全面开启 X25519MLKEM768 支持，请确保及时将客户端及本地配置更新至最新版本。',
          },
        },
      }, fallbackServerUrl: 'https://panel.example.com');

      expect(session.serverUrl, 'https://panel.example.com');
      expect(session.accessToken, 'ymx_secret_token');
      expect(
        session.bootstrap?.links.panelUrl,
        'https://panel.example.com/user',
      );
      expect(
        session.bootstrap?.links.webAuthUrl,
        'https://panel.example.com/user/client-auth',
      );
      expect(session.bootstrap?.announcements.single.displayBody, '你好');
      expect(session.bootstrap?.upgradeNotice?.enabled, isTrue);
      expect(session.bootstrap?.upgradeNotice?.isEnforced, isFalse);
      expect(session.bootstrap?.upgradeNotice?.cutoverAt, 1795204020);
      expect(session.bootstrap?.upgradeNotice?.cutoverDate, isNotNull);
      expect(session.bootstrap?.upgradeNotice?.title, '开启 X25519MLKEM768 更新通知');

      final serialized = session.toJson();
      final decoded = YoukoMixSession.fromJson(serialized);
      expect(decoded, session);
      expect(decoded.hashCode, session.hashCode);

      final updated = session.copyWith(
        accessToken: 'ymx_next',
        preferredSubMode: YoukoMixSubPreference.standard,
        bootstrap: session.bootstrap?.copyWith(
          subscription: session.bootstrap!.subscription.copyWith(
            activeMode: 'standard',
          ),
        ),
      );
      expect(updated.accessToken, 'ymx_next');
      expect(updated.preferredSubMode, YoukoMixSubPreference.standard);
      expect(updated.bootstrap?.subscription.activeMode, 'standard');
      expect(updated == session, isFalse);
      expect(YoukoMixSession.fromJson(updated.toJson()), updated);
      expect(
        YoukoMixSubPreference.fromString('EXCLUSIVE'),
        YoukoMixSubPreference.exclusive,
      );
      expect(
        YoukoMixSubPreference.fromString('unknown'),
        YoukoMixSubPreference.auto,
      );
      expect(
        parseYoukoMixDeepLink('youkomix://sync?mode=standard&format=/clash'),
        const YoukoMixSyncDeepLink(mode: YoukoMixSubPreference.standard),
      );
      expect(
        parseYoukoMixDeepLink('youkomix://sync?mode=exclusive'),
        const YoukoMixSyncDeepLink(mode: YoukoMixSubPreference.exclusive),
      );

      final enforcedNotice = YoukoMixUpgradeNotice.fromJson(const {
        'enabled': 1,
        'mode': 'REQUIRED',
        'cutover_at': '1795204020',
        'title': '开启 X25519MLKEM768 更新通知',
        'message': '系统已全面开启 X25519MLKEM768 支持，若遇到连接异常，请将客户端及本地配置更新至最新版本。',
      });
      expect(enforcedNotice.isEnforced, isTrue);
      expect(enforcedNotice.shouldDisplay, isTrue);
      expect(
        YoukoMixUpgradeNotice.fromJson(enforcedNotice.toJson()),
        enforcedNotice,
      );

      final cleared = session.bootstrap!.copyWith(clearUpgradeNotice: true);
      expect(cleared.upgradeNotice, isNull);

      final disabledBootstrap = YoukoMixBootstrap.fromJson(const {
        'upgrade_notice': {'enabled': false, 'title': '忽略'},
      });
      expect(disabledBootstrap.upgradeNotice, isNull);

      expect(isYoukoMixVersionBelow('1.1.0', '1.2.0'), isTrue);
      expect(isYoukoMixVersionBelow('1.2.0+2026111802', '1.2.0'), isFalse);
      expect(isYoukoMixVersionBelow('v1.3.0', '1.2.5'), isFalse);
      expect(isYoukoMixVersionBelow('', '1.2.0'), isFalse);

      expect(
        extractYoukoMixOneTimeCode(' copied ykx_AbCdEf12345678 token '),
        'ykx_AbCdEf12345678',
      );
      expect(
        extractYoukoMixOneTimeCode(
          'youkomix://auth?code=ykx_12345678&server=https://panel.example.com',
        ),
        'youkomix://auth?code=ykx_12345678&server=https://panel.example.com',
      );
      expect(extractYoukoMixOneTimeCode('hello world'), isNull);

      final readSession = session.copyWith(
        lastReadAnnouncementId: 8,
        lastPromptedPinnedId: 8,
      );
      expect(YoukoMixSession.fromJson(readSession.toJson()), readSession);

      final metaNonCommerce = YoukoMixMeta.fromJson(const {
        'app_name': '人间之里',
        'base_url': 'https://panel.example.com',
        'commerce_enabled': false,
        'reg_mode': 'close',
        'ticket_enabled': false,
        'checkin_enabled': true,
      });
      expect(metaNonCommerce.commerceEnabled, isFalse);
      expect(metaNonCommerce.regMode, 'close');
      expect(metaNonCommerce.ticketEnabled, isFalse);
      expect(metaNonCommerce.checkinEnabled, isTrue);
      expect(YoukoMixMeta.fromJson(metaNonCommerce.toJson()), metaNonCommerce);

      final checkinRes = YoukoMixCheckinResult.fromJson(const {
        'traffic_mb': 256,
        'message': '签到成功，获得 256 MB 流量',
        'bootstrap': {
          'panel': {'base_url': 'https://panel.example.com'},
          'commerce': {
            'enabled': false,
            'products': true,
            'balance': true,
            'free_reset_day': 15,
          },
          'features': {
            'reg_mode': 'invite',
            'ticket_enabled': false,
            'checkin_enabled': true,
            'able_to_checkin': false,
          },
        },
      });
      expect(checkinRes.trafficMb, 256);
      expect(checkinRes.bootstrap.commerce.enabled, isFalse);
      expect(checkinRes.bootstrap.commerce.products, isFalse);
      expect(checkinRes.bootstrap.commerce.balance, isFalse);
      expect(checkinRes.bootstrap.commerce.freeResetDay, 15);
      expect(
        checkinRes.bootstrap.commerce.shopUrl,
        'https://panel.example.com/user/product',
      );
      expect(checkinRes.bootstrap.features.canRegister, isTrue);
      expect(checkinRes.bootstrap.features.ticketEnabled, isFalse);
      expect(checkinRes.bootstrap.features.checkinEnabled, isTrue);
      expect(checkinRes.bootstrap.features.ableToCheckin, isFalse);
    });
  });
}
