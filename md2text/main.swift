//
//  main.swift
//  md2text
//
//  Created by Peter Richardson on 7/4/25.
//

import Foundation
import Markdown
import Rainbow
import Darwin

let sampleMarkdown = """
# Title
    
## Paragraph (wrapped to terminal width, break on word boundaries)

Call me Ishmael. Some years ago—never mind how long precisely — having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world. It is a way I have of driving off the spleen and regulating the circulation. Whenever I find myself growing grim about the mouth; whenever it is a damp, drizzly November in my soul; whenever I find myself involuntarily pausing before coffin warehouses, and bringing up the rear of every funeral I meet; and especially whenever my hypos get such an upper hand of me, that it requires a strong moral principle to prevent me from deliberately stepping into the street, and methodically knocking people’s hats off—then, I account it high time to get to sea as soon as I can.


## Misc Text Styles
Bold: **Now is the winter of our discontent**

Italic: _Made glorious summer by this sun of York_

Strikethrough: ~~Skibidi Toilet~~

## Unordered List

* list item 1
* list item 2
* list item 3

## Ordered List

1. foo
1. bar
1. baz

## Block Quote

> How many roads must a man walk down
>
> Before you call him a man?
> 
> — Bob Dylan

## Link

Here's a [Link](http://example.com) to example.com.

## Code Block
```c
#include <stdio.h>
void main(int argc, char** argv) {
    printf("Hello, World!\\n");
}
```

"""

func terminalWidth() -> Int {
    var w = winsize()
    if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
        return Int(w.ws_col)
    } else {
        return 80
    }
}

func wrap(text: String, width: Int) -> String {
    var lines: [String] = []
    var currentLine = ""
    
    for word in text.split(separator: " ") {
        if currentLine.count + word.count + 1 > width {
            lines.append(currentLine)
            currentLine = String(word)
        } else {
            if currentLine.isEmpty {
                currentLine = String(word)
            } else {
                currentLine += " " + word
            }
        }
    }
    if !currentLine.isEmpty {
        lines.append(currentLine)
    }
    return lines.joined(separator: "\n")
}

func renderMarkdownAsStyledText(_ markdown: String) -> String {
    let document = Document(parsing: markdown)
    var output = ""
    for child in document.children {
        output += renderBlock(child).trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n"
    }
    return output.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func renderOrderedList(_ list: OrderedList) -> String {
    var lines: [String] = []
    for (i, item) in list.children.enumerated() {
        let number = i + Int(list.startIndex)  // startIndex is usually 1
        let itemText = renderBlock(item)
        lines.append("\(number). \(itemText)")
    }
    return lines.joined(separator: "\n")
}

private func renderBlock(_ block: Markup) -> String {
    switch block {
    case let heading as Heading:
        let prefix = String(repeating: "#", count: heading.level)
        return (prefix + " " + renderInlineChildren(heading)).bold.white

    case let paragraph as Paragraph:
        let plain = renderInlineChildren(paragraph)
        return wrap(text: plain, width: terminalWidth())

    case let list as UnorderedList:
        return list.children.map { "• " + renderBlock($0) }.joined(separator: "\n")
        
    case let list as OrderedList:
        return renderOrderedList(list)
        
    case let listItem as ListItem:
        return listItem.children.map { renderBlock($0) }.joined(separator: " ")
        
    case let quote as BlockQuote:
        let quoted = quote.children.map { renderBlock($0) }
        return quoted.map { "    " + $0.replacingOccurrences(of: "\n", with: "\n    ") }.joined(separator: "\n").italic.blue

    case let codeBlock as CodeBlock:
        return "\n" + codeBlock.code.lightYellow + "\n"

    default:
        return ""
    }
}

//let esc = "\u{001B}"      // ESC
//let bel = "\u{0007}"      // BEL
//
//func terminalHyperlink(label: String, url: String) -> String {
//    return "\(esc)]8;;\(url)\(bel)\(label)\(esc)]8;;\(bel)"
//}

private func renderInlineChildren(_ markup: Markup) -> String {
    return markup.children.map { inline in
        switch inline {
        case let text as Text:
            return text.string

        case let emphasis as Emphasis:
            return renderInlineChildren(emphasis).italic

        case let strong as Strong:
            return renderInlineChildren(strong).bold

        case let code as InlineCode:
            return code.code.yellow

        case let link as Link:
            let label = renderInlineChildren(link)
            let url = link.destination ?? "(unknown)"
            return "\(label)".underline + " (\(url))".dim
            //return terminalHyperlink(label: label, url: url)

        default:
            return ""
        }
    }.joined()
}

let args = CommandLine.arguments
var source = sampleMarkdown
if args.count == 2 {
    source = try! String(contentsOfFile: args[1], encoding:  .utf8)
}

let output = renderMarkdownAsStyledText(source)
print(output)
