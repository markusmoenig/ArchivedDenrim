//
//  Utilities.swift
//  Denrim
//
//  Created by Markus Moenig on 23/9/20.
//

import Foundation

struct UpTo4Data {
    var int1         : Int1? = nil

    var data1        : Float1? = nil
    var data2        : Float2? = nil
    var data3        : Float3? = nil
    var data4        : Float4? = nil
}

func extractVariableValue(_ options: [String:Any], variableName: String, context: BehaviorContext, error: inout CompileError) -> Any?
{
    if let varString = options[variableName] as? String {
        if let value = context.getVariableValue(varString) {
            return value
        } else { error.error = "Cannot find '\(variableName)' parameter" }
    } else { error.error = "Missing required '\(variableName)' parameter" }
    
    return nil
}

/// Extract a float4 vale
func extractFloat4Value(_ options: [String:Any], context: BehaviorContext, tree: BehaviorTree, error: inout CompileError, name: String = "float4", isOptional: Bool = false ) -> Float4?
{
    if let value = options[name] as? String {
        let array = value.split(separator: ",")
        if array.count == 4 {
            let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
            let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
            let z : Float; if let v = Float(array[2].trimmingCharacters(in: .whitespaces)) { z = v } else { z = 0 }
            let w : Float; if let v = Float(array[3].trimmingCharacters(in: .whitespaces)) { w = v } else { w = 0 }
            return Float4(x, y, z, w)
        } else
        if array.count == 1 {
            if let v = context.getVariableValue(String(array[0]), tree: tree) as? Float4 {
                return v
            }
        } else { if isOptional == false { error.error = "Wrong argument count for Float4" } }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    
    return nil
}

/// Extract a float3 vale
func extractFloat3Value(_ options: [String:Any], context: BehaviorContext, tree: BehaviorTree, error: inout CompileError, name: String = "float3", isOptional: Bool = false ) -> Float3?
{
    if let value = options[name] as? String {
        let array = value.split(separator: ",")
        if array.count == 3 {
            let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
            let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
            let z : Float; if let v = Float(array[2].trimmingCharacters(in: .whitespaces)) { z = v } else { z = 0 }
            return Float3(x, y, z)
        } else
        if array.count == 1 {
            if let v = context.getVariableValue(String(array[0]), tree: tree) as? Float3 {
                return v
            }
        } else { if isOptional == false { error.error = "Wrong argument count for Float3" } }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    
    return nil
}

/// Extract a float2 vale
func extractFloat2Value(_ options: [String:Any], context: BehaviorContext, tree: BehaviorTree, error: inout CompileError, name: String = "float2", isOptional: Bool = false ) -> Float2?
{
    if let value = options[name] as? Float2 {
        return value
    } else
    if let value = options[name] as? String {
        let array = value.split(separator: ",")
        if array.count == 2 {
            let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
            let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
            return Float2(x, y)
        } else
        if array.count == 1 {
            if let v = context.getVariableValue(String(array[0]), tree: tree) as? Float2 {
                return v
            }
        } else { if isOptional == false { error.error = "Wrong argument count for Float2" } }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    
    return nil
}

/// Extract a float1 vale
func extractFloat1Value(_ options: [String:Any], context: BehaviorContext, tree: BehaviorTree, error: inout CompileError, name: String = "float", isOptional: Bool = false ) -> Float1?
{
    if let value = options[name] as? Float1 {
        return value
    } else
    if var value = options[name] as? String {
        value = value.trimmingCharacters(in: .whitespaces)
        if let value = Float(value) {
            return Float1(value)
        } else
        if let v = context.getVariableValue(value, tree: tree) as? Float1 {
            return v
        }  else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    
    return nil
}

/// Extract a int1 vale
func extractInt1Value(_ options: [String:Any], context: BehaviorContext, tree: BehaviorTree, error: inout CompileError, name: String = "int", isOptional: Bool = false ) -> Int1?
{
    if var value = options[name] as? String {
        value = value.trimmingCharacters(in: .whitespaces)
        if let value = Int(value) {
            return Int1(value)
        } else
        if let v = context.getVariableValue(value, tree: tree) as? Int1 {
            return v
        }  else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    return nil
}

/// Extract a Bool1 vale
func extractBool1Value(_ options: [String:Any], context: BehaviorContext, tree: BehaviorTree, error: inout CompileError, name: String = "bool", isOptional: Bool = false ) -> Bool1?
{
    if var value = options[name] as? String {
        value = value.trimmingCharacters(in: .whitespaces)
        if let value = Bool(value) {
            return Bool1(value)
        } else
        if let v = context.getVariableValue(value, tree: tree) as? Bool1 {
            return v
        }  else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    return nil
}

func extractPair(_ options: [String:Any], variableName: String, context: BehaviorContext, tree: BehaviorTree, error: inout CompileError, optionalVariables: [String]) -> (UpTo4Data, UpTo4Data,[UpTo4Data])
{
    var Data         = UpTo4Data()
    var variableData = UpTo4Data()
    var optionals : [UpTo4Data] = []
    
    //print("extractPair", options, variableName)

    if let variableValue = extractVariableValue(options, variableName: variableName, context: context, error: &error) {
        if let i1 = variableValue as? Int1 {
            variableData.int1 = i1
            if let data = extractInt1Value(options, context: context, tree: tree, error: &error) {
                Data.int1 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.int1 = extractInt1Value(options, context: context, tree: tree, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        } else
        if let f1 = variableValue as? Float1 {
            variableData.data1 = f1
            if let data = extractFloat1Value(options, context: context, tree: tree, error: &error) {
                Data.data1 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.data1 = extractFloat1Value(options, context: context, tree: tree, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        } else
        if let f2 = variableValue as? Float2 {
            variableData.data2 = f2
            if let data = extractFloat2Value(options, context: context, tree: tree, error: &error) {
                Data.data2 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.data2 = extractFloat2Value(options, context: context, tree: tree, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        } else
        if let f3 = variableValue as? Float3 {
            variableData.data3 = f3
            if let data = extractFloat3Value(options, context: context, tree: tree, error: &error) {
                Data.data3 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.data3 = extractFloat3Value(options, context: context, tree: tree, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        } else
        if let f4 = variableValue as? Float4 {
            variableData.data4 = f4
            if let data = extractFloat4Value(options, context: context, tree: tree, error: &error) {
                Data.data4 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.data4 = extractFloat4Value(options, context: context, tree: tree, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        }
    }
    
    return (Data, variableData, optionals)
}
