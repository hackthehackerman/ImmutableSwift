class ISHashable: ImmutableSwiftGeneratorPlugin {
    static let Name: String = "ISHashable"

    func shouldUseClass() -> Bool {
        return false
    }

    func imports() -> [String] {
        return ["Foundation"]
    }

    func superClasses() -> [String] {
        return ["Hashable"]
    }

    func postVariableDefinition(_: DataModel) -> String {
        return ""
    }

    func postConstructor(_ datamodel: DataModel) -> String {
        var results = ""
        results = results + ISHashable.GenerateIsEqualFunc(datamodel) + "\n\n"
        results = results + ISHashable.GenerateHashFunc(datamodel) + "\n"
        return results
    }

    private static func GenerateIsEqualFunc(_ datamodel: DataModel) -> String {
        let functionTemplate = "static func == (%@) -> Bool {\n\treturn %@\n}"
        let parameterTemplate = "lhs: %@, rhs: %@"

        let parameters = String(format: parameterTemplate, datamodel.name, datamodel.name)
        var stateComparisons: [String] = []
        for statement in datamodel.schema.statements {
            if statement is StateDef {
                stateComparisons.append("lhs." + (statement as! StateDef).name + " == " + "rhs." + (statement as! StateDef).name)
            }
        }
        let stateComparionsResult = stateComparisons.joined(separator: " && ")
        return String(format: functionTemplate, parameters, stateComparionsResult)
    }

    private static func GenerateHashFunc(_ datamodel: DataModel) -> String {
        let hashFunctionTemplate = "func hash(into hasher: inout Hasher) {\n%@\n}"
        var hashStatements: [String] = []

        for statement in datamodel.schema.statements {
            if statement is StateDef {
                hashStatements.append(String(format: "hasher.combine(%@)", (statement as! StateDef).name))
            }
        }
        return String(format: hashFunctionTemplate, StringUtils.formatStringWithIndentLevel(str: hashStatements.joined(separator: "\n"), indentLevel: 1))
    }
}
