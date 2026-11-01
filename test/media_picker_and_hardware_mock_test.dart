import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/media_picker_helper.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockImagePickerPlatform mockPicker;

  setUp(() {
    mockPicker = MockImagePickerPlatform.setup();
  });

  tearDown(() {
    MockImagePickerPlatform.tearDown();
  });

  group('MediaPickerHelper & Hardware Camera Mock Tests', () {
    testWidgets('frontCameraOnly directly invokes front camera with preferredCameraDevice.front',
        (WidgetTester tester) async {
      XFile? selectedImage;
      mockPicker.mockResult = XFile('test/assets/mock_selfie.jpg');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MediaPickerHelper.showMediaSourceSheet(
                    context: context,
                    frontCameraOnly: true,
                    onImageSelected: (file) => selectedImage = file,
                  );
                },
                child: const Text('Capture Selfie'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Capture Selfie'));
      await tester.pumpAndSettle();

      // Verified: Invoked camera with front-facing lens directly without opening bottom sheet
      expect(mockPicker.callCount, equals(1));
      expect(mockPicker.lastSource, equals(ImageSource.camera));
      expect(mockPicker.lastCameraDevice, equals(CameraDevice.front));
      expect(selectedImage, isNotNull);
      expect(selectedImage!.path, equals('test/assets/mock_selfie.jpg'));
    });

    testWidgets('Normal picker displays bottom sheet and Back Camera option uses CameraDevice.rear',
        (WidgetTester tester) async {
      XFile? selectedImage;
      mockPicker.mockResult = XFile('test/assets/mock_fleet.jpg');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MediaPickerHelper.showMediaSourceSheet(
                    context: context,
                    frontCameraOnly: false,
                    onImageSelected: (file) => selectedImage = file,
                  );
                },
                child: const Text('Add Vehicle Photo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add Vehicle Photo'));
      await tester.pumpAndSettle();

      // Bottom sheet is visible
      expect(find.text('Select Media Source'), findsOneWidget);
      expect(find.text('Take Photo (Back Camera)'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);

      // Tap Take Photo (Back Camera)
      await tester.tap(find.text('Take Photo (Back Camera)'));
      await tester.pumpAndSettle();

      // Verified: Invoked camera with rear lens
      expect(mockPicker.callCount, equals(1));
      expect(mockPicker.lastSource, equals(ImageSource.camera));
      expect(mockPicker.lastCameraDevice, equals(CameraDevice.rear));
      expect(selectedImage, isNotNull);
      expect(selectedImage!.path, equals('test/assets/mock_fleet.jpg'));
    });

    testWidgets('Gallery option invokes ImageSource.gallery',
        (WidgetTester tester) async {
      XFile? selectedImage;
      mockPicker.mockResult = XFile('test/assets/mock_gallery.png');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MediaPickerHelper.showMediaSourceSheet(
                    context: context,
                    frontCameraOnly: false,
                    onImageSelected: (file) => selectedImage = file,
                  );
                },
                child: const Text('Upload Document'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Upload Document'));
      await tester.pumpAndSettle();

      // Tap Choose from Gallery
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();

      expect(mockPicker.callCount, equals(1));
      expect(mockPicker.lastSource, equals(ImageSource.gallery));
      expect(selectedImage, isNotNull);
      expect(selectedImage!.path, equals('test/assets/mock_gallery.png'));
    });

    testWidgets('User cancellation returns null without mutating existing file',
        (WidgetTester tester) async {
      XFile? selectedImage = XFile('existing/file.jpg');
      mockPicker.mockResult = null; // User cancelled

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MediaPickerHelper.showMediaSourceSheet(
                    context: context,
                    frontCameraOnly: true,
                    onImageSelected: (file) => selectedImage = file,
                  );
                },
                child: const Text('Cancel Test'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel Test'));
      await tester.pumpAndSettle();

      expect(mockPicker.callCount, equals(1));
      // Callback was not invoked with null to overwrite existing
      expect(selectedImage!.path, equals('existing/file.jpg'));
    });

    testWidgets('Remove Photo button is visible when hasExistingFile=true and sets photo to null',
        (WidgetTester tester) async {
      XFile? selectedImage = XFile('existing/photo.jpg');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MediaPickerHelper.showMediaSourceSheet(
                    context: context,
                    frontCameraOnly: false,
                    hasExistingFile: true,
                    onImageSelected: (file) => selectedImage = file,
                  );
                },
                child: const Text('Edit Photo'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Photo'), findsOneWidget);

      await tester.tap(find.text('Remove Photo'));
      await tester.pumpAndSettle();

      expect(selectedImage, isNull);
    });

    testWidgets('Platform exception during camera access is caught cleanly without crash',
        (WidgetTester tester) async {
      mockPicker.shouldThrow = true; // Simulates permission denied

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MediaPickerHelper.showMediaSourceSheet(
                    context: context,
                    frontCameraOnly: true,
                    onImageSelected: (_) {},
                  );
                },
                child: const Text('Permission Denied Test'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Permission Denied Test'));
      await tester.pumpAndSettle();

      // Zero unhandled exceptions
      expect(tester.takeException(), isNull);
      expect(mockPicker.callCount, equals(1));
    });
  });
}

