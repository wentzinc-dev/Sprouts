import AppKit
import ColorSync
import ImageIO
import SDWebImageWebPCoder
import UniformTypeIdentifiers
import XCTest
@testable import Sprouts

final class ConversionPipelineTests: XCTestCase {
    func testInspectionUsesImagePropertiesForDimensions() throws {
        let source = try makePNG(width: 8, height: 6)
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        var options = ExportOptions()
        options.percentage = 200
        options.allowsUpscaling = true

        let inspection = InputInspector.inspect(urls: [source], options: options)

        XCTAssertEqual(inspection.fileCount, 1)
        XCTAssertEqual(inspection.outputImageCount, 1)
        XCTAssertEqual(inspection.upscaleImageCount, 1)
    }

    func testCancelledConversionDoesNotStartTheNextFile() async throws {
        let source = try makePNG(width: 8, height: 6)
        let destination = source.deletingLastPathComponent().appendingPathComponent("output")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let task = Task {
            try await FileConverter().convert(
                inputURL: source,
                destinationURL: destination,
                options: ExportOptions(),
                sequence: OutputSequence(),
                isJapanese: false,
                progress: { _, _ in }
            )
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("A cancelled conversion must not write a file.")
        } catch is CancellationError {
            XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        }
    }

    func testWebPExportStillWritesWebPData() async throws {
        let source = try makePNG(width: 8, height: 6)
        let destination = source.deletingLastPathComponent().appendingPathComponent("output")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        var options = ExportOptions()
        options.format = .webp
        let outputs = try await FileConverter().convert(
            inputURL: source,
            destinationURL: destination,
            options: options,
            sequence: OutputSequence(),
            isJapanese: false,
            progress: { _, _ in }
        )

        let output = try XCTUnwrap(outputs.first)
        let data = try Data(contentsOf: output)
        XCTAssertEqual(output.pathExtension.lowercased(), "webp")
        XCTAssertEqual(String(decoding: data.prefix(4), as: UTF8.self), "RIFF")
    }

    func testAdobeRGBMatchSourcePreservesProfileForEveryOutputFormatWithoutResizing() async throws {
        let source = try makeAdobeRGBImage(format: .png)
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        for format in [ExportFormat.jpg, .png, .tiff, .webp] {
            let output = try await convertAdobeRGBSource(source, format: format, percentage: 100, embedsProfile: true)
            if format == .webp {
                try XCTAssertAdobeRGBProfile(webPICCProfile(in: try Data(contentsOf: output)))
            } else {
                try XCTAssertAdobeRGB(at: output)
            }
            if format == .jpg {
                let image = try XCTUnwrap(imageAt(output))
                XCTAssertEqual(image.bitsPerComponent, 8)
                XCTAssertFalse(image.alphaInfo == .premultipliedFirst || image.alphaInfo == .premultipliedLast)
            }
        }
    }

    func testAdobeRGBAutomaticResizePreservesProfile() async throws {
        let source = try makeAdobeRGBImage(format: .png)
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        for format in [ExportFormat.jpg, .png, .tiff, .webp] {
            let output = try await convertAdobeRGBSource(source, format: format, percentage: 50, embedsProfile: true)
            let image = try XCTUnwrap(format == .webp ? webPImageAt(output) : imageAt(output))
            XCTAssertEqual(image.width, 16)
            XCTAssertEqual(image.height, 12)
            if format == .webp {
                try XCTAssertAdobeRGBProfile(webPICCProfile(in: try Data(contentsOf: output)))
            } else {
                try XCTAssertAdobeRGB(at: output)
            }
        }
    }

    func testWebPEmbedColorProfileToggle() async throws {
        let source = try makeAdobeRGBImage(format: .png)
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let embedded = try await convertAdobeRGBSource(source, format: .webp, percentage: 100, embedsProfile: true)
        let unembedded = try await convertAdobeRGBSource(source, format: .webp, percentage: 100, embedsProfile: false)
        try XCTAssertAdobeRGBProfile(webPICCProfile(in: try Data(contentsOf: embedded)))
        XCTAssertNil(webPICCProfile(in: try Data(contentsOf: unembedded)))
        let unembeddedImage = try XCTUnwrap(webPImageAt(unembedded))
        XCTAssertEqual(unembeddedImage.width, 32)
        XCTAssertEqual(unembeddedImage.height, 24)
    }

    func testGeneratedAdobeRGBInputFixturesKeepTheirProfiles() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("SproutsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        for format in [ExportFormat.jpg, .png, .tiff, .webp] {
            let source = try makeAdobeRGBImage(format: format, folder: folder)
            if format == .webp {
                try XCTAssertAdobeRGBProfile(webPICCProfile(in: try Data(contentsOf: source)))
            } else {
                try XCTAssertAdobeRGB(at: source)
            }
        }
    }

    private func makePNG(width: Int, height: Int) throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("SproutsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("source.png")
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try XCTUnwrap(context.makeImage())
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return url
    }

    private func makeAdobeRGBImage(format: ExportFormat, folder: URL? = nil) throws -> URL {
        let folder = try folder ?? makeTemporaryFolder()
        let url = folder.appendingPathComponent("source.\(format.rawValue)")
        let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.adobeRGB1998))
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 32, height: 24, bitsPerComponent: 8, bytesPerRow: 32 * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(colorSpace: colorSpace, components: [0.85, 0.18, 0.1, 1])!)
        context.fill(CGRect(x: 0, y: 0, width: 32, height: 24))
        let image = try XCTUnwrap(context.makeImage())
        if format == .webp {
            let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            let data = try XCTUnwrap(SDImageWebPCoder.shared.encodedData(with: nsImage, format: .webP, options: nil))
            try data.write(to: url)
        } else {
            let type: CFString = switch format {
            case .jpg: UTType.jpeg.identifier as CFString
            case .png: UTType.png.identifier as CFString
            case .tiff: UTType.tiff.identifier as CFString
            case .webp: fatalError("handled above")
            }
            let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, type, 1, nil))
            CGImageDestinationAddImage(destination, image, nil)
            XCTAssertTrue(CGImageDestinationFinalize(destination))
        }
        return url
    }

    private func convertAdobeRGBSource(_ source: URL, format: ExportFormat, percentage: Int, embedsProfile: Bool) async throws -> URL {
        let destination = source.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        var options = ExportOptions()
        options.format = format
        options.colorProfile = .matchSource
        options.percentage = percentage
        options.allowsUpscaling = true
        options.embedsColorProfile = embedsProfile
        let outputs = try await FileConverter().convert(
            inputURL: source, destinationURL: destination, options: options,
            sequence: OutputSequence(), isJapanese: false, progress: { _, _ in }
        )
        return try XCTUnwrap(outputs.first)
    }

    private func makeTemporaryFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("SproutsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func imageAt(_ url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func webPImageAt(_ url: URL) -> CGImage? {
        guard let data = try? Data(contentsOf: url),
              let image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil) else { return nil }
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    private func XCTAssertAdobeRGB(at url: URL, file: StaticString = #filePath, line: UInt = #line) throws {
        let image = try XCTUnwrap(imageAt(url), file: file, line: line)
        try XCTAssertAdobeRGBProfile(
            image.colorSpace?.copyICCData() as Data?,
            file: file,
            line: line
        )
    }

    private func XCTAssertAdobeRGBProfile(
        _ data: Data?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let profile = try XCTUnwrap(data, file: file, line: line)
        var error: Unmanaged<CFError>?
        let colorSyncProfile = try XCTUnwrap(
            ColorSyncProfileCreate(profile as CFData, &error)?.takeRetainedValue(),
            error?.takeRetainedValue().localizedDescription ?? "Invalid ICC profile",
            file: file,
            line: line
        )
        let description = try XCTUnwrap(
            ColorSyncProfileCopyDescriptionString(colorSyncProfile)?.takeRetainedValue() as String?,
            file: file,
            line: line
        )
        XCTAssertEqual(description, "Adobe RGB (1998)", file: file, line: line)
    }

    private func webPICCProfile(in data: Data) -> Data? {
        guard data.count >= 12, data.prefix(4) == Data("RIFF".utf8), data.subdata(in: 8..<12) == Data("WEBP".utf8) else { return nil }
        var offset = 12
        while offset + 8 <= data.count {
            let name = data.subdata(in: offset..<(offset + 4))
            let length = Int(data[offset + 4]) | (Int(data[offset + 5]) << 8) | (Int(data[offset + 6]) << 16) | (Int(data[offset + 7]) << 24)
            let payloadStart = offset + 8
            let next = payloadStart + length + (length & 1)
            guard next <= data.count else { return nil }
            if name == Data("ICCP".utf8) { return data.subdata(in: payloadStart..<(payloadStart + length)) }
            offset = next
        }
        return nil
    }
}
