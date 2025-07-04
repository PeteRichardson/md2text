# md2text

A simple swift cli to render markdown into styled text in the terminal.

USAGE:  md2text \[\<path to markdown file\>\]

With no markdown file, md2text will print out a sample markdown document (embedded in the source code)

Uses [swift-markdown](https://github.com/swiftlang/swift-markdown) to parse and [rainbow](https://github.com/onevcat/Rainbow) to style.

Handles
* Headers
* Paragraphs - text is wrapped to the terminal with and broken on word boundaries
* Ordered Lists
* Unordered Lists
* Block Quotes
* Emphasis (Italics)
* Strong (Bold)
* Links

Notes:
* does not render links to OSC8 links in the terminal.   The code is commented out because cmd-clicking one of these links in iterm2 fails to launch the browser on my mac for some reason.
