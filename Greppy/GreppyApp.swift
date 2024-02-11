//
//  GreppyApp.swift
//  Greppy
//
//  Created by Roberto Viola on 11/02/24.
//

import SwiftUI

@main
struct GreppyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var openedURL: URL?
}

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    AppState.shared.openedURL = url
    // Qui puoi gestire il file aperto con l'URL del file
    // Ad esempio, potresti volerlo aprire in una vista specifica
    return true
}


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Crea la ContentView e usa l'oggetto di stato condiviso
        let contentView = ContentView().environmentObject(AppState.shared)

        // Usa una UIWindowScene per configurare e allegare la finestra
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
