//
//  Behavior.swift
//  Denrim
//
//  Created by Markus Moenig on 18/9/20.
//

import Foundation

class BehaviorNode {
    
    enum Result {
        case Success, Failure, Running, Unused
    }
    
    // Only applicable for branch nodes like a sequence
    var leaves              : [BehaviorNode] = []
    
    // Options
    var options             : [String:Any]
    
    init(_ options: [String:Any] = [:])
    {
        self.options = options
    }
    
    /// Executes a node inside a behaviour tree
    @discardableResult func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        return .Success
    }
}

class BehaviorTree  : BehaviorNode
{
    var name        : String
    
    init(_ name: String)
    {
        self.name = name
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        for leave in leaves {
            leave.execute(game: game, context: context, parent: self)
        }
        return .Success
    }
}

class BehaviorVariable
{
    var name        : String
    var value       : Any
    
    init(_ name: String,_ value:Any)
    {
        self.name = name
        self.value = value
    }
}

class BehaviorContext
{
    var trees               : [BehaviorTree] = []
    var variables           : [BehaviorVariable] = []
    
    let game                : Game
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    func clear()
    {
        trees = []
        variables = []
    }
    
    func addVariable(_ name: String,_ value: Any)
    {
        variables.append(BehaviorVariable(name, value))
    }
    
    func getVariableValue(_ name: String) -> Any?
    {
        for v in variables {
            if v.name == name {
                return v.value
            }
        }
        return nil
    }
    
    func execute(name: String)
    {
        for tree in trees {
            if tree.name == name {
                tree.execute(game: game, context: self, parent: nil)
            }
        }
    }
}