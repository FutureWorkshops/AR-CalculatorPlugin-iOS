//
//  SceneDelegate.swift
//  Calculator
//
//

import UIKit

/// The core App Rail Plugin SDK must be imported.
import MobileWorkflowCore

/// Your plugin is then imported.
import CalculatorPlugin

/// This `SceneDelegate` defines your plugin's sample app. i.e. an app for testing and demonstrating your plugin's capabilities.
class SceneDelegate: MWSceneDelegate {
    
    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        /// This is your opportunity to modify the default set of dependencies that the app will refer to.
        
        /// Here you can specify the `appId`.
        /// If not provided, the default value is the app's bundle identifier.
        // self.dependencies.appId = "my_appId"
        
        /// Here you should list your plugin and any other plugins that your app requires.
        self.dependencies.plugins = [
            CalculatorPluginStruct.self
        ]
        
        /// Here you can specify an alternative `FileManager`, otherwise `FileManager.default` is used.
        //self.dependencies.fileManager = MyFileManager()

        /// Here you can specify an alternative object conforming to `CredentialStoreProtocol`.
        /// If not specified, an instance of `CredentialStore` is used.
        //self.dependencies.credentialStore = MyCredentialStore()

        /// Here you can specify an alternative object conforming to `EventService` protocol, which allows routing of app events to your steps.
        /// If not specified, an instance of `EventServiceImplementation` is used.
        //self.dependencies.eventService = MyEventService()

        /// Here you can provide additional objects conforming to `AsyncTaskService`, which will be available to your steps via `StepServices`.
        /// The default list includes an instance of `AuthenticationService`, which it is recommended to preserve unless you need to define a different authentication flow.
        /*
        self.dependencies.asyncServices.append(contentsOf: [
            MyAsyncService()
        ])
        */

        /// Here you can provide an instance of `QueueControllerNetworkAsyncTaskService` if your app needs to perform background network tasks.
        /// If not specified, the app will use default handling for network tasks.
        //self.dependencies.queueController = QueueControllerNetworkAsyncTaskService()

        /// Here you can provide your own `ResponseError` type for decoding server errors into display errors.
        /// The default list includes an instance of `SimpleResponseError`.
        /*
		self.dependencies.responseErrorTypes = [
            MyResponseError.Type
        ]
        */

        /// This call to `super` should occur after you have modified the `dependencies` that will be required by your app and plugin.
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    /// This function allows the developer to dictate what is the desired order in which the app configuration will be loaded. For example, the app may try
    /// to load the configuration from a local cache and, if fail, tries to load the configuration from the device bundle:
    ///
    /// ```
    /// override func preferredConfigurations(urlContexts: Set<UIOpenURLContext>) -> [AppConfigurationContext] {
    ///    var preferredConfigurations = [AppConfigurationContext]()
    ///    preferredConfigurations.append(.cached())
    ///    if let filePath = self.bundleJSONPath {
    ///        preferredConfigurations.append(.file(path: filePath, serverId: 2567))
    ///    }
    ///    return preferredConfigurations
    /// }
    /// ```
    ///
    /// The `bundleJSONPath` is a default variable that points to the file `app.json` in the app bundle.
    /// The `serverId: 2567`, in this example, tells the application to look for a server with id 2567 in the `app.json` configuration. This is the server that will
    /// be used as a reference. The server id can be found in the `app.json` in the key `server`, similar to:
    ///
    /// ```
    /// "servers":[{
    ///    "id": 2005,
    ///    "url": "https://example.domain.com"
    /// }],
    ///```
    ///
    ///
    /// The available configuration context options are:
    /// * `AppConfigurationContext.cached`: It attempts to load any configuration pre-loaded into the device (either from Bundle or download)
    /// * `AppConfigurationContext.remote`: Tells the SDK to perform a network request to download the configuration from the internet
    /// * `AppConfigurationContext.file`: Tries to load the configuration from a local file. Either the app Bundle or another file stored in the device
    ///
    /// - Parameter urlContexts: URL context available when the app will be launch
    /// - Returns: An array of `AppConfigurationContext` objects listing all avaliable options that the app can use to load configurations.
    override func preferredConfigurations(urlContexts: Set<UIOpenURLContext>) -> [AppConfigurationContext] {
        var preferredConfigurations = [AppConfigurationContext]()
        if let filePath = self.bundleJSONPath {
            preferredConfigurations.append(.file(path: filePath, serverId: nil))
        }
        return preferredConfigurations
    }
}
