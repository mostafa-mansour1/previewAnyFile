// Type definitions for cordova-plugin-preview-any-file
// Add `/// <reference types="cordova-plugin-preview-any-file" />` (or list the package in tsconfig "types")
// to get `window.PreviewAnyFile` typed.

export type PreviewStatus = 'SUCCESS' | 'NO_APP';
export type PreviewCallbackStatus = PreviewStatus | 'CLOSING';

export interface PreviewOptions {
    /** File name to use, e.g. "report.pdf". Only the file name is used; folders are ignored. */
    name?: string;
    /** MIME type, e.g. "application/pdf". Needed when the path has no file extension. */
    mimeType?: string;
    /** HTTP headers for remote URLs, e.g. { Authorization: 'Bearer …' }. Not sent to other hosts after a redirect. */
    headers?: Record<string, string>;
    /** iOS only: hide Quick Look's share, save, print and markup buttons. UI only, not a security control. */
    disableShare?: boolean;
    /** Promise style only: called when the user closes the preview. */
    onClose?: () => void;
}

export interface PreviewAnyFile {
    /** Preview a file:// path, content:// URI (Android) or http(s) URL. Resolves when the preview opens. */
    previewPath(path: string, options?: PreviewOptions): Promise<PreviewStatus>;
    previewPath(
        success: (status: PreviewCallbackStatus) => void,
        error: (message: string) => void,
        path: string,
        options?: PreviewOptions
    ): void;

    /** Preview a base64 string or data: URL. */
    previewBase64(base64: string, options?: PreviewOptions): Promise<PreviewStatus>;
    previewBase64(
        success: (status: PreviewCallbackStatus) => void,
        error: (message: string) => void,
        base64: string,
        options?: PreviewOptions
    ): void;

    /** Preview a file bundled in the app's www folder, e.g. "/assets/manual.pdf". */
    previewAsset(path: string, options?: PreviewOptions): Promise<PreviewStatus>;
    previewAsset(
        success: (status: PreviewCallbackStatus) => void,
        error: (message: string) => void,
        path: string,
        options?: PreviewOptions
    ): void;

    /** Whether this device can show the file type, given a file name ("a.pdf") or MIME type ("application/pdf"). */
    canPreview(nameOrMimeType: string): Promise<boolean>;
    canPreview(success: (canPreview: boolean) => void, error: (message: string) => void, nameOrMimeType: string): void;

    /** @deprecated use previewPath */
    preview(path: string, success?: (status: PreviewCallbackStatus) => void, error?: (message: string) => void): void;
}

declare global {
    interface Window {
        PreviewAnyFile: PreviewAnyFile;
    }
}
