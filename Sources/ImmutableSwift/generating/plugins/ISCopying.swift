class ISCopying: ImmutableSwiftGeneratorPlugin {
    static let Name: String = "ISCopying"

    func shouldUseClass() -> Bool {
        return true
    }

    func superClasses() -> [String] {
        return ["NSCopying"]
    }

    func postVariableDefinition(_: DataModel) -> String {
        return ""
    }

    func postConstructor(_ datamodel: DataModel) -> String {
        var results = ""
        results = results + ISCopying.GenerateCopyingFunc(datamodel)
        return results
    }

    private static func GenerateCopyingFunc(_ datamodel: DataModel) -> String {
        let copyFuncTemplate = "func copy(with zone: NSZone? = nil) -> Any {\n%@\n}"
        let copyFuncBodyTemplate = "let copy = %@(%@)\n return copy"
        var initMethodArguments: [String] = []
        for statement in datamodel.schema.statements {
            if statement is StateDef {
                initMethodArguments.append(String(format: "%@:%@", (statement as! StateDef).name, (statement as! StateDef).name))
            }
        }
        let initMethodArgument = initMethodArguments.joined(separator: ",")
        var copyFuncBody = String(format: copyFuncBodyTemplate, datamodel.name, initMethodArgument)
        copyFuncBody = StringUtils.formatStringWithIndentLevel(str: copyFuncBody, indentLevel: 1)
        return String(format: copyFuncTemplate, copyFuncBody)
    }
}
