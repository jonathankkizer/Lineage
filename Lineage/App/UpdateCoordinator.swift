import AppKit
import Foundation

@MainActor
final class UpdateCoordinator {

    static let repositoryOwner = "jonathankkizer"
    static let repositoryName = "Lineage"
    static let checkInterval: TimeInterval = 7 * 24 * 60 * 60   // weekly
    static let scheduledCheckTickInterval: TimeInterval = 24 * 60 * 60   // re-evaluate due-ness daily

    private let checker: UpdateChecker
    private var prefs: UpdatePreferences
    private let alerts: UpdateAlertController

    private var isChecking = false
    private var dailyTickTimer: Timer?

    init(
        checker: UpdateChecker? = nil,
        prefs: UpdatePreferences = UpdatePreferences(),
        alerts: UpdateAlertController = UpdateAlertController()
    ) {
        self.checker = checker ?? UpdateChecker(
            owner: Self.repositoryOwner,
            repo: Self.repositoryName
        )
        self.prefs = prefs
        self.alerts = alerts
    }

    // MARK: - Lifecycle

    func start() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if !prefs.consentPromptShown {
                presentConsentPromptOnce()
            }
            runScheduledCheckIfDue()
        }
        scheduleDailyTick()
    }

    private func scheduleDailyTick() {
        dailyTickTimer?.invalidate()
        let timer = Timer(timeInterval: Self.scheduledCheckTickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.runScheduledCheckIfDue()
            }
        }
        timer.tolerance = 60 * 60
        RunLoop.main.add(timer, forMode: .common)
        dailyTickTimer = timer
    }

    // MARK: - Public surface

    func checkManually() {
        runCheck(isManual: true)
    }

    var isAutoCheckEnabled: Bool {
        prefs.autoCheckEnabled
    }

    func setAutoCheckEnabled(_ enabled: Bool) {
        prefs.autoCheckEnabled = enabled
        prefs.consentPromptShown = true
        if enabled {
            runScheduledCheckIfDue()
        }
    }

    // MARK: - Scheduling

    private func runScheduledCheckIfDue() {
        guard prefs.autoCheckEnabled, !isChecking else { return }
        if let last = prefs.lastCheckDate, Date().timeIntervalSince(last) < Self.checkInterval {
            return
        }
        guard NSApp.isActive else { return }   // never interrupt other apps
        runCheck(isManual: false)
    }

    private func presentConsentPromptOnce() {
        guard !prefs.consentPromptShown else { return }
        let choice = alerts.presentConsentPrompt()
        prefs.consentPromptShown = true
        prefs.autoCheckEnabled = (choice == .enable)
    }

    // MARK: - Core check

    private func runCheck(isManual: Bool) {
        guard !isChecking else { return }
        guard let currentVersion = Self.currentVersionString() else {
            if isManual { alerts.presentError(UpdateCheckError.noCurrentVersion) }
            return
        }
        isChecking = true

        Task { @MainActor in
            defer { isChecking = false }

            let status: UpdateStatus
            do {
                status = try await checker.checkForLatest(currentVersionString: currentVersion)
            } catch {
                if isManual { alerts.presentError(error) }
                return
            }

            prefs.lastCheckDate = Date()

            switch status {
            case .upToDate(let current):
                if isManual {
                    alerts.presentUpToDate(current: current)
                }
            case .updateAvailable(let latest, let current, let release):
                if !isManual, let skipped = prefs.skippedVersion,
                   let skippedVersion = SemanticVersion(skipped),
                   skippedVersion >= latest {
                    return   // user previously skipped this version
                }
                handleUpdateAvailable(
                    latest: latest,
                    current: current,
                    release: release,
                    isManual: isManual
                )
            }
        }
    }

    private func handleUpdateAvailable(
        latest: SemanticVersion,
        current: SemanticVersion,
        release: GitHubRelease,
        isManual: Bool
    ) {
        let choice = alerts.presentUpdateAvailable(
            latest: latest,
            current: current,
            release: release,
            offerSkip: !isManual
        )
        switch choice {
        case .viewRelease:
            // Defensive: htmlURL comes from the GitHub API response. We trust
            // api.github.com over HTTPS, but a scheme check guarantees we
            // never hand NSWorkspace a file:// or other non-web URL even if a
            // future code path widens this source.
            if release.htmlURL.scheme == "https" {
                NSWorkspace.shared.open(release.htmlURL)
            }
        case .skipVersion:
            prefs.skippedVersion = String(describing: latest)
        case .later:
            break
        }
    }

    // MARK: - Helpers

    static func currentVersionString() -> String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
