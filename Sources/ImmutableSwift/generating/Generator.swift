class Generator {
    static func Generate(_ datamodel: DataModel) -> String {
        var output = ""
        let pluginList : PluginList?
        if datamodel.plugins != nil{
            pluginList = datamodel.plugins
        } else{
            pluginList = PluginList(Plugins.defaultPlugins)
        }

        // optional imports
        if datamodel.imports != nil {
            output = output + Generator.ImportsToString(datamodel.imports!) + "\n"
        }

        if pluginList != nil {
            let importsFromPlugins = Generator.GenerateImportsWithPluginList(pluginList!)
            if importsFromPlugins.count > 0{
                output = output  + importsFromPlugins + "\n"
            }
        }

        // optional accesscontrol
        if datamodel.accessControlLevel != nil {
            output = output + Generator.AccessControlLevelToString(datamodel.accessControlLevel!) + " "
        }

        // struct or class
        let shouldUseClass: Bool = Generator.shouldUseClass(pluginList)
        if shouldUseClass {
            output = output + Keyword.CLASS + " "
        } else {
            output = output + Keyword.STRUCT + " "
        }
        // name
        output = output + datamodel.name + " "

        // optional super classes
        if pluginList != nil {
            output = output + Generator.PrintSuperClasses(pluginList!)
        }

        // variables
        var datamodelBody = Generator.SchemaToString(datamodel.schema)

        // post variable body from plugins
        if pluginList != nil {
            let additionalBody = Generator.GeneratePostVariableDefinitionObjectBodyWithPluginList(pluginList!, datamodel)
            if !additionalBody.isEmpty {
                datamodelBody = datamodelBody + "\n" + additionalBody
            }
        }

        // constructor
        if shouldUseClass {
            let constructor = Generator.PrintConstructorForClass(datamodel.schema)
            datamodelBody = datamodelBody + "\n" + constructor + "\n"
        }

        // post constructor body from plugins
        if pluginList != nil {
            let additionalBody = Generator.GeneratePostConstructorObjectBodyWithPluginList(pluginList!, datamodel)
            if !additionalBody.isEmpty {
                datamodelBody = datamodelBody + "\n" + additionalBody + "\n"
            }
        }

        datamodelBody = StringUtils.formatStringWithIndentLevel(str: datamodelBody, indentLevel: 1)
        output = output + Generator.WrappedModelBody(datamodelBody)
        return output
    }

    static func ImportsToString(_ imports: [Import]) -> String {
        var output = ""
        for importStatment in imports {
            if importStatment is SingleModuleImport {
                let singleModuleImport = importStatment as! SingleModuleImport
                output = output + [Keyword.IMPORT, singleModuleImport.module].joined(separator: " ")
            } else if importStatment is ModuleWithSubmoduleImport {
                let moduleWithSubmoduleImport = importStatment as! ModuleWithSubmoduleImport
                output = output + [Keyword.IMPORT, moduleWithSubmoduleImport.module + "." + moduleWithSubmoduleImport.submodule].joined(separator: " ")
            } else if importStatment is ModuleWithSymbolImport {
                let moduleWithSymbolImport = importStatment as! ModuleWithSymbolImport
                output = output + [Keyword.IMPORT, moduleWithSymbolImport.kind, moduleWithSymbolImport.module + "." + moduleWithSymbolImport.symbol].joined(separator: " ")
            }
            output = output + "\n"
        }
        return output
    }

    static func GenerateImportsWithPluginList(_ pluginList: PluginList) -> String {
        var imports: Set<String> = []
        for pluginName in pluginList.plugins {
            if Plugins.pluginMap[pluginName] != nil {
                for importFromPlugin in Plugins.pluginMap[pluginName]!.imports() {
                    imports.insert("import "+importFromPlugin)
                }
            }
        }
        return imports.joined(separator: "\n") + "\n"
    }

    static func AccessControlLevelToString(_ accessControl: AccessControl) -> String {
        switch accessControl {
        case AccessControl.levelPublic:
            return Keyword.AccessControlModifier.PUBLIC_LEVEL
        case AccessControl.levelInternal:
            return Keyword.AccessControlModifier.INTERNAL_LEVEL
        }
    }

    static func shouldUseClass(_ pluginList: PluginList?) -> Bool {
        if pluginList == nil {
            return false
        }
        for pluginName in pluginList!.plugins {
            if Plugins.pluginMap[pluginName] != nil, Plugins.pluginMap[pluginName]!.shouldUseClass() {
                return true
            }
        }
        return false
    }

    static func PrintSuperClasses(_ pluginList: PluginList) -> String {
        var superClasses: [String] = []
        for pluginName in pluginList.plugins {
            if Plugins.pluginMap[pluginName] != nil {
                superClasses = superClasses + Plugins.pluginMap[pluginName]!.superClasses()
            }
        }
        if !superClasses.isEmpty {
            return ": " + superClasses.joined(separator: ", ")
        } else {
            return ""
        }
    }

    static func PrintConstructorForClass(_ schema: Schema) -> String {
        let constructorFormat = "init(%@) {\n%@\n}"
        var parameters: [String] = []
        var assignments: [String] = []
        for statement in schema.statements {
            if statement is StateDef {
                parameters.append((statement as! StateDef).name + ":" + (statement as! StateDef).type)
                assignments.append("self." + (statement as! StateDef).name + " = " + (statement as! StateDef).name)
            }
        }
        let parametersString = parameters.joined(separator: ", ")
        let assignmentString = StringUtils.formatStringWithIndentLevel(str: assignments.joined(separator: "\n"), indentLevel: 1)
        return String(format: constructorFormat, parametersString, assignmentString)
    }

    static func SchemaToString(_ schema: Schema) -> String {
        var result: [String] = []
        for i in 0 ..< schema.statements.count {
            let statement = schema.statements[i]
            if statement is Comment {
                result.append("//" + (statement as! Comment).source)
            } else if statement is StateDef {
                let stateDef = statement as! StateDef
                result.append("let " + stateDef.name + " : " + stateDef.type)
            }
        }
        return result.joined(separator: "\n") + "\n"
    }

    static func GeneratePostVariableDefinitionObjectBodyWithPluginList(_ pluginList: PluginList, _ datamodel: DataModel) -> String {
        var additionalBody: [String] = []
        for pluginName in pluginList.plugins {
            if Plugins.pluginMap[pluginName] != nil {
                let bodyFromPlugin = Plugins.pluginMap[pluginName]!.postVariableDefinition(datamodel)
                if !bodyFromPlugin.isEmpty {
                    additionalBody.append(bodyFromPlugin)
                }
            }
        }
        return additionalBody.joined(separator: "\n")
    }

    static func GeneratePostConstructorObjectBodyWithPluginList(_ pluginList: PluginList, _ datamodel: DataModel) -> String {
        var additionalMethods: [String] = []
        for pluginName in pluginList.plugins {
            if Plugins.pluginMap[pluginName] != nil {
                let methodFromPlugin = Plugins.pluginMap[pluginName]!.postConstructor(datamodel)
                if !methodFromPlugin.isEmpty {
                    additionalMethods.append(methodFromPlugin)
                }
            }
        }
        return additionalMethods.joined(separator: "\n")
    }

    static func WrappedModelBody(_ body: String) -> String {
        return "{\n" + body + "}"
    }
}
