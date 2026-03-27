//
//  DataPackageDownloader.swift
//  TAKAware
//
//  Created by TAKAware on 2025.
//

import Foundation

enum DownloadError: Error, LocalizedError {
    case httpError(statusCode: Int)
    case networkError(Error)
    case invalidFileFormat
    case urlExpired
    case fileTooLarge(Int64)
    case timeout
    case httpRedirectBlocked(String)
    case tooManyRedirects
    case notHTTPS
    
    var errorDescription: String? {
        switch self {
        case .httpError(let statusCode):
            if statusCode == 403 {
                return "The download URL has expired. Please generate a new QR code in CloudTAK (HTTP \(statusCode))"
            }
            return "Download failed with status \(statusCode)"
        case .networkError(let error):
            return "Download failed: \(error.localizedDescription)"
        case .invalidFileFormat:
            return "The downloaded file is not a valid data package"
        case .urlExpired:
            return "The download URL has expired. Please generate a new QR code in CloudTAK"
        case .fileTooLarge(let size):
            let mb = size / (1024 * 1024)
            return "The data package exceeds the 50 MB size limit (\(mb) MB)"
        case .timeout:
            return "Download timed out after 60 seconds"
        case .httpRedirectBlocked(let url):
            return "Download blocked: redirect to non-HTTPS URL (\(url))"
        case .tooManyRedirects:
            return "Download failed: too many redirects"
        case .notHTTPS:
            return "Only HTTPS URLs are accepted for security reasons"
        }
    }
}

enum DownloadStatus {
    case idle
    case downloading(progress: Double)
    case completed(URL)
    case failed(DownloadError)
}

class CloudTAKDownloader: NSObject, ObservableObject {
    @Published var status: DownloadStatus = .idle
    
    static let maxDownloadSize: Int64 = 50 * 1024 * 1024  // 50 MB
    static let downloadTimeout: TimeInterval = 60
    static let maxRedirects: Int = 5
    static let tempSubdirectory = "com.takaware.pkg-import"
    
    private var redirectCount = 0
    private(set) var tempFileURL: URL?
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var downloadContinuation: CheckedContinuation<URL, Error>?
    private let continuationQueue = DispatchQueue(label: "com.takaware.downloader.continuation")
    
    func download(from url: URL) async throws -> URL {
        guard url.scheme?.lowercased() == "https" else {
            let error = DownloadError.notHTTPS
            await MainActor.run { status = .failed(error) }
            throw error
        }
        
        redirectCount = 0
        await MainActor.run { status = .downloading(progress: 0) }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Self.downloadTimeout
        config.timeoutIntervalForResource = Self.downloadTimeout
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuationQueue.sync {
                self.downloadContinuation = continuation
            }
            self.downloadTask = self.session?.downloadTask(with: url)
            self.downloadTask?.resume()
        }
    }
    
    func cancel() {
        downloadTask?.cancel()
        cleanup()
    }
    
    func cleanup() {
        if let url = tempFileURL {
            try? FileManager.default.removeItem(at: url)
            TAKLogger.debug("[CloudTAKDownloader] Cleaned up temp file: \(url.lastPathComponent)")
            tempFileURL = nil
        }
    }
    
    static func sweepOrphanedTempFiles() {
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(tempSubdirectory)
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: tempDir) else { return }
        for file in files where file.hasSuffix(".zip") {
            let path = (tempDir as NSString).appendingPathComponent(file)
            try? fm.removeItem(atPath: path)
            TAKLogger.debug("[CloudTAKDownloader] Swept orphaned temp file: \(file)")
        }
        // Remove subdirectory if empty
        if let remaining = try? fm.contentsOfDirectory(atPath: tempDir), remaining.isEmpty {
            try? fm.removeItem(atPath: tempDir)
        }
    }
    
    private func finishWithError(_ error: DownloadError) {
        Task { @MainActor in
            status = .failed(error)
        }
        continuationQueue.sync {
            downloadContinuation?.resume(throwing: error)
            downloadContinuation = nil
        }
        session?.finishTasksAndInvalidate()
        session = nil
    }
}

// MARK: - URLSessionTaskDelegate
extension CloudTAKDownloader: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        redirectCount += 1
        
        if redirectCount > Self.maxRedirects {
            completionHandler(nil)
            task.cancel()
            finishWithError(.tooManyRedirects)
            return
        }
        
        guard let redirectURL = request.url,
              redirectURL.scheme?.lowercased() == "https" else {
            let dest = request.url?.absoluteString ?? "unknown"
            completionHandler(nil)
            task.cancel()
            finishWithError(.httpRedirectBlocked(dest))
            return
        }
        
        completionHandler(request)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        // Only handle errors here if continuation hasn't been consumed yet
        let hasContinuation = continuationQueue.sync { downloadContinuation != nil }
        guard hasContinuation else { return }
        
        if (error as NSError).code == NSURLErrorTimedOut {
            finishWithError(.timeout)
        } else if (error as NSError).code == NSURLErrorCancelled {
            // Cancellation — continuation may already be consumed by redirect handler
            let stillHasContinuation = continuationQueue.sync { downloadContinuation != nil }
            if stillHasContinuation {
                finishWithError(.networkError(error))
            }
        } else {
            finishWithError(.networkError(error))
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension CloudTAKDownloader: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if totalBytesWritten > Self.maxDownloadSize {
            downloadTask.cancel()
            finishWithError(.fileTooLarge(totalBytesWritten))
            return
        }
        
        let progress: Double
        if totalBytesExpectedToWrite > 0 {
            progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        } else {
            progress = 0
        }
        Task { @MainActor in
            status = .downloading(progress: progress)
        }
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // Check HTTP status code
        if let httpResponse = downloadTask.response as? HTTPURLResponse {
            let statusCode = httpResponse.statusCode
            guard (200...299).contains(statusCode) else {
                finishWithError(.httpError(statusCode: statusCode))
                return
            }
        }
        
        // Move to a dedicated temp subdirectory
        let tempDir = (NSTemporaryDirectory() as NSString).appendingPathComponent(Self.tempSubdirectory)
        let fm = FileManager.default
        try? fm.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        
        let fileName = UUID().uuidString + ".zip"
        let destPath = (tempDir as NSString).appendingPathComponent(fileName)
        let destURL = URL(fileURLWithPath: destPath)
        
        do {
            try fm.moveItem(at: location, to: destURL)
            try fm.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: destPath
            )
        } catch {
            finishWithError(.networkError(error))
            return
        }
        
        tempFileURL = destURL
        Task { @MainActor in
            status = .completed(destURL)
        }
        continuationQueue.sync {
            downloadContinuation?.resume(returning: destURL)
            downloadContinuation = nil
        }
        self.session?.finishTasksAndInvalidate()
        self.session = nil
    }
}
