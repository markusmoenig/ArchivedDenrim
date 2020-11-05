//
//  BehaviorBuilder.swift
//  Denrim
//
//  Created by Markus Moenig on 18/9/20.
//

import Foundation

struct CompileError
{
    var asset           : Asset? = nil
    var line            : Int32? = nil
    var column          : Int32? = 0
    var error           : String? = nil
    var type            : String = "error"
}

class BehaviorNodeItem
{
    var name         : String
    var createNode   : (_ options: [String:Any]) -> BehaviorNode
    
    init(_ name: String, _ createNode: @escaping (_ options: [String:Any]) -> BehaviorNode)
    {
        self.name = name
        self.createNode = createNode
    }
}

class BehaviorBuilder
{
    var cursorTimer     : Timer? = nil
    let game            : Game
    
    var branches        : [BehaviorNodeItem] =
    [
        BehaviorNodeItem("repeat", { (_ options: [String:Any]) -> BehaviorNode in return RepeatBranch(options) }),
        BehaviorNodeItem("sequence", { (_ options: [String:Any]) -> BehaviorNode in return SequenceBranch(options) }),
        BehaviorNodeItem("selector", { (_ options: [String:Any]) -> BehaviorNode in return SelectorBranch(options) }),
        BehaviorNodeItem("while", { (_ options: [String:Any]) -> BehaviorNode in return WhileBranch(options) }),
    ]
    
    var leaves          : [BehaviorNodeItem] =
    [
        BehaviorNodeItem("SetScene", { (_ options: [String:Any]) -> BehaviorNode in return SetScene(options) }),
        BehaviorNodeItem("Call", { (_ options: [String:Any]) -> BehaviorNode in return Call(options) }),
        BehaviorNodeItem("StartTimer", { (_ options: [String:Any]) -> BehaviorNode in return StartTimer(options) }),
        BehaviorNodeItem("IsKeyDown", { (_ options: [String:Any]) -> BehaviorNode in return IsKeyDown(options) }),
        BehaviorNodeItem("GetTouchPos", { (_ options: [String:Any]) -> BehaviorNode in return GetTouchPos(options) }),
        BehaviorNodeItem("DistanceToShape", { (_ options: [String:Any]) -> BehaviorNode in return DistanceToShape(options) }),
        BehaviorNodeItem("ShapeContactCount", { (_ options: [String:Any]) -> BehaviorNode in return ShapeContactCount(options) }),
        BehaviorNodeItem("RandomColor", { (_ options: [String:Any]) -> BehaviorNode in return RandomColorNode(options) }),
        BehaviorNodeItem("Random", { (_ options: [String:Any]) -> BehaviorNode in return RandomNode(options) }),
        BehaviorNodeItem("Log", { (_ options: [String:Any]) -> BehaviorNode in return LogNode(options) }),

        BehaviorNodeItem("PlayAudio", { (_ options: [String:Any]) -> BehaviorNode in return PlayAudioNode(options) }),

        BehaviorNodeItem("Set", { (_ options: [String:Any]) -> BehaviorNode in return SetNode(options) }),
        BehaviorNodeItem("IsVariable", { (_ options: [String:Any]) -> BehaviorNode in return IsVariable(options) }),

        BehaviorNodeItem("CreateInstance2D", { (_ options: [String:Any]) -> BehaviorNode in return CreateInstance2D(options) }),
        BehaviorNodeItem("DestroyInstance2D", { (_ options: [String:Any]) -> BehaviorNode in return DestroyInstance2D(options) }),
        
        BehaviorNodeItem("SetVisible", { (_ options: [String:Any]) -> BehaviorNode in return SetVisible(options) }),
        BehaviorNodeItem("SetActive", { (_ options: [String:Any]) -> BehaviorNode in return SetActive(options) }),
        BehaviorNodeItem("SetLinearVelocity2D", { (_ options: [String:Any]) -> BehaviorNode in return SetLinearVelocity2D(options) }),

        BehaviorNodeItem("IsVisible", { (_ options: [String:Any]) -> BehaviorNode in return IsVisible(options) }),

        BehaviorNodeItem("ApplyTexture2D", { (_ options: [String:Any]) -> BehaviorNode in return ApplyTexture2D(options) }),

        BehaviorNodeItem("Multiply", { (_ options: [String:Any]) -> BehaviorNode in return Multiply(options) }),
        BehaviorNodeItem("Subtract", { (_ options: [String:Any]) -> BehaviorNode in return Subtract(options) }),
        BehaviorNodeItem("Add", { (_ options: [String:Any]) -> BehaviorNode in return Add(options) })
    ]
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    @discardableResult func compile(_ asset: Asset) -> CompileError
    {
        var error = CompileError()
        error.asset = asset
        
        func createError(_ errorText: String = "Syntax Error") {
            error.error = errorText
        }
        
        if asset.behavior == nil {
            asset.behavior = BehaviorContext(game)
        } else {
            asset.behavior!.clear()
        }
        
        let ns = asset.value as NSString
        var lineNumber  : Int32 = 0
        
        var currentTree     : BehaviorTree? = nil
        var currentBranch   : [BehaviorNode] = []
        var lastLevel       : Int = -1

        ns.enumerateLines { (str, _) in
            if error.error != nil { return }
            error.line = lineNumber
            
            //
            
            var processed = false
            var leftOfComment : String

            if str.firstIndex(of: "#") != nil {
                let split = str.split(separator: "#")
                if split.count == 2 {
                    leftOfComment = String(str.split(separator: "#")[0])
                } else {
                    leftOfComment = ""
                }
            } else {
                leftOfComment = str
            }
            
            // Get the current indention level
            let level = (str.prefix(while: {$0 == " "}).count) / 4

            leftOfComment = leftOfComment.trimmingCharacters(in: .whitespaces)
            
            // If empty, bail out, nothing todo
            if leftOfComment.count == 0 {
                lineNumber += 1
                return
            }
            
            // Drop the last branch when indention decreases
            if level < lastLevel {
                let levelsToDrop = lastLevel - level
                //print("dropped at line", error.line, "\"", str, "\"", level, levelsToDrop)
                for _ in 0..<levelsToDrop {
                    currentBranch = currentBranch.dropLast()
                }
            }
            
            var variableName : String? = nil
            // --- Check for variable assignment
            let values = leftOfComment.split(separator: "=")
            if values.count == 2 {
                variableName = String(values[0]).trimmingCharacters(in: .whitespaces)
                leftOfComment = String(values[1])
            }

            if leftOfComment.count > 0 {
                let arguments = leftOfComment.split(separator: " ", omittingEmptySubsequences: true)
                if arguments.count > 0 {
                    //print(level, arguments)
                    
                    let cmd = arguments[0].trimmingCharacters(in: .whitespaces)
                    if cmd == "tree" {
                        if arguments.count >= 2 {
                            let name = arguments[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)

                            if CharacterSet.letters.isSuperset(of: CharacterSet(charactersIn: name)) {
                                if level == 0 {
                                    currentTree = BehaviorTree(name)
                                    asset.behavior!.trees.append(currentTree!)
                                    currentBranch = []
                                    processed = true
                                    asset.behavior!.lines[error.line!] = "tree"

                                    // Rest of the parameters are incoming variables
                                    
                                    if arguments.count > 2 {
                                        var variablesString = ""
                                        
                                        for index in 2..<arguments.count {
                                            var string = arguments[index].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
                                            string = string.replacingOccurrences(of: ">", with: "<")
                                            variablesString += string
                                        }
                                        
                                        var rightValueArray = variablesString.split(separator: "<")
                                        while rightValueArray.count > 1 {
                                            let possibleVar = rightValueArray[0].lowercased()
                                            let varName = String(rightValueArray[1])
                                            if CharacterSet.letters.isSuperset(of: CharacterSet(charactersIn: varName)) {
                                                if possibleVar == "int" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Int1(0)))
                                                } else
                                                if possibleVar == "bool" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Bool1()))
                                                } else
                                                if possibleVar == "float" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Float1(0)))
                                                } else
                                                if possibleVar == "float2" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Float2(0,0)))
                                                } else
                                                if possibleVar == "float3" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Float3(0,0,0)))
                                                } else
                                                if possibleVar == "float4" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Float4(0,0,0,0)))
                                                }
                                            } else { error.error = "Invalid variable '\(varName)'" }
                                            
                                            rightValueArray = Array(rightValueArray.dropFirst(2))
                                        }
                                    }
                                }
                            } else { error.error = "Invalid name for tree '\(name)'" }
                        } else { error.error = "No name given for tree" }
                    } else {
                        var rightValueArray : [String.SubSequence]
                            
                        if leftOfComment.firstIndex(of: "<") != nil {
                            rightValueArray = leftOfComment.split(separator: "<")
                        } else {
                            rightValueArray = leftOfComment.split(separator: " ")
                        }
                        
                        if rightValueArray.count > 0 {
                            
                            let possbibleCmd = String(rightValueArray[0]).trimmingCharacters(in: .whitespaces)
                            
                            if variableName == nil {
                                
                                // Looking for branch
                                for branch in self.branches {
                                    if branch.name == possbibleCmd {
                                        
                                        // Build options
                                        var nodeOptions : [String:String] = [:]
                                        var no = leftOfComment.split(separator: " ")
                                        no.removeFirst()
                                        
                                        for s in no {
                                            let ss = String(s)
                                            nodeOptions[ss] = ss
                                        }

                                        let newBranch = branch.createNode(nodeOptions)
                                        newBranch.verifyOptions(context: asset.behavior!, tree: currentTree!, error: &error)
                                        if error.error == nil {                                            
                                            if currentBranch.count == 0 {
                                                currentTree?.leaves.append(newBranch)
                                                currentBranch.append(newBranch)
                                                
                                                newBranch.lineNr = error.line!
                                                asset.behavior!.lines[error.line!] = newBranch.name
                                            } else {
                                                if let branch = currentBranch.last {
                                                    branch.leaves.append(newBranch)
                                                    
                                                    newBranch.lineNr = error.line!
                                                    asset.behavior!.lines[error.line!] = newBranch.name
                                                }
                                                currentBranch.append(newBranch)
                                            }
                                            processed = true
                                        }
                                    }
                                }
                                
                                if processed == false {
                                    // Looking for leave
                                    for leave in self.leaves {
                                        if leave.name == possbibleCmd {
                                            
                                            var options : [String: String] = [:]
                                            
                                            // Fill in options
                                            rightValueArray.removeFirst()
                                            if rightValueArray.count == 1 && rightValueArray[0] == ">" {
                                                // Empty Arguments
                                            } else {
                                                while rightValueArray.count > 0 {
                                                    let array = rightValueArray[0].split(separator: ":")
                                                    //print("2", array)
                                                    rightValueArray.removeFirst()
                                                    if array.count == 2 {
                                                        let optionName = array[0].lowercased().trimmingCharacters(in: .whitespaces)
                                                        var values = array[1].trimmingCharacters(in: .whitespaces)
                                                        //print("option", optionName, "value", values)
                                                                                            
                                                        if values.count > 0 && values.last! != ">" {
                                                            createError("No closing '>' for option '\(optionName)'")
                                                        } else {
                                                            values = String(values.dropLast())
                                                        }
                                                        options[optionName] = String(values)
                                                    } else { createError(); rightValueArray = [] }
                                                }
                                            }
                                            
                                            let nodeOptions = self.parser_processOptions(options, &error)
                                            if error.error == nil {
                                                if let branch = currentBranch.last {
                                                    let behaviorNode = leave.createNode(nodeOptions)
                                                    behaviorNode.verifyOptions(context: asset.behavior!, tree: currentTree!, error: &error)
                                                    if error.error == nil {
                                                        behaviorNode.lineNr = error.line!
                                                        branch.leaves.append(behaviorNode)
                                                        asset.behavior!.lines[error.line!] = behaviorNode.name
                                                        processed = true
                                                    }
                                                } else { createError("Leaf node without active branch") }
                                            }
                                        }
                                    }
                                }
                            } else
                            if rightValueArray.count > 1 {
                                // Variable
                                asset.behavior!.lines[error.line!] = "Variable"
                                let possibleVariableType = rightValueArray[0].trimmingCharacters(in: .whitespaces)
                                if possibleVariableType == "Float4" {
                                    rightValueArray.removeFirst()
                                    let array = rightValueArray[0].split(separator: ",")
                                    if array.count == 4 {
                                        
                                        let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
                                        let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
                                        let z : Float; if let v = Float(array[2].trimmingCharacters(in: .whitespaces)) { z = v } else { z = 0 }
                                        let w : Float; if let v = Float(array[3].dropLast().trimmingCharacters(in: .whitespaces)) { w = v } else { w = 0 }

                                        let value = Float4(x, y, z, w)
                                        asset.behavior!.addVariable(variableName!, value)
                                        processed = true
                                    } else { createError() }
                                } else
                                if possibleVariableType == "Float3" {
                                    rightValueArray.removeFirst()
                                    let array = rightValueArray[0].split(separator: ",")
                                    if array.count == 3 {
                                        
                                        let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
                                        let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
                                        let z : Float; if let v = Float(array[2].trimmingCharacters(in: .whitespaces)) { z = v } else { z = 0 }

                                        let value = Float3(x, y, z)
                                        asset.behavior!.addVariable(variableName!, value)
                                        processed = true
                                    } else { createError() }
                                } else
                                if possibleVariableType == "Float2" {
                                    rightValueArray.removeFirst()
                                    let array = rightValueArray[0].split(separator: ",")
                                    if array.count == 2 {
                                        
                                        let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
                                        let y : Float; if let v = Float(array[1].dropLast().trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }

                                        let value = Float2(x, y)
                                        asset.behavior!.addVariable(variableName!, value)
                                        processed = true
                                    } else { createError() }
                                } else
                                if possibleVariableType == "Float" {
                                    rightValueArray.removeFirst()
                                    let value : Float; if let v = Float(rightValueArray[0].dropLast().trimmingCharacters(in: .whitespaces)) { value = v } else { value = 0 }
                                    asset.behavior!.addVariable(variableName!, Float1(value))
                                    processed = true
                                } else
                                if possibleVariableType == "Int" {
                                    rightValueArray.removeFirst()
                                    let value : Int; if let v = Int(rightValueArray[0].dropLast().trimmingCharacters(in: .whitespaces)) { value = v } else { value = 0 }
                                    asset.behavior!.addVariable(variableName!, Int1(value))
                                    processed = true
                                } else
                                if possibleVariableType == "Bool" {
                                    rightValueArray.removeFirst()
                                    let value : Bool; if let v = Bool(rightValueArray[0].dropLast().trimmingCharacters(in: .whitespaces)) { value = v } else { value = false }
                                    asset.behavior!.addVariable(variableName!, Bool1(value))
                                    processed = true
                                } else
                                if possibleVariableType == "Text" {
                                    rightValueArray.removeFirst()
                                    let v = String(rightValueArray[0].dropLast().trimmingCharacters(in: .whitespaces))
                                    asset.behavior!.addVariable(variableName!, TextRef(v))
                                    processed = true
                                } else { error.error = "Unrecognized Variable type '\(possbibleCmd)'" }
                            }
                        }
                    }
                }
                if str.trimmingCharacters(in: .whitespaces).count > 0 && processed == false && error.error == nil {
                    error.error = "Unrecognized statement"
                }
            }
            
            lastLevel = level
            lineNumber += 1
        }
        
        if game.state == .Idle {
            if error.error != nil {
                error.line = error.line! + 1
                game.scriptEditor?.setError(error)
            } else {
                game.scriptEditor?.clearAnnotations()
            }
        }

        return error
    }
    
    func parser_processOptions(_ options: [String:String],_ error: inout CompileError) -> [String:Any]
    {
        //print("Processing Options", options)

        var res: [String:Any] = [:]
        
        for(name, value) in options {
            res[name] = value
        }
        
        return res
    }
    
    func startTimer(_ asset: Asset)
    {
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: 0.2,
                                             target: self,
                                             selector: #selector(self.cursorCallback),
                                             userInfo: asset,
                                             repeats: true)
            self.cursorTimer = timer
        })
    }
    
    func stopTimer(_ asset: Asset)
    {
        if cursorTimer != nil {
            cursorTimer?.invalidate()
            cursorTimer = nil
        }
    }
    
    @objc func cursorCallback(_ timer: Timer) {
        if game.state == .Idle && game.scriptEditor != nil {
            game.scriptEditor!.getSessionCursor({ (line) in
                if let asset = timer.userInfo as? Asset {
                    if let context = asset.behavior {
                        if let name = context.lines[line] {
                            if name != self.game.contextKey {
                                if let helpText = self.game.scriptEditor!.getBehaviorHelpForKey(name) {
                                    self.game.contextText = helpText
                                    self.game.contextKey = name
                                    self.game.contextTextChanged.send(self.game.contextText)

                                }
                            }
                        } else {
                            if self.game.contextKey != "BehaviorHelp" {
                                self.game.contextText = self.game.scriptEditor!.behaviorHelpText
                                self.game.contextKey = "BehaviorHelp"
                                self.game.contextTextChanged.send(self.game.contextText)
                            }
                        }
                    }
                }
            })
        }
    }
}
