//
//  PlaygroundBookExportManager.swift
//  PlaygroundStudio
//
//  Created by User on 21/11/25.
//

import Foundation
import AppKit


/// Manages exporting Playground Books and related assets.
final class PlaygroundBookExportManager {
    enum ExportError: Error, LocalizedError {
        case templateNotFound
        case copyFailed(underlying: Error)
        case zipNotFound
        case unzipFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .templateNotFound:
                return "Template folder not found in bundle. Ensure the Template folder is added to the target as a folder reference."
            case .copyFailed(let underlying):
                return "Failed to copy template: \(underlying.localizedDescription)"
            case .zipNotFound:
                return "Template.zip not found in bundle. Ensure Template.zip is added to the target resources."
            case .unzipFailed(let underlying):
                return "Failed to unzip template: \(underlying.localizedDescription)"
            }
        }
    }

    // The most recently exported/unzipped playground book root
    private(set) var currentBookRoot: URL?

    // Resolve an app-writable base directory in Application Support
    private func appSupportDirectory() throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(for: .applicationSupportDirectory,
                              in: .userDomainMask,
                              appropriateFor: nil,
                              create: true)
        let appFolder = base.appendingPathComponent("PlaygroundStudio", isDirectory: true)
        try fm.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder
    }

    /// Copies a folder named `templateFolderName` from the main bundle to `destinationURL`.
    /// - Parameters:
    ///   - templateFolderName: The folder name inside the bundle (no extension). Defaults to "Template".
    ///   - destinationURL: The destination directory where the folder will be copied to.
    ///   - replaceExisting: If true and a folder already exists at `destinationURL`, it will be removed first.
    func copyTemplateFolderFromBundle(
        templateFolderName: String = "Template",
        to destinationURL: URL,
        replaceExisting: Bool = true
    ) throws {
        let fm = FileManager.default

        // Locate the folder in the bundle. For folder references, this resolves to a directory URL.
        guard let sourceURL = Bundle.main.url(forResource: templateFolderName, withExtension: nil) else {
            throw ExportError.templateNotFound
        }

        // Ensure destination parent directory exists
        let parent = destinationURL.deletingLastPathComponent()
        try fm.createDirectory(at: parent, withIntermediateDirectories: true)

        // Remove existing destination if requested
        if fm.fileExists(atPath: destinationURL.path) {
            if replaceExisting {
                try fm.removeItem(at: destinationURL)
            } else {
                // If not replacing, nothing to do
                return
            }
        }

        do {
            try fm.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw ExportError.copyFailed(underlying: error)
        }
    }

    private func unzip(zipURL: URL, to destinationURL: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: destinationURL, withIntermediateDirectories: true)

        // Use system unzip in non-interactive, quiet mode to avoid blocking on prompts
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        // -o overwrite without prompting, -q quiet to reduce output (avoid pipe backpressure)
        process.arguments = ["-oq", zipURL.path, "-d", destinationURL.path]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let stdinPipe = Pipe() // provide empty stdin so unzip can't block on input
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = stdinPipe

        // Close the write end of stdin immediately (EOF), ensuring no interactive wait
        stdinPipe.fileHandleForWriting.closeFile()

        do {
            try process.run()
        } catch {
            throw ExportError.unzipFailed(underlying: error)
        }

        // Implement a timeout so we never wait indefinitely
        let timeoutSeconds: TimeInterval = 60
        let deadline = Date().addingTimeInterval(timeoutSeconds)

        // Poll for termination to allow a timeout
        while process.isRunning && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
        }

        if process.isRunning {
            // Timed out — terminate and surface an error
            process.terminate()
            let terminateDeadline = Date().addingTimeInterval(2)
            while process.isRunning && Date() < terminateDeadline {
                Thread.sleep(forTimeInterval: 0.05)
            }

            let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errData, encoding: .utf8) ?? ""
            let outMsg = String(data: outData, encoding: .utf8) ?? ""
            let combined = [errMsg, outMsg].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let underlying = NSError(
                domain: "PlaygroundBookExportManager.unzip",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: combined.isEmpty ? "unzip timed out after \(Int(timeoutSeconds))s" : combined]
            )
            throw ExportError.unzipFailed(underlying: underlying)
        }

        // Now the process has finished; capture output
        let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let errMsg = String(data: errData, encoding: .utf8) ?? ""
            let outMsg = String(data: outData, encoding: .utf8) ?? ""
            let combined = [errMsg, outMsg].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let underlying = NSError(
                domain: "PlaygroundBookExportManager.unzip",
                code: Int(process.terminationStatus),
                userInfo: [
                    NSLocalizedDescriptionKey: combined.isEmpty
                        ? "unzip failed with status \(process.terminationStatus)"
                        : combined
                ]
            )
            throw ExportError.unzipFailed(underlying: underlying)
        }

        // Optional: post-process verification to ensure results are visible on disk
        var attempts = 0
        while attempts < 20 {
            let contents = try? fm.contentsOfDirectory(at: destinationURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            if let contents, !contents.isEmpty {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)
            attempts += 1
        }
    }

    @discardableResult
    func duplicateTemplateBesideSource(
        templateFolderName: String = "Template",
        newFolderName: String = "Template Copy",
        replaceExisting: Bool = true
    ) throws -> URL {
        guard let zipURL = Bundle.main.url(forResource: "Template", withExtension: "zip") else {
            throw ExportError.zipNotFound
        }

        let fm = FileManager.default
        // Choose a writable base directory (Application Support/PlaygroundStudio)
        let writableBase = try appSupportDirectory()
        let destinationDir = writableBase.appendingPathComponent(newFolderName, isDirectory: true)

        if fm.fileExists(atPath: destinationDir.path) {
            if replaceExisting {
                try fm.removeItem(at: destinationDir)
            } else {
                return destinationDir
            }
        }
        try fm.createDirectory(at: destinationDir, withIntermediateDirectories: true)

        let destinationZip = destinationDir.appendingPathComponent("Template.zip")
        if fm.fileExists(atPath: destinationZip.path) {
            try fm.removeItem(at: destinationZip)
        }
        try fm.copyItem(at: zipURL, to: destinationZip)

        // Unzip into destination directory and remove the zip after successful extraction
        do {
            try unzip(zipURL: destinationZip, to: destinationDir)
            try? fm.removeItem(at: destinationZip)
        } catch {
            throw ExportError.unzipFailed(underlying: error)
        }

        // Locate and store the .playgroundbook root for subsequent operations
        do {
            let bookRoot = try locatePlaygroundBookRoot(in: destinationDir)
            self.currentBookRoot = bookRoot
        } catch {
            // If no .playgroundbook is found, keep currentBookRoot nil but still return the destination directory
            self.currentBookRoot = nil
        }
        currentBookRoot = destinationDir
        return destinationDir
    }

    // MARK: - Playground Book Utilities

    /// Attempts to locate a `.playgroundbook` root directory within the given directory.
    /// - Parameter directory: The directory to search.
    /// - Returns: URL to the first found `.playgroundbook` directory.
    func locatePlaygroundBookRoot(in directory: URL) throws -> URL {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        if let book = contents.first(where: { $0.pathExtension == "playgroundbook" }) {
            return book
        }
        // Optionally search one level deeper
        for url in contents {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey])
            if values.isDirectory == true {
                let subcontents = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
                if let book = subcontents.first(where: { $0.pathExtension == "playgroundbook" }) {
                    return book
                }
            }
        }
        throw NSError(domain: "PlaygroundBookExportManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No .playgroundbook found in \(directory.path)"]) 
    }

    /// Writes the provided Swift code into a page's Contents.swift, creating folders as needed.
    func writePageContents(bookRoot: URL, chapterName: String, pageName: String, contents: String) throws {
        let pageDir = pageDirectory(bookRoot: bookRoot, chapterName: chapterName, pageName: pageName)
        try FileManager.default.createDirectory(at: pageDir, withIntermediateDirectories: true)
        let contentsSwift = pageDir.appendingPathComponent("Contents.swift")
        guard let data = contents.data(using: .utf8) else {
            throw NSError(domain: "PlaygroundBookExportManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unable to encode contents as UTF-8"]) 
        }
        try data.write(to: contentsSwift, options: .atomic)
    }

    /// Adds a new page with a minimal Manifest.plist and initial Contents.swift.
    func addPage(bookRoot: URL, chapterName: String, pageName: String, initialCode: String = "// Welcome") throws {
        let fm = FileManager.default
        let chapterDir = chapterDirectory(bookRoot: bookRoot, chapterName: chapterName)
        let pagesDir = chapterDir.appendingPathComponent("Pages", isDirectory: true)
        let pageDir = pagesDir.appendingPathComponent("\(pageName).playgroundpage", isDirectory: true)

        try fm.createDirectory(at: pageDir, withIntermediateDirectories: true)

        // Minimal Manifest.plist for a page
        let manifestURL = pageDir.appendingPathComponent("Manifest.plist")
        let manifest: [String: Any] = [
            "Name": pageName,
            "Version": "1.0",
            "ContentVersion": "1.0"
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: manifest, format: .xml, options: 0)
        try plistData.write(to: manifestURL, options: .atomic)

        // Write initial Contents.swift
        let contentsURL = pageDir.appendingPathComponent("Contents.swift")
        guard let data = initialCode.data(using: .utf8) else {
            throw NSError(domain: "PlaygroundBookExportManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unable to encode initial code as UTF-8"]) 
        }
        try data.write(to: contentsURL, options: .atomic)
    }

    /// Adds or replaces a Swift file in Shared Playground Support/Sources.
    func addSharedSource(bookRoot: URL, fileName: String, code: String) throws {
        let fm = FileManager.default
        let sourcesDir = sharedSourcesDirectory(bookRoot: bookRoot)
        try fm.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
        let fileURL = sourcesDir.appendingPathComponent(fileName).appendingPathExtension("swift")
        guard let data = code.data(using: .utf8) else {
            throw NSError(domain: "PlaygroundBookExportManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unable to encode source code as UTF-8"]) 
        }
        try data.write(to: fileURL, options: .atomic)
    }

    /// Adds or replaces a resource file in Shared Playground Support/Resources.
    func addSharedResource(bookRoot: URL, resourceName: String, data: Data) throws {
        let fm = FileManager.default
        let resourcesDir = sharedResourcesDirectory(bookRoot: bookRoot)
        try fm.createDirectory(at: resourcesDir, withIntermediateDirectories: true)
        let resourceURL = resourcesDir.appendingPathComponent(resourceName)
        try data.write(to: resourceURL, options: .atomic)
    }

    // MARK: - Internal path helpers

    private func contentsDirectory(bookRoot: URL) -> URL {
        bookRoot.appendingPathComponent("Contents", isDirectory: true)
    }

    private func chaptersDirectory(bookRoot: URL) -> URL {
        contentsDirectory(bookRoot: bookRoot).appendingPathComponent("Chapters", isDirectory: true)
    }

    private func chapterDirectory(bookRoot: URL, chapterName: String) -> URL {
        chaptersDirectory(bookRoot: bookRoot).appendingPathComponent("\(chapterName).playgroundchapter", isDirectory: true)
    }

    private func pageDirectory(bookRoot: URL, chapterName: String, pageName: String) -> URL {
        chapterDirectory(bookRoot: bookRoot, chapterName: chapterName)
            .appendingPathComponent("Pages", isDirectory: true)
            .appendingPathComponent("\(pageName).playgroundpage", isDirectory: true)
    }

    private func sharedSupportDirectory(bookRoot: URL) -> URL {
        contentsDirectory(bookRoot: bookRoot).appendingPathComponent("Shared Playground Support", isDirectory: true)
    }

    private func sharedSourcesDirectory(bookRoot: URL) -> URL {
        sharedSupportDirectory(bookRoot: bookRoot).appendingPathComponent("Sources", isDirectory: true)
    }

    private func sharedResourcesDirectory(bookRoot: URL) -> URL {
        sharedSupportDirectory(bookRoot: bookRoot).appendingPathComponent("Resources", isDirectory: true)
    }

    // MARK: - Convenience APIs using currentBookRoot

    private func requireCurrentBookRoot() throws -> URL {
        if let url = currentBookRoot { return url }
        throw NSError(domain: "PlaygroundBookExportManager", code: 412, userInfo: [NSLocalizedDescriptionKey: "No current playground book is set. Call duplicateTemplateBesideSource(...) first or set currentBookRoot manually."])
    }

    func writePageContents(chapterName: String, pageName: String, contents: String) throws {
        let root = try requireCurrentBookRoot()
        try writePageContents(bookRoot: root, chapterName: chapterName, pageName: pageName, contents: contents)
    }

    func addPage(chapterName: String, pageName: String, initialCode: String = "// Welcome") throws {
        let root = try requireCurrentBookRoot()
        try addPage(bookRoot: root, chapterName: chapterName, pageName: pageName, initialCode: initialCode)
    }

    func addSharedSource(fileName: String, code: String) throws {
        let root = try requireCurrentBookRoot()
        try addSharedSource(bookRoot: root, fileName: fileName, code: code)
    }

    func addSharedResource(resourceName: String, data: Data) throws {
        let root = try requireCurrentBookRoot()
        try addSharedResource(bookRoot: root, resourceName: resourceName, data: data)
    }

    // MARK: - xcodebuild Helper
    private func runXcodeBuild(project: URL, scheme: String, configuration: String = "Release") throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = [
            "-project", project.path,
            "-scheme", scheme,
            "-configuration", configuration,
            "clean", "build",
            "-quiet"
        ]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw NSError(domain: "PlaygroundBookExportManager.xcodebuild", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start xcodebuild: \(error.localizedDescription)"])
        }

        process.waitUntilExit()

        let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let outMsg = String(data: outData, encoding: .utf8) ?? ""
        let errMsg = String(data: errData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            let combined = [errMsg, outMsg].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(domain: "PlaygroundBookExportManager.xcodebuild", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: combined.isEmpty ? "xcodebuild failed" : combined])
        }
    }

    // MARK: - Export TemplateSample and Save (no build)

    /// Copies TemplateSample.zip from the bundle, unzips it into a writable directory,
    /// locates the resulting .playgroundbook, and prompts the user to save it.
    /// - Parameters:
    ///   - newFolderName: Destination folder name under Application Support.
    ///   - replaceExisting: Whether to replace an existing destination folder.
    /// - Returns: The final saved .playgroundbook URL chosen by the user.
    @discardableResult
    func exportTemplateSampleAndSave(
        newFolderName: String = "TemplateSample Copy",
        replaceExisting: Bool = true
    ) throws -> URL {
        let fm = FileManager.default

        // 1) Copy and unzip TemplateSample.zip to a writable location
        guard let zipURL = Bundle.main.url(forResource: "TemplateSample", withExtension: "zip") else {
            throw ExportError.zipNotFound
        }

        let writableBase = try appSupportDirectory()
        let destinationDir = writableBase.appendingPathComponent(newFolderName, isDirectory: true)

        if fm.fileExists(atPath: destinationDir.path) {
            if replaceExisting {
                try fm.removeItem(at: destinationDir)
            }
        }
        try fm.createDirectory(at: destinationDir, withIntermediateDirectories: true)

        let destinationZip = destinationDir.appendingPathComponent("TemplateSample.zip")
        if fm.fileExists(atPath: destinationZip.path) {
            try fm.removeItem(at: destinationZip)
        }
        try fm.copyItem(at: zipURL, to: destinationZip)

        do {
            try unzip(zipURL: destinationZip, to: destinationDir)
            try? fm.removeItem(at: destinationZip)
        } catch {
            throw ExportError.unzipFailed(underlying: error)
        }

        // Locate the resulting .playgroundbook and store it
        let bookRoot = try locatePlaygroundBookRoot(in: destinationDir)
        self.currentBookRoot = bookRoot

        // 3) Ask user where to save and copy the .playgroundbook there
        let defaultName = bookRoot.deletingPathExtension().lastPathComponent
        let saveURL = try presentSavePanelForPlaygroundBook(defaultName: defaultName)
        if fm.fileExists(atPath: saveURL.path) {
            try fm.removeItem(at: saveURL)
        }
        try fm.copyItem(at: bookRoot, to: saveURL)
        return saveURL
    }

    // MARK: - Build TemplateSample to Desktop
    @discardableResult
    func buildTemplateSampleToDesktop(
        newFolderName: String = "TemplateSample Build",
        replaceExisting: Bool = true,
        configuration: String = "Debug"
    ) throws -> URL {
        let fm = FileManager.default

        // 1) Unzip TemplateSample.zip into a writable dir
        guard let zipURL = Bundle.main.url(forResource: "TemplateSample", withExtension: "zip") else {
            throw ExportError.zipNotFound
        }
        guard let downloadsBase = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "PlaygroundBookExportManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unable to resolve Downloads directory"])
        }
        let destinationDir = downloadsBase.appendingPathComponent(newFolderName, isDirectory: true)

        if fm.fileExists(atPath: destinationDir.path) {
            if replaceExisting {
                try fm.removeItem(at: destinationDir)
            }
        }
        try fm.createDirectory(at: destinationDir, withIntermediateDirectories: true)

        let destinationZip = destinationDir.appendingPathComponent("TemplateSample.zip")
        if fm.fileExists(atPath: destinationZip.path) {
            try fm.removeItem(at: destinationZip)
        }
        try fm.copyItem(at: zipURL, to: destinationZip)

        do {
            try unzip(zipURL: destinationZip, to: destinationDir)
            try? fm.removeItem(at: destinationZip)
        } catch {
            throw ExportError.unzipFailed(underlying: error)
        }

        // 2) Locate Xcode project: /TemplateSample/PlaygroundBook.xcodeproj
        let projectURL = destinationDir
            .appendingPathComponent("TemplateSample", isDirectory: true)
            .appendingPathComponent("PlaygroundBook.xcodeproj", isDirectory: true)

        guard fm.fileExists(atPath: projectURL.path) else {
            throw NSError(domain: "PlaygroundBookExportManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "PlaygroundBook.xcodeproj not found at \(projectURL.path)"])
        }

        // 3) Open the Xcode project automatically
        NSWorkspace.shared.open(projectURL)

        return projectURL
    }

    #if canImport(AppKit)
    /// Presents a save panel for choosing where to save the .playgroundbook.
    private func presentSavePanelForPlaygroundBook(defaultName: String) throws -> URL {
        let panel = NSSavePanel()
        panel.title = "Save Swift Playground Book"
        panel.nameFieldStringValue = defaultName + ".playgroundbook"
        panel.allowedFileTypes = ["playgroundbook"]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            throw NSError(domain: "PlaygroundBookExportManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Save cancelled"])
        }
        return url
    }
    #endif
}

