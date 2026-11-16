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
        'markdown': '纯文本通知',
        'is_pinned': 1,
      });
      expect(ann.isPinned, isTrue);
      expect(ann.displayBody, '纯文本通知');
      expect(YoukoMixAnnouncement.fromJson(ann.toJson()), ann);
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
    });
  });
}
