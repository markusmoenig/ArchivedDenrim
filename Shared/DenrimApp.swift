//
//  DenrimApp.swift
//  Shared
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI
import Combine

@main
struct DenrimApp: App {
        
    @StateObject var appState = AppState()

    private let exportCommand = PassthroughSubject<Void, Never>()

    var body: some Scene {
        DocumentGroup(newDocument: DenrimDocument()) { file in
            ContentView(document: file.$document)
                .onReceive(exportCommand) { _ in
                    print("test")
                    //file.document.beginExport()
                }
        }
        .commands {
            
            CommandGroup(replacing: .help) {
                Button(action: {
                    if appState.currentDocument != nil {
                        print("test")
                    }
                }) {
                    Text("Denrim Help")
                }
            }
            CommandMenu("Examples") {
                Button(action: {
                    exportCommand.send()
                }) {
                    Text("Pong")
                }
                //.keyboardShortcut("e", modifiers: .command)
            }
        }
    }
    
    private func createView(for file: FileDocumentConfiguration<DenrimDocument>) -> some View {
        appState.currentDocument = file.document
        return ContentView(document: file.$document)
    }
}

class AppState: ObservableObject {
    @Published var currentDocument: DenrimDocument?
}
