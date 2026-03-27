# Implementation Plan: CloudTAK QR Code Import

## Overview

Extend TAKAware's QR code scanning to recognize CloudTAK HTTPS URLs, download the referenced .zip data package with security constraints, prompt for a P12 password, import certificates and server preferences, and auto-configure the TAK server connection. Implementation is in Swift/SwiftUI targeting the existing Xcode project.

## Tasks

- [x] 1. Extend QRCodeParser with CloudTAK URL detection
  - [x] 1.1 Add QRCodeParseResult enum and parseExtended() static method to QRCodeParser.swift
    - Add `QRCodeParseResult` enum with cases: `.certificateEnrollment(CertificateEnrollmentParameters)`, `.cloudTAKURL(URL)`, `.invalid(String)`
    - Add `parseExtended()` instance method with three detection branches: iTAK comma-separated, ATAK JSON, HTTPS URL
    - Add static `parseExtended(_:)` method matching the existing `parse(_:)` pattern
    - Reject `http://` URLs with descriptive error message
    - Validate URL well-formedness (non-nil host) before returning `.cloudTAKURL`
    - Preserve existing `parse()` and static `parse(_:)` methods unchanged for backward compatibility
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [ ]* 1.2 Write property test for URL scheme detection (Property 1)
    - **Property 1: URL scheme determines parse result**
    - **Validates: Requirements 1.1, 1.2**

  - [ ]* 1.3 Write property test for backward compatibility (Property 2)
    - **Property 2: Existing QR code formats are preserved**
    - **Validates: Requirements 1.3, 1.4**

  - [ ]* 1.4 Write property test for URL well-formedness (Property 3)
    - **Property 3: URL well-formedness validation**
    - **Validates: Requirements 1.5**

- [x] 2. Create DataPackageDownloader with security constraints
  - [x] 2.1 Create DataPackageDownloader.swift in TAKAware/Communications/
    - Define `DownloadError` enum with cases: `httpError(statusCode:)`, `networkError(Error)`, `invalidFileFormat`, `urlExpired`, `fileTooLarge(Int64)`, `timeout`, `httpRedirectBlocked(String)`, `tooManyRedirects` — each with `LocalizedError` conformance and `errorDescription`
    - Define `DownloadStatus` enum with cases: `.idle`, `.downloading(progress: Double)`, `.completed(URL)`, `.failed(DownloadError)`
    - Create `DataPackageDownloader` class as `NSObject, ObservableObject, URLSessionDownloadDelegate, URLSessionTaskDelegate`
    - Implement `download(from:) async throws -> URL` — creates URLSession with 60s timeout, downloads to `NSTemporaryDirectory()/{UUID}.zip` with file permissions `0o600`
    - Implement `URLSessionTaskDelegate` redirect handler: reject non-HTTPS redirects, enforce max 5 redirects
    - Implement `URLSessionDownloadDelegate` progress handler: enforce 50 MB cap, publish progress via `@Published var status`
    - Implement `cleanup()` to delete temp .zip file
    - Implement `static sweepOrphanedTempFiles()` to delete all .zip files in NSTemporaryDirectory()
    - Validate HTTP status codes: 403 → "URL expired" hint, other 4xx/5xx → include status code in error
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 7.1, 7.2, 7.3, 9.4, 9.5, 9.6, 11.1, 11.2, 11.3, 13.1, 13.3, 13.4_

  - [ ]* 2.2 Write property test for HTTP error status codes (Property 4)
    - **Property 4: HTTP error status codes appear in error messages**
    - **Validates: Requirements 2.5**

  - [ ]* 2.3 Write property test for HTTPS-only enforcement (Property 9)
    - **Property 9: HTTPS-only download enforcement**
    - **Validates: Requirements 9.4**

  - [ ]* 2.4 Write property test for download size limit (Property 10)
    - **Property 10: Download size limit enforcement**
    - **Validates: Requirements 9.5**

  - [ ]* 2.5 Write property test for redirect scheme enforcement (Property 15)
    - **Property 15: Redirect scheme enforcement**
    - **Validates: Requirements 11.2, 11.3**

  - [ ]* 2.6 Write property test for temp file cleanup (Property 6)
    - **Property 6: Temp file cleanup on terminal states**
    - **Validates: Requirements 7.1, 7.2, 13.3**

  - [ ]* 2.7 Write property test for temp file retention during retry (Property 7)
    - **Property 7: Temp file retained during password retry**
    - **Validates: Requirements 8.5, 13.2**

- [x] 3. Add new file to Xcode project and checkpoint
  - [x] 3.1 Write a Python script to add DataPackageDownloader.swift to project.pbxproj
    - Add PBXFileReference entry for DataPackageDownloader.swift
    - Add PBXBuildFile entry referencing the file reference
    - Add file reference to the Communications PBXGroup children list
    - Add build file to the main target PBXSourcesBuildPhase
    - Use existing entries (e.g. ChannelManager.swift) as format reference
    - Run the script to update project.pbxproj

- [x] 4. Extend TAKDataPackageParser with password parameter and zip safety
  - [x] 4.1 Add parse(p12Password:) method to TAKDataPackageParser.swift
    - Add new `parse(p12Password: Data)` method that accepts password as `Data` instead of relying on `DataPackageContents.userCertificatePassword`
    - Override the password in `DataPackageContents` with the provided `Data` buffer before calling `storeUserCertificate` and `storeServerCertificate`
    - Add `zeroPasswordBuffer(_ buffer: inout Data)` utility using `withUnsafeMutableBytes` + `memset_s`-equivalent zeroing
    - Call `zeroPasswordBuffer` in a defer block after import completes (success or failure)
    - Add zip safety checks: path traversal detection (canonical path must start with extraction dir), reject absolute paths, reject symlinks, 250 MB uncompressed limit, 1000 entry limit
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 12.1, 12.2_

  - [ ]* 4.2 Write property test for path traversal protection (Property 11)
    - **Property 11: Path traversal protection**
    - **Validates: Requirements 10.1, 10.2, 10.3**

  - [ ]* 4.3 Write property test for symlink rejection (Property 12)
    - **Property 12: Symlink rejection**
    - **Validates: Requirements 10.4**

  - [ ]* 4.4 Write property test for uncompressed size limit (Property 13)
    - **Property 13: Uncompressed size limit**
    - **Validates: Requirements 10.5**

  - [ ]* 4.5 Write property test for entry count limit (Property 14)
    - **Property 14: Entry count limit**
    - **Validates: Requirements 10.6**

  - [ ]* 4.6 Write property test for password buffer zeroing (Property 16)
    - **Property 16: Password buffer zeroing after import**
    - **Validates: Requirements 12.2**

- [x] 5. Checkpoint - Ensure all core components compile
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Update ConnectionOptions with CloudTAK import flow
  - [x] 6.1 Update CertEnrollmentScreen in ConnectionOptions.swift
    - Add state variables: `isShowingHostConfirmation`, `cloudTAKURL`, `isShowingPasswordPrompt`, `p12PasswordInput`, `downloadedZipURL`, `isDownloading`, `downloadProgress`, `importStatusMessage`
    - Add `@StateObject var downloader = DataPackageDownloader()`
    - Update `processQRCode` to call `QRCodeParser.parseExtended()` instead of `QRCodeParser.parse()`
    - Handle `.cloudTAKURL(url)`: set `cloudTAKURL`, show hostname confirmation alert
    - Handle `.certificateEnrollment(params)`: preserve existing behavior
    - Handle `.invalid(message)`: show error alert with the message
    - Add hostname confirmation `.alert` — shows "Download configuration from {hostname}?" with Confirm/Cancel
    - On confirm: call `downloader.download(from:)` async, show progress indicator
    - On download success: show P12 password prompt with `SecureField`, `.autocorrectionDisabled(true)`, `.textContentType(.password)`
    - Add password prompt explanation text: "Enter the password set when generating the configuration file in CloudTAK"
    - On password submit: convert string to `Data`, clear string, call `TAKDataPackageParser.parse(p12Password:)`
    - On wrong password: show error, re-prompt (zip stays on disk for retry)
    - On success: set `SettingsStore.global.takServerChanged = true`, show success alert, cleanup temp files, dismiss
    - On cancel at any point: cleanup temp files
    - Prevent double-download while in progress
    - _Requirements: 2.2, 5.1, 5.2, 5.3, 5.4, 5.5, 6.1, 6.2, 6.3, 6.4, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 9.1, 9.2, 9.3, 12.1, 12.3, 13.2_

  - [ ]* 6.2 Write property test for password non-persistence (Property 8)
    - **Property 8: Password non-persistence after import**
    - **Validates: Requirements 8.6, 12.3**

  - [ ]* 6.3 Write property test for preference extraction (Property 5)
    - **Property 5: Preference extraction round trip**
    - **Validates: Requirements 4.1, 4.2, 4.3, 4.4**

- [x] 7. Add startup sweep to TAKAwareApp
  - [x] 7.1 Call DataPackageDownloader.sweepOrphanedTempFiles() in TAKAwareApp.swift
    - Add `DataPackageDownloader.sweepOrphanedTempFiles()` call in the `init()` method of `TAKTrackerApp`
    - _Requirements: 13.3, 13.4_

- [x] 8. Final checkpoint - Build, fix errors, ensure all tests pass
  - Build with xcodebuild to verify compilation
  - Fix any compile errors
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The design uses Swift, so all implementation is in Swift/SwiftUI
- New .swift files must be added to project.pbxproj via Python script
- Property tests validate universal correctness properties from the design document
