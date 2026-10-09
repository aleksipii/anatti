import Testing
@testable import AnattiCore

@Suite struct VideoPlannerTests {
    private func source(seconds: Double, fps: Double = 60, audio: Bool = true,
                        width: Double = 1170, height: Double = 2532) -> VideoSourceInfo {
        VideoSourceInfo(width: width, height: height, durationSeconds: seconds, frameRate: fps, hasAudio: audio)
    }
    private let target = PixelSize(886, 1920)

    @Test func longVideoIsTrimmed() throws {
        let plan = try VideoPlanner.plan(source: source(seconds: 90), target: target, fit: .fill)
        #expect(plan.loops == 1)
        #expect(plan.outputSeconds == VideoPlanner.maxOutputSeconds)
    }

    @Test func shortVideoLoopsToMinimum() throws {
        let plan = try VideoPlanner.plan(source: source(seconds: 4), target: target, fit: .fill)
        #expect(plan.loops == 4)
        #expect(plan.outputSeconds >= 15 && plan.outputSeconds <= 30)
    }

    @Test func inRangeVideoIsKept() throws {
        let plan = try VideoPlanner.plan(source: source(seconds: 20), target: target, fit: .fill)
        #expect(plan.loops == 1 && plan.outputSeconds == 20)
    }

    @Test func frameRateAndAudio() throws {
        let plan = try VideoPlanner.plan(source: source(seconds: 20, fps: 60, audio: false), target: target, fit: .fill)
        #expect(plan.frameRate == 30)
        #expect(plan.addsSilentAudio)
        let slow = try VideoPlanner.plan(source: source(seconds: 20, fps: 24), target: target, fit: .fill)
        #expect(slow.frameRate == 24 && !slow.addsSilentAudio)
    }

    @Test func rejectsBadSources() {
        #expect(throws: VideoPlanError.tooShort) { try VideoPlanner.plan(source: source(seconds: 0.5), target: target, fit: .fill) }
        #expect(throws: VideoPlanError.invalidSource) { try VideoPlanner.plan(source: source(seconds: 10, width: 0), target: target, fit: .fill) }
    }

    @Test func fillCoversAndFitContains() throws {
        let fill = try VideoPlanner.plan(source: source(seconds: 20), target: target, fit: .fill)
        #expect(fill.offsetX <= 1e-9 && fill.offsetY <= 1e-9)
        let fit = try VideoPlanner.plan(source: source(seconds: 20, width: 1920, height: 1080), target: target, fit: .fit)
        #expect(fit.offsetX >= 0 && fit.offsetY >= 0)
        #expect(fit.orientationMismatch)
    }

    @Test func validatorFlagsProblems() {
        let spec = SpecCatalog.appStorePreviews.first { $0.id == "as.prev.iphone.di.medium" }!
        let ok = VideoValidator.validate(spec: spec, size: target, seconds: 20, frameRate: 30,
                                         hasAudio: true, format: .mp4, byteCount: 10_000_000)
        #expect(ok.isEmpty)
        let bad = VideoValidator.validate(spec: spec, size: PixelSize(100, 100), seconds: 5, frameRate: 60,
                                          hasAudio: false, format: .png, byteCount: 600_000_000)
        #expect(Set(bad) == [.wrongSize, .tooShort, .frameRateTooHigh, .fileTooLarge(maxMB: 500), .noAudio, .unsupportedFormat])
    }

    @Test func plannedOutputAlwaysPassesValidator() throws {
        let spec = SpecCatalog.appStorePreviews.first { $0.id == "as.prev.iphone.di.medium" }!
        for seconds in [1.0, 3, 7.5, 14.9, 15, 15.05, 29.9, 30, 120] {
            let plan = try VideoPlanner.plan(source: source(seconds: seconds), target: target, fit: .fill)
            let issues = VideoValidator.validate(spec: spec, size: target, seconds: plan.outputSeconds,
                                                 frameRate: Double(plan.frameRate), hasAudio: true,
                                                 format: .mp4, byteCount: 1)
            #expect(issues.isEmpty, "\(seconds): \(issues)")
        }
    }

    @Test func level40SizeLimit() {
        for spec in SpecCatalog.appStorePreviews where spec.id != "as.prev.vision" {
            for size in spec.renderSizes { #expect(VideoLimits.fitsH264Level40(size), "\(size.label)") }
        }
        #expect(!VideoLimits.fitsH264Level40(PixelSize(3840, 2160)))
        #expect(ExportPlanner.videoRelativePath(size: target, index: 3) == "AppStore/Previews/886x1920/03.mp4")
    }
}
