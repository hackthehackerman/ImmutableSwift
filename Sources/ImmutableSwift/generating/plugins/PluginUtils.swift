protocol ImmutableSwiftGeneratorPlugin {
    static var Name: String { get }
    func shouldUseClass() -> Bool
    func imports() -> [String]
    func superClasses() -> [String]
    func postVariableDefinition(_ datamodel: DataModel) -> String
    func postConstructor(_ datamodel: DataModel) -> String
}

struct Plugins {
    static let pluginMap: [String: ImmutableSwiftGeneratorPlugin] = [
        ISCoding.Name: ISCoding(),
        ISHashable.Name: ISHashable(),
        ISCodable.Name: ISCodable(),
        ISCopying.Name: ISCopying(),
    ]

    static let defaultPlugins : [String] = [
        ISHashable.Name,
        ISCodable.Name,
        ISCopying.Name,
    ]
}