class ISCoding: ImmutableSwiftGeneratorPlugin {
    static let Name: String = "ISCoding"

    // type X in this array should use NSCoder.decodeX()
    static let typesWithDedicatedDecodeMethodWithSameName: [String] = [
        "Bool",
        "Data",
        "Float",
        "Int32",
        "Int64",
        "CGPoint",
        "CGRect",
        "CGSize",
        "CGAffineTransform",
        "UIEdgeInsets",
        "UIOffset",
        "CGVector",
    ]

    // type X in this array should use NSCoder.decodeCUSTOMNAME()
    static let typesWithDedicatedDecodeMethodWithCustomName: [String: String] = [
        "Int32": "CInt",
        "Int": "Integer",
        "NSPoint": "Point",
        "NSRect": "Rect",
        "NSSize": "Size",
        "CMTime": "Time",
        "CMTimeRange": "TimeRange",
        "CMTimeMapping": "TimeMapping",
    ]

    static let decodeMethodWithOptionalReturnValue: [String] = [
        "decodeObject",
        "decodeData",
    ]

    func shouldUseClass() -> Bool {
        return true
    }

    func superClasses() -> [String] {
        return ["NSObject", "NSCoding"]
    }

    func postVariableDefinition(_ datamodel: DataModel) -> String {
        return ISCoding.printKeyEnum(datamodel.schema) + "\n"
    }

    func postConstructor(_ datamodel: DataModel) -> String {
        var out = ""
        out = out + ISCoding.printEncodeFunc(datamodel.schema) + "\n"
        out = out + "\n" + ISCoding.printDecodeFunc(datamodel.schema) + "\n"
        return out
    }

    static func printKeyEnum(_ schema: Schema) -> String {
        let keyEnumFormat = "enum Key:String {\n%@\n}"
        var keys: [String] = []
        for statement in schema.statements {
            if statement is StateDef {
                keys.append(String(format: "case %@ = \"%@\"", (statement as! StateDef).name, (statement as! StateDef).name))
            }
        }
        var keyString = keys.joined(separator: "\n")
        keyString = StringUtils.formatStringWithIndentLevel(str: keyString, indentLevel: 1)
        return String(format: keyEnumFormat, keyString)
    }

    static func printEncodeFunc(_ schema: Schema) -> String {
        let encodefuncFormat = "func encode(with aCoder: NSCoder) {\n%@\n}"
        var encodeStatement: [String] = []
        for statement in schema.statements {
            if statement is StateDef {
                let stateDef = statement as! StateDef
                if ISCoding.isOptionalType(stateDef.type) {
                    encodeStatement.append(String(format: "if %@ != nil {\naCoder.encode(%@, forKey: Key.%@.rawValue)\n}", (statement as! StateDef).name, (statement as! StateDef).name, (statement as! StateDef).name))
                } else {
                    encodeStatement.append(String(format: "aCoder.encode(%@, forKey: Key.%@.rawValue)", (statement as! StateDef).name, (statement as! StateDef).name))
                }
            }
        }
        var encodeString = encodeStatement.joined(separator: "\n")
        encodeString = StringUtils.formatStringWithIndentLevel(str: encodeString, indentLevel: 1)
        return String(format: encodefuncFormat, encodeString)
    }

    static func printDecodeFunc(_ schema: Schema) -> String {
        let decodeFuncFormat = "convenience required init?(coder aDecoder: NSCoder) {\n%@\n}"
        let initMethodCallFormat = "self.init(%@)"
        var decodeStatement: [String] = []
        var initParameters: [String] = []
        for statement in schema.statements {
            if statement is StateDef {
                var decodeMethod = "decodeObject"
                let stateType = (statement as! StateDef).type
                let stateName = (statement as! StateDef).name
                if ISCoding.typesWithDedicatedDecodeMethodWithSameName.contains(stateType) {
                    decodeMethod = "decode" + stateType
                } else if ISCoding.typesWithDedicatedDecodeMethodWithCustomName.keys.contains(stateType) {
                    decodeMethod = "decode" + ISCoding.typesWithDedicatedDecodeMethodWithCustomName[stateType]!
                }

                if ISCoding.decodeMethodWithOptionalReturnValue.contains(decodeMethod), !ISCoding.isOptionalType(stateType) {
                    decodeStatement.append(String(format: "guard let %@ = aDecoder.%@(forKey: Key.%@.rawValue) as? %@ else { return nil }", stateName, decodeMethod, stateName, stateType))
                } else {
                    decodeStatement.append(String(format: "let %@ = aDecoder.%@(forKey: Key.%@.rawValue)", stateName, decodeMethod, stateName))
                }

                initParameters.append(stateName + ":" + stateName)
            }
        }
        let decodeString = decodeStatement.joined(separator: "\n")
        let initParametersString = initParameters.joined(separator: ",")
        var decodeMethodBody = decodeString + "\n" + String(format: initMethodCallFormat, initParametersString)
        decodeMethodBody = StringUtils.formatStringWithIndentLevel(str: decodeMethodBody, indentLevel: 1)

        return String(format: decodeFuncFormat, decodeMethodBody)
    }

    static func isOptionalType(_ type: String) -> Bool {
        if type.count <= 0 {
            return false
        }
        return type.last! == "?"
    }
}
