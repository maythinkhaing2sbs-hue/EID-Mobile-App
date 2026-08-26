import 'dart:io';

import 'package:eid_wallet/app.dart';
import 'package:eid_wallet/core/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Font loading does real file I/O, so it must happen in setUpAll — inside a
// testWidgets body the fake-async zone never completes it and the test hangs.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _fonts();
  });

  testWidgets('desktop viewport renders the phone mockup', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EidWalletApp());
    await tester.pump(const Duration(milliseconds: 900));

    await expectLater(
      find.byType(EidWalletApp),
      matchesGoldenFile('goldens/desktop-frame.png'),
    );
  });

  testWidgets('dark screen flips the mock status bar to light', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EidWalletApp());
    await tester.pump();
    final ctx = tester.element(find.byType(Navigator).last);
    Navigator.of(ctx).pushNamed(Routes.presentScan);
    // Fixed pumps, not pumpAndSettle: the scanner's sweep animation repeats
    // forever and would never settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await expectLater(
      find.byType(EidWalletApp),
      matchesGoldenFile('goldens/desktop-frame-dark.png'),
    );
  });

  testWidgets('narrow viewport bypasses the frame', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EidWalletApp());
    await tester.pump(const Duration(milliseconds: 900));

    await expectLater(
      find.byType(EidWalletApp),
      matchesGoldenFile('goldens/phone-unframed.png'),
    );
  });
}

Future<void> _fonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final p in paths) {
      loader.addFont(
          Future.value(ByteData.sublistView(await File(p).readAsBytes())));
    }
    await loader.load();
  }

  await load('NotoSerifMyanmar', [
    'assets/fonts/NotoSerifMyanmar-Regular.ttf',
    'assets/fonts/NotoSerifMyanmar-Medium.ttf',
    'assets/fonts/NotoSerifMyanmar-SemiBold.ttf',
    'assets/fonts/NotoSerifMyanmar-Bold.ttf',
  ]);
  await load('RobotoSlab', ['assets/fonts/RobotoSlab-Variable.ttf']);
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons =
        '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf';
    if (File(icons).existsSync()) await load('MaterialIcons', [icons]);
  }
}

// Appended: the dark screen must flip the simulated status bar to white.
