//
//  Utilities.swift
//  Denrim
//
//  Created by Markus Moenig on 23/9/20.
//

import Foundation

struct UpTo4Data {
    var bool1        : Bool1? = nil
    var int1         : Int1? = nil

    var data1        : Float1? = nil
    var data2        : Float2? = nil
    var data3        : Float3? = nil
    var data4        : Float4? = nil
    
    // if component
    var index        : Int? = nil
}

func extractComponent(_ options: [String:Any], variableName: String = "variable", container: VariableContainer, parameters: [BaseVariable] = [], error: inout CompileError) -> UpTo4Data?
{
    var index : Int? = nil
    if let compString = options["component"] as? String {
        
        let indexString = compString.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil).lowercased()
        
        if indexString == "x" {
            index = 0
        } else
        if indexString == "y" {
            index = 1
        } else
        if indexString == "z" {
            index = 2
        } else
        if indexString == "w" {
            index = 3
        } else {
            error.error = "Incorrect 'Component' value, must be one of x, y, z or w"
        }
    } else { error.error = "Missing required 'Component' parameter" }
    
    if let index = index {
        if let f2 = extractFloat2Value(options, container: container, parameters: parameters, error: &error, name: variableName, isOptional: true) {
            if index <= 1 {
                var data = UpTo4Data()
                data.data2 = f2
                data.index = index
                return data
            } else {
                error.error = "'Component' value must be x or y for a Float2 variable"
            }
        } else
        if let f3 = extractFloat3Value(options, container: container, parameters: parameters, error: &error, name: variableName, isOptional: true) {
            if index <= 2 {
                var data = UpTo4Data()
                data.data3 = f3
                data.index = index
                return data
            } else {
                error.error = "'Component' value must be x, y or z for a Float3 variable"
            }
        } else
        if let f4 = extractFloat4Value(options, container: container, parameters: parameters, error: &error, name: variableName, isOptional: true) {
            if index <= 3 {
                var data = UpTo4Data()
                data.data4 = f4
                data.index = index
                return data
            } else {
                error.error = "'Component' value must be x, y, z or w for a Float4 variable"
            }
        } else {
            error.error = "'Variable' value must reference a Float2, Float3 or Float4 variable"
        }
    }
    
    return nil
}

func extractVariableValue(_ options: [String:Any], variableName: String, container: VariableContainer, parameters: [BaseVariable] = [], error: inout CompileError) -> Any?
{
    if let varString = options[variableName] as? String {
        if let value = container.getVariableValue(varString, parameters: parameters) {
            return value
        } else { error.error = "Cannot find '\(variableName)' parameter" }
    } else { error.error = "Missing required '\(variableName)' parameter" }
    
    return nil
}

/// Extract a float4 vale
func extractFloat4Value(_ options: [String:Any], container: VariableContainer, parameters: [BaseVariable] = [], error: inout CompileError, name: String = "float4", isOptional: Bool = false,  ignoreErrors: Bool = false) -> Float4?
{
    if let value = options[name] as? String {
        if let context = expressionBuilder( expression: value, container: container, defaultVariableType: .Float4, error: &error) {
            if let value = context.executeForFloat4() {
                return value
            } else {
                error.error = "Result for '\(name)' is not a Float4 value but \(context.wrongType)"
                return nil
            }
        }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    
    if ignoreErrors {
        error.error = nil
    }
    return nil
}

/// Extract a float3 vale
func extractFloat3Value(_ options: [String:Any], container: VariableContainer, parameters: [BaseVariable] = [], error: inout CompileError, name: String = "float3", isOptional: Bool = false, ignoreErrors: Bool = false) -> Float3?
{
    if let value = options[name] as? String {
        if let context = expressionBuilder( expression: value, container: container, defaultVariableType: .Float3, error: &error) {
            if let value = context.executeForFloat3() {
                return value
            } else {
                error.error = "Result for '\(name)' is not a Float3 value but \(context.wrongType)"
                return nil
            }
        }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    
    if ignoreErrors {
        error.error = nil
    }
    return nil
}

/// Extract a float2 vale
func extractFloat2Value(_ options: [String:Any], container: VariableContainer, parameters: [BaseVariable] = [], error: inout CompileError, name: String = "float2", isOptional: Bool = false, ignoreErrors: Bool = false) -> Float2?
{
    if let value = options[name] as? String {
        if let context = expressionBuilder( expression: value, container: container, defaultVariableType: .Float2, error: &error) {
            if let value = context.executeForFloat2() {
                return value
            } else {
                error.error = "Result for '\(name)' is not a Float2 value but \(context.wrongType)"
                return nil
            }
        }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    
    if ignoreErrors {
        error.error = nil
    }
    return nil
}

/// Extract a float1 vale
func extractFloat1Value(_ options: [String:Any], container: VariableContainer, parameters: [BaseVariable] = [], error: inout CompileError, name: String = "float", isOptional: Bool = false, ignoreErrors: Bool = false) -> Float1?
{
    if let value = options[name] as? Float1 {
        return value
    } else
    if var value = options[name] as? String {
        value = value.trimmingCharacters(in: .whitespaces)
        if let value = Float(value) {
            return Float1(value)
        } else
        if let v = container.getVariableValue(value, parameters: parameters) as? Float1 {
            return v
        }  else
        {
            if let context = expressionBuilder( expression: value, container: container, error: &error) {
                if let value = context.executeForFloat1() {
                    return value
                } else {
                    error.error = "Result for '\(name)' is not a Float1 value but \(context.wrongType)"
                    return nil
                }
            }
            if isOptional == false { error.error = "Parameter '\(name)' not found" }
        }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    
    if ignoreErrors {
        error.error = nil
    }
    return nil
}

/// Extract a int1 vale
func extractInt1Value(_ options: [String:Any], container: VariableContainer, parameters: [BaseVariable] = [], error: inout CompileError, name: String = "int", isOptional: Bool = false, ignoreErrors: Bool = false) -> Int1?
{
    if var value = options[name] as? String {
        value = value.trimmingCharacters(in: .whitespaces)
        if let value = Int(value) {
            return Int1(value)
        } else
        if let v = container.getVariableValue(value, parameters: parameters) as? Int1 {
            return v
        }  else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    
    if ignoreErrors {
        error.error = nil
    }
    return nil
}

/// Extract a Bool1 vale
func extractBool1Value(_ options: [String:Any], container: VariableContainer, parameters: [BaseVariable] = [], error: inout CompileError, name: String = "bool", isOptional: Bool = false,  ignoreErrors: Bool = false) -> Bool1?
{
    if var value = options[name] as? String {
        value = value.trimmingCharacters(in: .whitespaces)
        if let value = Bool(value) {
            return Bool1(value)
        } else
        if let v = container.getVariableValue(value, parameters: parameters) as? Bool1 {
            return v
        }  else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    } else { if isOptional == false { error.error = "Parameter '\(name)' not found" } }
    
    if ignoreErrors {
        error.error = nil
    }
    return nil
}

func extractPair(_ options: [String:Any], variableName: String, container: VariableContainer, parameters: [BaseVariable] = [], error: inout CompileError, optionalVariables: [String]) -> (UpTo4Data, UpTo4Data,[UpTo4Data])
{
    var Data         = UpTo4Data()
    var variableData = UpTo4Data()
    var optionals : [UpTo4Data] = []
    
    if let variableValue = extractVariableValue(options, variableName: variableName, container: container, /*parameters: parameters,*/ error: &error) {
        if let b1 = variableValue as? Bool1 {
            variableData.bool1 = b1
            if let data = extractBool1Value(options, container: container, parameters: parameters, error: &error) {
                Data.bool1 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.bool1 = extractBool1Value(options, container: container, parameters: parameters, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        } else
        if let i1 = variableValue as? Int1 {
            variableData.int1 = i1
            if let data = extractInt1Value(options, container: container, parameters: parameters, error: &error) {
                Data.int1 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.int1 = extractInt1Value(options, container: container, parameters: parameters, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        } else
        if let f1 = variableValue as? Float1 {
            variableData.data1 = f1
            if let data = extractFloat1Value(options, container: container, parameters: parameters, error: &error) {
                Data.data1 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.data1 = extractFloat1Value(options, container: container, parameters: parameters, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        } else
        if let f2 = variableValue as? Float2 {
            variableData.data2 = f2
            if let data = extractFloat2Value(options, container: container, parameters: parameters, error: &error) {
                Data.data2 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.data2 = extractFloat2Value(options, container: container, parameters: parameters, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        } else
        if let f3 = variableValue as? Float3 {
            variableData.data3 = f3
            if let data = extractFloat3Value(options, container: container, parameters: parameters, error: &error) {
                Data.data3 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.data3 = extractFloat3Value(options, container: container, parameters: parameters, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        } else
        if let f4 = variableValue as? Float4 {
            variableData.data4 = f4
            if let data = extractFloat4Value(options, container: container, parameters: parameters, error: &error) {
                Data.data4 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.data4 = extractFloat4Value(options, container: container, parameters: parameters, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        }
    }
    
    return (Data, variableData, optionals)
}

/// Build the expression and return the context
func expressionBuilder(expression: String, container: VariableContainer, defaultVariableType: BaseVariable.VariableType? = nil, error: inout CompileError) -> ExpressionContext?
{
    let exp = ExpressionContext()
    exp.parse(expression: expression, container: container, defaultVariableType: defaultVariableType, error: &error)
    if error.error != nil {
        return nil
    }
    return exp
}
