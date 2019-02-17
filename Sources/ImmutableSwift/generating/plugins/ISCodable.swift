class ISCodable: ImmutableSwiftGeneratorPlugin {
    static let Name: String = "ISCodable"

    func shouldUseClass() -> Bool {
        return false
    }

    func imports() -> [String] {
        return ["Foundation"]
    }

    func superClasses() -> [String] {
        return ["Codable"]
    }

    func postVariableDefinition(_: DataModel) -> String {
        return ""
    }

    func postConstructor(_: DataModel) -> String {
        return ""
    }
}
