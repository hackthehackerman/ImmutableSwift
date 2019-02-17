enum AccessControl {
    case levelPublic
    case levelInternal
}

class Node {
    init() {}
}

class DataModel: Node {
    let imports: [Import]?
    let accessControlLevel: AccessControl?
    let name: String
    let plugins: PluginList?
    let schema: Schema

    init(_ imports: [Import]?, _ accessControlLevel: AccessControl?, _ name: String, _ plugins: PluginList?, _ schema: Schema) {
        self.imports = imports
        self.accessControlLevel = accessControlLevel
        self.name = name
        self.plugins = plugins
        self.schema = schema
    }
}

class Import: Node {}

class SingleModuleImport: Import {
    let module: String
    init(_ module: String) {
        self.module = module
    }
}

class ModuleWithSubmoduleImport: Import {
    let module: String
    let submodule: String
    init(_ module: String, _ submodule: String) {
        self.module = module
        self.submodule = submodule
    }
}

class ModuleWithSymbolImport: Import {
    let kind: String
    let module: String
    let symbol: String
    init(_ kind: String, _ module: String, _ symbol: String) {
        self.kind = kind
        self.module = module
        self.symbol = symbol
    }
}

class PluginList: Node {
    let plugins: [String]

    init(_ plugins: [String]) {
        self.plugins = plugins
    }
}

class Schema: Node {
    let statements: [Statement]

    init(_ statements: [Statement]) {
        self.statements = statements
    }
}

class Statement: Node {}

class Comment: Statement {
    let source: String
    init(_ source: String) {
        self.source = source
    }
}

class StateDef: Statement {
    let type: String
    let name: String
    init(_ type: String, _ name: String) {
        self.type = type
        self.name = name
    }
}
