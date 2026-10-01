package com.mostafa.previewanyfile;

import androidx.core.content.FileProvider;

/**
 * Android keeps one provider record per class name. cordova-android, Capacitor and other plugins
 * also declare androidx.core.content.FileProvider, so sharing that class leaves this plugin's
 * authority unexported and viewer apps fail with "Permission Denial" (a blank document).
 */
public class PreviewAnyFileProvider extends FileProvider {
}
