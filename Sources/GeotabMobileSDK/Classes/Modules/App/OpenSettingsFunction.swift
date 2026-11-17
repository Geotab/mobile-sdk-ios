import Foundation

/// Lets the web app open the Settings page of the running app, so it can send people to the phone settings it tells them
/// to change. The web app chooses nothing: the page is the one the system names, and anything the web app sends is
/// ignored.
class OpenSettingsFunction: ModuleFunction {
    static let functionName: String = "openSettings"

    /// How long the system gets to answer before the web app is told that the request failed.
    static let answerTimeoutSeconds: TimeInterval = 5

    private let openURL: URLOpener
    let executer: any AsyncMainExecuterAdapter

    init(
        module: AppModule,
        openURL: @escaping URLOpener = AppSettings.openInSystem,
        executer: any AsyncMainExecuterAdapter = MainExecuter()
    ) {
        self.openURL = openURL
        self.executer = executer
        super.init(module: module, name: Self.functionName)
    }

    override func handleJavascriptCall(argument: Any?, jsCallback: @escaping (Result<String, any Error>) -> Void) {
        let failure: Result<String, any Error> = .failure(GeotabDriveErrors.AppModuleError(error: "Could not open the app settings"))
        guard let settingsURL = AppSettings.url else {
            jsCallback(failure)
            return
        }

        // The system is not documented to always call its completion, or to call it only once. The web app gets one answer:
        // the first of the completion and the timeout, and the other is dropped.
        var answered = false
        func answer(_ result: Result<String, any Error>) {
            guard !answered else { return }
            answered = true
            jsCallback(result)
        }
        openURL(settingsURL) { opened in
            answer(opened ? .success("undefined") : failure)
        }
        executer.after(Self.answerTimeoutSeconds) {
            answer(failure)
        }
    }
}
