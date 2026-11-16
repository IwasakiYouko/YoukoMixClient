import 'package:fl_clash/common/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('ProtocolRegistrationPlan', () {
    test('builds registry writes for URL protocol registration', () {
      const plan = ProtocolRegistrationPlan(
        scheme: 'youkomix',
        executable: r'C:\Program Files\YoukoMix\YoukoMix.exe',
      );

      expect(plan.protocolKey, r'Software\Classes\youkomix');
      expect(plan.commandKey, r'shell\open\command');
      expect(plan.protocolValueName, 'URL Protocol');
      expect(plan.protocolValue, '');
      expect(plan.command, r'"C:\Program Files\YoukoMix\YoukoMix.exe" "%1"');
    });
  });

  group('LinuxProtocolRegistrationPlan', () {
    const plan = LinuxProtocolRegistrationPlan(
      schemes: protocolSchemes,
      executable: '/home/me/Apps/YoukoMix.AppImage',
      applicationsDir: '/home/me/.local/share/applications',
    );

    test('writes a hidden desktop entry claiming every scheme', () {
      expect(
        plan.desktopPath,
        '/home/me/.local/share/applications/youkomix-url-handler.desktop',
      );
      expect(
        plan.desktopEntry,
        '[Desktop Entry]\n'
        'Type=Application\n'
        'Name=人间之里\n'
        'NoDisplay=true\n'
        'Exec="/home/me/Apps/YoukoMix.AppImage" %u\n'
        'MimeType=x-scheme-handler/youkomix;\n',
      );
    });

    test('makes the entry the default handler for every scheme', () {
      expect(plan.xdgMimeArguments, [
        'default',
        'youkomix-url-handler.desktop',
        'x-scheme-handler/youkomix',
      ]);
    });

    test('escapes reserved characters in the executable path', () {
      const plan = LinuxProtocolRegistrationPlan(
        schemes: ['youkomix'],
        executable: r'/opt/my "apps"/$HOME/100%/Youko`Mix\bin',
        applicationsDir: '/tmp',
      );

      expect(plan.exec, r'"/opt/my \"apps\"/\$HOME/100%%/Youko\`Mix\\bin" %u');
    });
  });
}
