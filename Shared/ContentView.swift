//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI

#if os(OSX)
var toolbarPlacement1 : ToolbarItemPlacement = .automatic

#else
var toolbarPlacement1 : ToolbarItemPlacement = .navigationBarLeading
#endif

/*
struct BehaviorView: View {
    @State var document: DenrimDocument

    @State private var showBehaviorItems: Bool = true

    @State private var showGroups: Bool = true

    var body: some View {
        DisclosureGroup("Behavior", isExpanded: $showBehaviorItems) {
            
            ForEach(document.game.assetFolder.behaviorGroups, id: \.id) { group in
                DisclosureGroup(group.name, isExpanded: $showGroups) {
                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Behavior && asset.group == group.name {
                            Button(action: {
                                document.game.assetFolder.select(asset.id)
                                document.game.createPreview(asset)
                                //scriptIsVisible = true
                                //updateView.toggle()
                                document.game.updateView.send()
                            })
                            {
                                Text(asset.name)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(document.game.assetFolder.current!.id == asset.id ? Color.accentColor : Color.primary)
                        }
                    }
                }
            }
            
            ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                
                if asset.type == .Behavior && asset.group.isEmpty {
                    Button(action: {
                        document.game.assetFolder.select(asset.id)
                        document.game.createPreview(asset)
                        //scriptIsVisible = true
                        document.game.updateView.send()
                    })
                    {
                        Text(asset.name)
                    }
                    .contextMenu {
                        Button(action: {
                            // change country setting
                            asset.group = ""
                            document.game.updateView.send()
                        }) {
                            Text("None")
                        }
                        ForEach(document.game.assetFolder.behaviorGroups, id: \.id) { group in
                            Button(action: {
                                asset.group = group.name
                                print("jer", group.name)
                                document.game.updateView.send()
                            }) {
                                Text(group.name)
                                if asset.group == group.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(document.game.assetFolder.current!.id == asset.id ? Color.accentColor : Color.primary)
                }
            }
            // delete action
            .onDelete { indexSet in
                for index in indexSet {
                    if document.game.assetFolder.assets[index].name != "Game" {
                        document.game.assetFolder.assets.remove(at: index)
                    }
                }
            }
            // move action
            .onMove { indexSet, newOffset in
                document.game.assetFolder.assets.move(fromOffsets: indexSet, toOffset: newOffset)
                //updateView.toggle()
            }
        }
    }
}*/

struct ContentView: View {
    @Binding var document: DenrimDocument
    
    @State private var showAssetNamePopover: Bool = false
    @State private var assetName: String = ""

    @State private var updateView: Bool = false

    @State private var helpIsVisible: Bool = false
    @State private var helpText: String = ""

    @State private var imageIndex: Double = 0
    @State private var imageScale: Double = 1

    @State private var showDeleteAssetAlert: Bool = false

    @State private var showBehaviorItems: Bool = true
    @State private var showMapItems: Bool = false
    @State private var showShaderItems: Bool = false
    @State private var showImageItems: Bool = false
    @State private var showAudioItems: Bool = false

    @State private var rightSideBarIsVisible: Bool = true

    @State private var isImportingImages: Bool = false
    @State private var isImportingAudio: Bool = false
    @State private var isAddingImages: Bool = false
    
    @State private var showTemplates: Bool = true

    @State private var contextText: String = ""

    @Environment(\.colorScheme) var deviceColorScheme: ColorScheme

    var body: some View {
        HStack {
        NavigationView() {
            /*
            List(document.game.assetFolder.assets, id: \.id, children: \.children) { asset in
                //Image(systemName: row.icon)
                
                Button(action: {
                    document.game.assetFolder.select(asset.id)
                    document.game.createPreview(asset)
                    scriptIsVisible = true
                    updateView.toggle()
                })
                {
                    Text(asset.name)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
            }*/
            List {
                DisclosureGroup("Behavior", isExpanded: $showBehaviorItems) {
                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Behavior {
                            Button(action: {
                                document.game.assetFolder.select(asset.id)
                                document.game.createPreview(asset)
                                updateView.toggle()
                            })
                            {
                                Text(asset.name)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
                        }
                    }
                    // delete action
                    .onDelete { indexSet in
                        for index in indexSet {
                            if document.game.assetFolder.assets[index].name != "Game" {
                                document.game.assetFolder.assets.remove(at: index)
                            }
                        }
                    }
                    // move action
                    .onMove { indexSet, newOffset in
                        document.game.assetFolder.assets.move(fromOffsets: indexSet, toOffset: newOffset)
                        updateView.toggle()
                    }
                }
                DisclosureGroup("Map Files", isExpanded: $showMapItems) {
                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Map {
                            Button(action: {
                                document.game.assetFolder.select(asset.id)
                                document.game.createPreview(asset)
                                updateView.toggle()
                            })
                            {
                                Text(asset.name)

                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
                        }
                    }
                }
                DisclosureGroup("Shaders", isExpanded: $showShaderItems) {
                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Shader {
                            Button(action: {
                                document.game.assetFolder.select(asset.id)
                                document.game.createPreview(asset)
                                updateView.toggle()
                            })
                            {
                                Text(asset.name)

                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
                        }
                    }
                }
                DisclosureGroup("Image Groups", isExpanded: $showImageItems) {
                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Image {
                            Button(action: {
                                document.game.assetFolder.select(asset.id)
                                document.game.createPreview(asset)
                                imageIndex = Double(asset.dataIndex)
                                imageScale = asset.dataScale
                                updateView.toggle()
                            })
                            {
                                Text(asset.name)

                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
                        }
                    }
                }
                DisclosureGroup("Audio", isExpanded: $showAudioItems) {
                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Audio {
                            Button(action: {
                                document.game.assetFolder.select(asset.id)
                                document.game.createPreview(asset)
                                updateView.toggle()
                            })
                            {
                                Text(asset.name)

                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
                        }
                    }
                }
                //#endif
            }
            .frame(minWidth: 160, idealWidth: 200, maxWidth: 200)
            .layoutPriority(0)
            // Asset deletion
            .alert(isPresented: $showDeleteAssetAlert) {
                Alert(
                    title: Text("Do you want to remove the asset '\(document.game.assetFolder.current!.name)' ?"),
                    message: Text("This action cannot be undone!"),
                    primaryButton: .destructive(Text("Yes"), action: {
                        if let asset = document.game.assetFolder.current {
                            document.game.assetFolder.removeAsset(asset)
                            self.updateView.toggle()
                        }
                    }),
                    secondaryButton: .cancel(Text("No"), action: {})
                )
            }
            // Edit Asset name
            .popover(isPresented: self.$showAssetNamePopover,
                     arrowEdge: .top
            ) {
                VStack(alignment: .leading) {
                    Text("Name:")
                    TextField("Name", text: $assetName, onEditingChanged: { (changed) in
                        if let asset = document.game.assetFolder.current {
                            asset.name = assetName
                            self.updateView.toggle()
                        }
                    })
                    .frame(minWidth: 200)
                }.padding()
            }
            .toolbar {
                ToolbarItemGroup(placement: toolbarPlacement1) {
                    Menu {
                        Section(header: Text("Add Asset")) {
                            Menu("New Behavior") {
                                Button("Object 2D", action: {
                                    document.game.assetFolder.addBehaviorTree("New Object 2D")
                                    assetName = document.game.assetFolder.current!.name
                                    showAssetNamePopover = true
                                    updateView.toggle()
                                })
                            }
                            Button("New Map", action: {
                                document.game.assetFolder.addMap("New Map")
                                assetName = document.game.assetFolder.current!.name
                                showAssetNamePopover = true
                                updateView.toggle()
                            })
                            Button("New Shader", action: {
                                document.game.assetFolder.addShader("New Shader")
                                if let asset = document.game.assetFolder.current {
                                    assetName = document.game.assetFolder.current!.name
                                    showAssetNamePopover = true
                                    document.game.createPreview(asset)
                                }
                                updateView.toggle()
                            })
                            Button("New Image(s)", action: {
                                isImportingImages = true
                            })
                            Button("New Audio", action: {
                                isImportingAudio = true
                            })
                        }
                        Section(header: Text("Edit Asset")) {
                            // Optional toolbar items depending on asset
                            if let asset = document.game.assetFolder.current {
                                
                                Button(action: {
                                    assetName = String(asset.name.split(separator: ".")[0])
                                    showAssetNamePopover = true
                                })
                                {
                                    Label("Rename", systemImage: "pencil")//rectangle.and.pencil.and.ellipsis")
                                }
                                .disabled(asset.name == "Game")
                                
                                if asset.type == .Behavior || asset.type == .Shader || asset.type == .Map || asset.type == .Audio {
                                    Button(action: {
                                        showDeleteAssetAlert = true
                                    })
                                    {
                                        Label("Remove", systemImage: "minus")
                                    }
                                    .disabled(asset.name == "Game")
                                } else
                                if asset.type == .Image {
                                    Button(action: {
                                        isAddingImages = true
                                    })
                                    {
                                        Label("Add to Group", systemImage: "plus")
                                    }
                                    
                                    Button(action: {
                                        showDeleteAssetAlert = true
                                    })
                                    {
                                        Label("Remove Image Group", systemImage: "minus")
                                    }
                                    
                                    Button(action: {
                                        if let asset = document.game.assetFolder.current {
                                            asset.data.remove(at: Int(imageIndex))
                                        }
                                        updateView.toggle()
                                    })
                                    {
                                        Label("Remove Image", systemImage: "minus.circle")
                                    }
                                    .disabled(document.game.assetFolder.current == nil || document.game.assetFolder.current!.data.count < 2)
                                }
                            }
                        }
                    }
                    label: {
                        //Text("Asset")//.foregroundColor(Color.gray)
                        Label("Command", systemImage: "contextualmenu.and.cursorarrow")
                    }
                }

            }
            // Import Images
            .fileImporter(
                isPresented: $isImportingImages,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                do {
                    let selectedFiles = try result.get()
                    if selectedFiles.count > 0 {
                        document.game.assetFolder.addImages(selectedFiles[0].deletingPathExtension().lastPathComponent, selectedFiles)
                        assetName = document.game.assetFolder.current!.name
                        showAssetNamePopover = true
                        updateView.toggle()
                    }
                } catch {
                    // Handle failure.
                }
            }
            GeometryReader { geometry in
                ZStack(alignment: .topTrailing) {
                    ScrollView {

                        WebView(document.game, deviceColorScheme).tabItem {
                        }
                            .frame(height: geometry.size.height)
                            .tag(1)
                            .onChange(of: deviceColorScheme) { newValue in
                                document.game.scriptEditor?.setTheme(newValue)
                            }
                            .opacity(helpIsVisible ? 0 : 1)
                    }
                        .zIndex(0)
                        .frame(maxWidth: .infinity)
                        .layoutPriority(2)
                    MetalView(document.game)
                        .zIndex(2)
                        .frame(minWidth: 0,
                               maxWidth: geometry.size.width / document.game.previewFactor,
                               minHeight: 0,
                               maxHeight: geometry.size.height / document.game.previewFactor,
                               alignment: .topTrailing)
                        .opacity(helpIsVisible ? 0 : (document.game.state == .Running ? 1 : document.game.previewOpacity))
                        .animation(.default)
                        .allowsHitTesting(document.game.state == .Running)
                    
                    ScrollView {
                        ParmaView(text: $helpText)
                            .frame(minWidth: 0,
                                   maxWidth: .infinity,
                                   minHeight: 0,
                                   maxHeight: .infinity,
                                   alignment: .topLeading)
                            .padding(4)
                            .animation(.default)
                            .onReceive(self.document.game.helpTextChanged) { state in
                                helpText = self.document.game.helpText
                            }
                    }
                    .zIndex(4)//helpIsVisible ? 4 : -1)
                    .opacity(helpIsVisible ? 1 : 0)
                    .animation(.default)
                }
            }
            .layoutPriority(2)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                                    
                    // Game Controls
                    Button(action: {
                        document.game.stop()
                        document.game.start()
                        helpIsVisible = false
                        updateView.toggle()
                    })
                    {
                        Label("Run", systemImage: "play.fill")
                    }
                    .keyboardShortcut("r")
                    
                    Button(action: {
                        document.game.stop()
                        updateView.toggle()
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                    }.keyboardShortcut("t")
                    .disabled(document.game.state == .Idle)
                    
                    Button(action: {
                        if let scriptEditor = document.game.scriptEditor {
                            scriptEditor.activateDebugSession()
                        }
                    }) {
                        Label("Bug", systemImage: "ant.fill")
                    }.keyboardShortcut("b")
                    
                    Divider()
                        .padding(.horizontal, 20)
                        .opacity(0)
                    
                    Menu {
                        Section(header: Text("Preview")) {
                            Button("Small", action: {
                                document.game.previewFactor = 4
                                updateView.toggle()
                            })
                            .keyboardShortcut("1")
                            Button("Medium", action: {
                                document.game.previewFactor = 2
                                updateView.toggle()
                            })
                            .keyboardShortcut("2")
                            Button("Large", action: {
                                document.game.previewFactor = 1
                                updateView.toggle()
                            })
                            .keyboardShortcut("3")
                        }
                        Section(header: Text("Opacity")) {
                            Button("Opacity Off", action: {
                                document.game.previewOpacity = 0
                                updateView.toggle()
                            })
                            .keyboardShortcut("4")
                            Button("Opacity Half", action: {
                                document.game.previewOpacity = 0.5
                                updateView.toggle()
                            })
                            .keyboardShortcut("5")
                            Button("Opacity Full", action: {
                                document.game.previewOpacity = 1.0
                                updateView.toggle()
                            })
                            .keyboardShortcut("6")
                        }
                    }
                    label: {
                        //Text("Preview")
                        Label("View", systemImage: "viewfinder")
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                        .opacity(0)

                    Button(action: {
                        helpIsVisible.toggle()
                    }) {
                        //Text(!helpIsVisible ? "Help" : "Hide")
                        Label("Help", systemImage: "questionmark")
                    }
                    .keyboardShortcut("h")
                    
                    Button(action: { rightSideBarIsVisible.toggle() }, label: {
                        Image(systemName: "sidebar.right")
                    })
                }
            }
            .onReceive(self.document.game.gameError) { state in
                if let asset = self.document.game.assetError.asset {
                    document.game.assetFolder.select(asset.id)
                    document.game.scriptEditor?.setError(self.document.game.assetError, scrollToError: true)
                }
                self.updateView.toggle()
            }
            // Adding Images
            .fileImporter(
                isPresented: $isAddingImages,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                do {
                    let selectedFiles = try result.get()
                    if selectedFiles.count > 0 {
                        document.game.assetFolder.addImages(selectedFiles[0].deletingPathExtension().lastPathComponent, selectedFiles, existingAsset: document.game.assetFolder.current)

                        updateView.toggle()
                    }
                } catch {
                    // Handle failure.
                }
            }
        }
        if rightSideBarIsVisible == true {
            if helpIsVisible == true {
                HelpIndexView(document.game)
                    .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                    .layoutPriority(0)
                    .animation(.easeInOut)
            } else
            if let asset = document.game.assetFolder.current {
                ScrollView {
                    if asset.type == .Image {
                        VStack {
                            if document.game.assetFolder.current!.data.count > 1 {
                                Text("Index \(Int(imageIndex))")
                                Slider(value: $imageIndex, in: 0...Double(document.game.assetFolder.current!.data.count-1), step: 1) { pressed in
                                    asset.dataIndex = Int(imageIndex)
                                    document.game.assetFolder.createPreview()
                                }
                                .padding(.horizontal)
                            }
                            Text("Scale \(String(format: "%.02f", imageScale))")
                            Slider(value: $imageScale, in: 0.25...4, step: 0.25) { pressed in
                                asset.dataScale = imageScale
                                document.game.assetFolder.createPreview()
                            }
                            .padding(.horizontal)
                        }
                        .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                        .layoutPriority(0)
                        .animation(.easeInOut)
                    } else {
                        ParmaView(text: $contextText)
                            .frame(minWidth: 0,
                                   maxWidth: .infinity,
                                   minHeight: 0,
                                   maxHeight: .infinity,
                                   alignment: .bottomLeading)
                            .padding(4)
                            .onReceive(self.document.game.contextTextChanged) { text in
                                contextText = text//self.document.game.contextText
                            }
                            .foregroundColor(Color.gray)
                            .font(.system(size: 12))
                            .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                            .layoutPriority(0)
                            .animation(.easeInOut)
                    }
                }
                .animation(.easeInOut)
            }
        }
        }
        // Import Audio
        .fileImporter(
            isPresented: $isImportingAudio,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            do {
                let selectedFiles = try result.get()
                if selectedFiles.count > 0 {
                    document.game.assetFolder.addAudio(selectedFiles[0].deletingPathExtension().lastPathComponent, selectedFiles)
                    assetName = document.game.assetFolder.current!.name
                    showAssetNamePopover = true
                    updateView.toggle()
                }
            } catch {
                // Handle failure.
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(DenrimDocument()))
    }
}
