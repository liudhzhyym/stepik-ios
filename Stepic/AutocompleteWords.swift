//
//  AutocompleteWords.swift
//  Stepic
//
//  Created by Ostrenkiy on 09.07.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation

struct AutocompleteWords {
    
    static func autocompleteFor(_ text: String, language: String) -> [String] {
        var suggestions: [String] = []
        
        switch language {
        case "python3":
            suggestions = python
            break
        case "c++", "c++11":
            suggestions = cpp
            break
        case "cs":
            suggestions = cs
            break
        case "java", "java8":
            suggestions = java
            break
        case "javascript":
            suggestions = js
            break
        case "ruby":
            suggestions = ruby
            break
        default:
            suggestions = []
            break
        }
        
        return suggestions.filter{
            $0.indexOf(text) == 0
        }
    }
    
    static let python = [
        "False",
        "class",
        "finally",
        "is",
        "return",
        "None",
        "continue",
        "for",
        "lambda",
        "try",
        "True",
        "def",
        "from",
        "nonlocal",
        "while",
        "and",
        "del",
        "global",
        "not",
        "with",
        "as",
        "elif",
        "if",
        "or",
        "yield",
        "assert",
        "else",
        "import",
        "pass",
        "print",
        "break",
        "except",
        "in",
        "raise"
    ]
    
    static let cpp = [
        "bool",
        "break",
        "case",
        "catch",
        "char",
        "class",
        "const",
        "cout",
        "cin",
        "endl",
        "include",
        "iostream",
        "continue",
        "default",
        "delete",
        "do",
        "double",
        "else",
        "enum",
        "extern",
        "false",
        "float",
        "for",
        "friend",
        "goto",
        "if",
        "inline",
        "int",
        "long",
        "mutable",
        "namespace",
        "new",
        "operator",
        "private",
        "protected",
        "public",
        "return",
        "short",
        "signed",
        "sizeof",
        "static",
        "string",
        "struct",
        "switch",
        "template",
        "this",
        "throw",
        "true",
        "try",
        "typedef",
        "typename",
        "union",
        "unsigned",
        "using",
        "virtual",
        "void",
        "while"
    ]
    
    static let cs = [
        "abstract",
        "base",
        "bool",
        "break",
        "byte",
        "case",
        "catch",
        "char",
        "checked",
        "class",
        "const",
        "continue",
        "decimal",
        "default",
        "delegate",
        "do",
        "double",
        "else",
        "enum",
        "event",
        "explicit",
        "extern",
        "false",
        "finally",
        "fixed",
        "float",
        "for",
        "foreach",
        "goto",
        "if",
        "implicit",
        "int",
        "interface",
        "internal",
        "lock",
        "long",
        "namespace",
        "new",
        "null",
        "object",
        "operator",
        "out",
        "override",
        "params",
        "private",
        "protected",
        "public",
        "readonly",
        "ref",
        "return",
        "sbyte",
        "sealed",
        "short",
        "sizeof",
        "stackalloc",
        "static",
        "string",
        "struct",
        "switch",
        "this",
        "throw",
        "true",
        "try",
        "typeof",
        "uint",
        "ulong",
        "unchecked",
        "unsafe",
        "ushort",
        "using",
        "virtual",
        "void",
        "volatile",
        "while",
        "set",
        "get",
        "var"
    ]
    
    static let java = [
        "abstract",
        "assert",
        "boolean",
        "break",
        "byte",
        "case",
        "catch",
        "char",
        "class",
        "const",
        "continue",
        "default",
        "do",
        "double",
        "else",
        "enum",
        "extends",
        "final",
        "finally",
        "float",
        "for",
        "goto",
        "if",
        "implements",
        "import",
        "instanceof",
        "int",
        "interface",
        "long",
        "native",
        "new",
        "package",
        "private",
        "protected",
        "public",
        "return",
        "short",
        "static",
        "super",
        "switch",
        "synchronized",
        "this",
        "throw",
        "throws",
        "try",
        "void",
        "volatile",
        "while",
        "false",
        "null",
        "true",
        "System",
        "out",
        "print",
        "println",
        "main",
        "String",
        "Math",
        "Scanner",
        "Thread",
        "ArrayList",
        "LinkedList",
        "HashMap",
        "HashSet",
        "Collections",
        "Iterator",
        "File",
        "Formatter",
        "Exception"
    ]
    
    static let js = [
        "abstract",
        "arguments",
        "boolean",
        "break",
        "byte",
        "case",
        "catch",
        "char",
        "class",
        "const",
        "continue",
        "debugger",
        "default",
        "delete",
        "do",
        "double",
        "else",
        "enum",
        "eval",
        "export",
        "extends",
        "false",
        "final",
        "finally",
        "float",
        "for",
        "function",
        "goto",
        "if",
        "implements",
        "in",
        "instanceof",
        "int",
        "interface",
        "let",
        "long",
        "native",
        "new",
        "null",
        "package",
        "private",
        "protected",
        "public",
        "return",
        "short",
        "static",
        "super",
        "switch",
        "synchronized",
        "this",
        "throw",
        "throws",
        "transient",
        "true",
        "try",
        "typeof",
        "var",
        "void",
        "volatile",
        "while",
        "with",
        "yield",
        "Array",
        "Date",
        "length",
        "Math",
        "NaN",
        "name",
        "Number",
        "Object",
        "prototype",
        "String",
        "toString",
        "undefinedvalueOf",
        "alert",
        "prompt",
        "confirm"
    ]
    
    static let ruby = [
        "and",
        "begin",
        "break",
        "case",
        "class",
        "def",
        "do",
        "else",
        "elsif",
        "each",
        "end",
        "true",
        "false",
        "for",
        "if",
        "in",
        "module",
        "next",
        "nil",
        "not",
        "or",
        "rescue",
        "retry",
        "return",
        "self",
        "super",
        "then",
        "undef",
        "unless",
        "until",
        "when",
        "while",
        "yield",
        "attr_accessor",
        "attr_reader",
        "attr_writer",
        "initialize",
        "new",
        "puts",
        "gets",
        "print",
        "Struct",
        "Math",
        "Time",
        "Proc",
        "File",
        "lambda",
        "Comparable",
        "Enumerable"
    ]
}
