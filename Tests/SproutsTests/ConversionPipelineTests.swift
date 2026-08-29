import AppKit
import ImageIO
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
}
