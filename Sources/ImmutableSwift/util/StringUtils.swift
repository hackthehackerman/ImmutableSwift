class StringUtils {
    static func formatStringWithIndentLevel(str: String, indentLevel: Int, indentSymbol: String = "\t") -> String {
        if indentLevel < 0 {
            return str
        }

        let indentPrefix = String(repeating: indentSymbol, count: indentLevel)
        var out = ""

        let lines = str.split(separator: "\n", omittingEmptySubsequences: false)
        for i in lines.startIndex ..< lines.endIndex {
            if !lines[i].isEmpty {
                out = out + indentPrefix + lines[i]
            }
            if i != lines.endIndex - 1 {
                out = out + "\n"
            }
        }
        return out
    }
}
