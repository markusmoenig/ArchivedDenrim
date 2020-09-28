//
//  Leaves.swift
//  Denrim
//
//  Created by Markus Moenig on 19/9/20.
//

import Foundation

// Sets the current scene and initializes it
class SetScene: BehaviorNode
{
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "SetScene"
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if let mapName = options["map"] as? String {
            if let asset = game.assetFolder.getAsset(mapName, .Map) {
                if asset.map != nil {
                    asset.map?.clear()
                }
                if game.mapBuilder.compile(asset).error == nil {
                    if let map = asset.map {
                        if let sceneName = options["scene"] as? String {
                            if let scene = map.scenes[sceneName] {
                                game.currentMap = asset
                                game.currentScene = scene
                                map.setup(game: game)
                                // Add Game Behavior
                                let gameBehavior = MapBehavior(behavior: game.gameAsset!, name: "game", options: [:])
                                map.behavior["game"] = gameBehavior
                                return .Success
                            }
                        }
                    }
                }
            }
        }
        
        return .Failure
    }
}

// Calls a given tree
class Call: BehaviorNode
{
    var callContext         : BehaviorContext? = nil
    var treeName            : String? = nil
    
    var parameters          : [BehaviorVariable] = []

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Call"
    }
    
    override func verifyOptions(context: BehaviorContext, error: inout CompileError) {
        if options["tree"] as? String == nil {
            error.error = "Call requires a 'Tree' parameter"
        }
        
        if let value = options["variables"] as? String {
            let array = value.split(separator: ",")

            for v in array {
                let val = String(v.trimmingCharacters(in: .whitespaces))
                var foundVar : BehaviorVariable? = nil
                for variable in context.variables {
                    if variable.name == val {
                        foundVar = variable
                        break
                    }
                }
                if foundVar != nil {
                    parameters.append(foundVar!)
                } else {
                    error.error = "Variable '\(val)' not found"
                }
            }
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if callContext == nil {
            if let treeName = options["tree"] as? String {
                let treeArray = treeName.split(separator: ".")
                if treeArray.count == 1 {
                    // No ., tree has to be in the same context
                    callContext = context
                    self.treeName = treeName
                } else
                if treeArray.count == 2 {
                    var asset = game.assetFolder.getAsset(String(treeArray[0]), .Behavior)
                    if asset == nil && treeArray[0] == "game" {
                        asset = game.gameAsset
                    }
                    if let asset = asset {
                        if let context = asset.behavior {
                            callContext = context
                            self.treeName = String(treeArray[1])
                        }
                    }
                }
            }
        }
        
        if let context = callContext, treeName != nil {
            let storedVars = context.variables
            context.variables = parameters + context.variables
            let rc = context.execute(name: treeName!)
            context.variables = storedVars
            return rc
        }
        
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class IsKeyDown: BehaviorNode
{
    var keyCodes    : [Float:String] = [
        53: "Escape",

        50: "Back Quote",
        18: "1",
        19: "2",
        20: "3",
        21: "4",
        23: "5",
        22: "6",
        26: "7",
        28: "8",
        25: "9",
        29: "0",
        27: "-",
        24: "=",
        51: "Delete",

        48: "Tab",
        12: "Q",
        13: "W",
        14: "E",
        15: "R",
        17: "T",
        16: "Y",
        32: "U",
        34: "I",
        31: "O",
        35: "P",
        33: "[",
        30: "]",
        42: "\\",
        
//        57: "Caps Lock",
        0: "A",
        1: "S",
        2: "D",
        3: "F",
        5: "G",
        4: "H",
        38: "J",
        40: "K",
        37: "L",
        41: ";",
        39: ",",
        36: "Return",
        
        57: "Shift",
        6: "Z",
        7: "X",
        8: "C",
        9: "V",
        11: "B",
        45: "N",
        46: "M",
        43: "Comma",
        47: "Period",
        44: "/",
        60: "Shift",
        
        63: "fn",
        59: "Control",
        58: "Option",
        55: "Command",
        49: "Space",
//        55: "R. Command",
        61: "R. Option",
        
        123: "ArrowLeft",
        126: "ArrowUp",
        124: "ArrowRight",
        125: "ArrowDown",
    ]
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "IsKeyDown"
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if let key = options["key"] as? String {
            for k in game.view.keysDown {
                for (code, char) in keyCodes {
                    if code == k && char == key {
                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class Subtract: BehaviorNode
{
    var pair    : (UpTo4Data, UpTo4Data, [UpTo4Data])? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Subtract"
    }
    
    override func verifyOptions(context: BehaviorContext, error: inout CompileError) {
        pair = extractPair(options, variableName: "from", context: context, error: &error, optionalVariables: ["minimum"])
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if let pair = pair {
            if pair.0.int1 != nil {
                // Int
                pair.1.int1!.x -= pair.0.int1!.x
                if let min = pair.2[0].int1 {
                    pair.1.int1!.x = max(pair.1.int1!.x, min.x)
                }
                return .Success
            } else
            if pair.0.data1 != nil {
                // Float
                pair.1.data1!.x -= pair.0.data1!.x
                if let min = pair.2[0].data1 {
                    pair.1.data1!.x = max(pair.1.data1!.x, min.x)
                }
                return .Success
            } else
            if pair.0.data2 != nil {
                // Float2
                pair.1.data2!.x -= pair.0.data2!.x
                pair.1.data2!.y -= pair.0.data2!.y
                if let min = pair.2[0].data2 {
                    pair.1.data2!.x = max(pair.1.data2!.x, min.x)
                    pair.1.data2!.y = max(pair.1.data2!.y, min.y)
                }
                return .Success
            }
        }
        return .Failure
    }
}

class Add: BehaviorNode
{
    var pair    : (UpTo4Data, UpTo4Data, [UpTo4Data])? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Add"
    }
    
    override func verifyOptions(context: BehaviorContext, error: inout CompileError) {
        pair = extractPair(options, variableName: "to", context: context, error: &error, optionalVariables: ["maximum"])
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if let pair = pair {
            // Int
            if pair.0.int1 != nil {
                pair.1.int1!.x += pair.0.int1!.x
                if let max = pair.2[0].int1 {
                    pair.1.int1!.x = min(pair.1.int1!.x, max.x)
                }
                return .Success
            }
            // Float
            if pair.0.data1 != nil {
                pair.1.data1!.x += pair.0.data1!.x
                if let max = pair.2[0].data1 {
                    pair.1.data1!.x = min(pair.1.data1!.x, max.x)
                }
                return .Success
            }
            // Float2
            if pair.0.data2 != nil {
                pair.1.data2!.x += pair.0.data2!.x
                pair.1.data2!.y += pair.0.data2!.y
                if let max = pair.2[0].data2 {
                    pair.1.data2!.x = min(pair.1.data2!.x, max.x)
                    pair.1.data2!.y = min(pair.1.data2!.y, max.y)
                }
                return .Success
            }
        }
        return .Failure
    }
}

class Multiply: BehaviorNode
{
    var pair    : (UpTo4Data, UpTo4Data, [UpTo4Data])? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Multiply"
    }
    
    override func verifyOptions(context: BehaviorContext, error: inout CompileError) {
        pair = extractPair(options, variableName: "with", context: context, error: &error, optionalVariables: [])
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if let pair = pair {
            // Int
            if pair.0.int1 != nil {
                pair.1.int1!.x *= pair.0.int1!.x
                return .Success
            } else
            // Float
            if pair.0.data1 != nil {
                pair.1.data1!.x *= pair.0.data1!.x
                return .Success
            } else
            // Float2
            if pair.0.data2 != nil {
                pair.1.data2!.x *= pair.0.data2!.x
                pair.1.data2!.y *= pair.0.data2!.y
                return .Success
            }
        }
        return .Failure
    }
}

class IsVariable: BehaviorNode
{
    enum Mode {
        case GreaterThan, LessThan, Equal
    }
    
    var mode    : Mode = .Equal
    var pair    : (UpTo4Data, UpTo4Data, [UpTo4Data])? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "IsVariable"
    }
    
    override func verifyOptions(context: BehaviorContext, error: inout CompileError) {
        pair = extractPair(options, variableName: "variable", context: context, error: &error, optionalVariables: [])
        if error.error == nil {
            if var m = options["mode"] as? String {
                m = m.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
                if m == "GreaterThan" {
                    mode = .GreaterThan
                } else
                if m == "LessThan" {
                    mode = .LessThan
                } else { error.error = "'Mode' needs to be 'Equal', 'GreatherThan' or 'LessThan'" }
            } else { error.error = "Missing 'Mode' statement" }
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if let pair = pair {
            // Int
            if pair.0.int1 != nil {
                if mode == .Equal {
                    if pair.1.int1!.x == pair.0.int1!.x {
                        return .Success
                    }
                } else
                if mode == .GreaterThan {
                    if pair.1.int1!.x > pair.0.int1!.x {
                        return .Success
                    }
                } else
                if mode == .LessThan {
                    if pair.1.int1!.x < pair.0.int1!.x {
                        return .Success
                    }
                }
            } else
            // Float
            if pair.0.data1 != nil {
                if mode == .Equal {
                    if pair.1.data1!.x == pair.0.data1!.x {
                        return .Success
                    }
                } else
                if mode == .GreaterThan {
                    if pair.1.data1!.x > pair.0.data1!.x {
                        return .Success
                    }
                } else
                if mode == .LessThan {
                    if pair.1.data1!.x < pair.0.data1!.x {
                        return .Success
                    }
                }
            } else
            // Float2
            if pair.0.data2 != nil {
                if mode == .Equal {
                    if pair.1.data2!.x == pair.0.data2!.x && pair.1.data2!.y == pair.0.data2!.y {
                        return .Success
                    }
                } else
                if mode == .GreaterThan {
                    if pair.1.data2!.x > pair.0.data2!.x && pair.1.data2!.y > pair.0.data2!.y {
                        return .Success
                    }
                } else
                if mode == .LessThan {
                    if pair.1.data2!.x < pair.0.data2!.x && pair.1.data2!.y < pair.0.data2!.y {
                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}


