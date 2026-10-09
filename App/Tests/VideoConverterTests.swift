import Testing
import AVFoundation
import AnattiCore
@testable import Anatti

@Suite struct VideoConverterTests {
    private func spec(_ id: String) -> AssetSpec { SpecCatalog.appStorePreviews.first { $0.id == id }! }

    @Test func shortSilentVideoBecomesValidPreview() async throws {
        let source = try await TestVideo.make(seconds: 3, fps: 30)
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("out-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: source); try? FileManager.default.removeItem(at: output) }

        let target = PixelSize(886, 1920)
        let plan = try await VideoConverter.convert(source: source, target: target, to: output)
        #expect(plan.loops == 6 && plan.addsSilentAudio)

        let measured = try await VideoConverter.measure(output)
        #expect(measured.size == target)
        #expect(measured.isH264)
        #expect(measured.hasAudio)
        #expect(measured.frameRate <= 30.5)
        let issues = VideoValidator.validate(
            spec: spec("as.prev.iphone.di.medium"), size: measured.size, seconds: measured.seconds,
            frameRate: measured.frameRate, hasAudio: measured.hasAudio, format: .mp4, byteCount: measured.byteCount)
        #expect(issues.isEmpty, "\(issues) \(measured.seconds)s")
    }

    @Test func longVideoIsTrimmedAndFpsKept() async throws {
        let source = try await TestVideo.make(seconds: 40, fps: 10, width: 284, height: 160)
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("out-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: source); try? FileManager.default.removeItem(at: output) }

        let target = PixelSize(1920, 886)   // landscape target, fit with black bars
        let plan = try await VideoConverter.convert(source: source, target: target, fit: .fit, to: output)
        #expect(plan.frameRate == 10)
        let measured = try await VideoConverter.measure(output)
        #expect(measured.size == target)
        #expect(measured.seconds <= 30.05 && measured.seconds >= 29)
    }
}
