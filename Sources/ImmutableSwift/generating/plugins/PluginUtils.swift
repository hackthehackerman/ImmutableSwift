protocol ImmutableSwiftGeneratorPlugin {
    static var Name: String { get }
    func shouldUseClass() -> Bool
    func imports() -> [String]
    func superClasses() -> [String]
    func postVariableDefinition(_ datamodel: DataModel) -> String
    func postConstructor(_ datamodel: DataModel) -> String
}

struct Plugins {
    static let PLUGIN_MAP: [String: ImmutableSwiftGeneratorPlugin] = [
        ISCoding.Name: ISCoding(),
        ISHashable.Name: ISHashable(),
        ISCodable.Name: ISCodable(),
        ISCopying.Name: ISCopying(),
    ]
}
