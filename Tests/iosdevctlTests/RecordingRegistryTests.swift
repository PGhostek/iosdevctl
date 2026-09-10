import XCTest
@testable import iosdevctl

/// Regression tests for the `device record` PID bookkeeping.
///
/// The pid file used to be trusted on sight: `record start` refused to run
/// whenever the file existed and `record stop` SIGINT'd whatever number it held.
/// Nothing ever removed the file except a successful `stop`, so an interrupted
/// agent run — or the simulator shutting down, which makes `simctl recordVideo`
/// exit on its own — left the file behind indefinitely. From then on
/// `record start` answered RECORDING_ALREADY_IN_PROGRESS forever, and the
/// documented remedy (`record stop`) sent SIGINT to a PID macOS had long since
/// recycled onto an unrelated process, while reporting "Recording stopped."
final class RecordingRegistryTests: XCTestCase {

    private var tempDir: URL!
    private var savedProbe: ((Int32) -> String?)!

    override func setUp() {
        super.setUp()
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("iosdevctl-recording-tests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        savedProbe = RecordingRegistry.commandLineForPid
        RecordingRegistry.pidFilePath  = tempDir.appendingPathComponent("recording.pid").path
        RecordingRegistry.pathFilePath = tempDir.appendingPathComponent("recording-path.txt").path
    }

    override func tearDown() {
        RecordingRegistry.commandLineForPid = savedProbe
        RecordingRegistry.resetPathsToDefaults()
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private var pidFileExists: Bool {
        FileManager.default.fileExists(atPath: RecordingRegistry.pidFilePath)
    }

    private var pathFileExists: Bool {
        FileManager.default.fileExists(atPath: RecordingRegistry.pathFilePath)
    }

    // MARK: - isLiveRecording

    func test_isLiveRecording_deadPid_isNotOurs() {
        // `ps` reports nothing for a PID that no longer exists.
        XCTAssertFalse(RecordingRegistry.isLiveRecording(commandLine: nil))
    }

    func test_isLiveRecording_ourSimctlRecording_isOurs() {
        let cmd = "/usr/bin/xcrun simctl io 1234-ABCD recordVideo --force /tmp/demo.mov"
        XCTAssertTrue(RecordingRegistry.isLiveRecording(commandLine: cmd))
    }

    func test_isLiveRecording_recycledPid_isNotOurs() {
        // The bug that mattered: a live but unrelated process must never be signalled.
        XCTAssertFalse(RecordingRegistry.isLiveRecording(commandLine: "/usr/sbin/mDNSResponder"))
        XCTAssertFalse(RecordingRegistry.isLiveRecording(commandLine: "/bin/zsh -l"))
    }

    // MARK: - activePid

    func test_activePid_noPidFile_returnsNil() {
        RecordingRegistry.commandLineForPid = { _ in XCTFail("should not probe without a pid file"); return nil }
        XCTAssertNil(RecordingRegistry.activePid())
    }

    func test_activePid_livePidFile_returnsPidAndKeepsFiles() {
        RecordingRegistry.writePid(4242)
        RecordingRegistry.writePath("/tmp/demo.mov")
        RecordingRegistry.commandLineForPid = { pid in
            XCTAssertEqual(pid, 4242)
            return "/usr/bin/xcrun simctl io 1234 recordVideo --force /tmp/demo.mov"
        }

        XCTAssertEqual(RecordingRegistry.activePid(), 4242)
        XCTAssertTrue(pidFileExists, "a live recording's pid file must survive the check")
        XCTAssertEqual(RecordingRegistry.readPath(), "/tmp/demo.mov")
    }

    func test_activePid_stalePidFile_returnsNilAndClearsFiles() {
        // The wedge: process is gone, pid file was never cleaned up.
        RecordingRegistry.writePid(4242)
        RecordingRegistry.writePath("/tmp/demo.mov")
        RecordingRegistry.commandLineForPid = { _ in nil }

        XCTAssertNil(RecordingRegistry.activePid(), "a dead PID must not count as a recording")
        XCTAssertFalse(pidFileExists,  "stale pid file must be cleared, not left to wedge `record start`")
        XCTAssertFalse(pathFileExists, "stale path file must be cleared too")
    }

    func test_activePid_recycledPid_returnsNilAndClearsFiles() {
        RecordingRegistry.writePid(4242)
        RecordingRegistry.writePath("/tmp/demo.mov")
        RecordingRegistry.commandLineForPid = { _ in "/usr/sbin/mDNSResponder" }

        XCTAssertNil(RecordingRegistry.activePid(), "a recycled PID must not be reported as our recording")
        XCTAssertFalse(pidFileExists)
    }

    func test_readPid_garbageContent_returnsNil() {
        try? "not-a-pid".write(toFile: RecordingRegistry.pidFilePath, atomically: true, encoding: .utf8)
        XCTAssertNil(RecordingRegistry.readPid())
    }

    // MARK: - the real `ps` probe

    func test_defaultProbe_reportsNilForDeadPid_andCommandForLivePid() {
        let probe = RecordingRegistry.defaultCommandLineProbe

        // A process we ran to completion: its PID is dead by the time we ask.
        let corpse = Process()
        corpse.executableURL = URL(fileURLWithPath: "/usr/bin/true")
        try? corpse.run()
        corpse.waitUntilExit()
        XCTAssertNil(probe(corpse.processIdentifier), "ps must report nothing for an exited process")

        // Ourselves: definitely alive.
        let mine = probe(getpid())
        XCTAssertNotNil(mine, "ps must report a command line for a live process")
        XCTAssertFalse(mine?.isEmpty ?? true)
    }
}

/// Black-box regression: a stale pid file must not make `record stop` claim
/// success (and fire SIGINT at a recycled PID) instead of reporting that there
/// is nothing to stop. Uses the real /tmp paths the CLI reads, so it saves and
/// restores anything already there.
final class RecordStopStalePidCLITests: XCTestCase {

    private let pidPath  = "/tmp/iosdevctl-recording.pid"
    private let pathPath = "/tmp/iosdevctl-recording-path.txt"
    private var savedPid: String?
    private var savedPath: String?

    override func setUp() {
        super.setUp()
        savedPid  = try? String(contentsOfFile: pidPath,  encoding: .utf8)
        savedPath = try? String(contentsOfFile: pathPath, encoding: .utf8)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: pidPath)
        try? FileManager.default.removeItem(atPath: pathPath)
        if let savedPid  { try? savedPid.write(toFile: pidPath,   atomically: true, encoding: .utf8) }
        if let savedPath { try? savedPath.write(toFile: pathPath, atomically: true, encoding: .utf8) }
        super.tearDown()
    }

    func test_recordStop_withStalePidFile_reportsNoRecording() {
        // A PID that is guaranteed dead: run a process to completion and reuse its number.
        let corpse = Process()
        corpse.executableURL = URL(fileURLWithPath: "/usr/bin/true")
        try? corpse.run()
        corpse.waitUntilExit()
        let deadPid = corpse.processIdentifier

        try? "\(deadPid)".write(toFile: pidPath, atomically: true, encoding: .utf8)
        try? "/tmp/never-written.mov".write(toFile: pathPath, atomically: true, encoding: .utf8)

        let result = iosdevctl("device", "record", "stop")

        XCTAssertNotEqual(result.exitCode, 0, "stale pid file must not be reported as a stopped recording")
        XCTAssertEqual(result.jsonDict?["code"] as? String, "NO_RECORDING_IN_PROGRESS")
        XCTAssertFalse(FileManager.default.fileExists(atPath: pidPath),
                       "the stale pid file must be cleared so `record start` is not wedged")
    }
}
