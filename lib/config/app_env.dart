class AppEnv {
  static const cloudinaryCloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const cloudinaryUploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
  static const stripePublishableKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  static const stripeBackendUrl = String.fromEnvironment('STRIPE_BACKEND_URL');

  static bool get isCloudinaryConfigured =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;

  static bool get isStripeConfigured =>
      stripePublishableKey.startsWith('pk_test_') &&
      stripeBackendUrl.startsWith('https://');
}
