#!/usr/bin/env rdmd
/++
    Helper script to build docs, avoiding name conflicts between package files.
+/
module build_docs;

import std.algorithm: filter;
import std.file: SpanMode, dirEntries, mkdir, exists;
import std.path: stripExtension;
import std.process: execute;
import std.string: split, replace, format;

enum command = "/usr/bin/env dmd -c -o- -Dfdocs/%s.html -w -Isrc src/macros.ddoc %s";

string to_module(string path)
{
    return path.stripExtension.replace("src/", "").replace("/", ".");
}

auto all_files()
{
    return dirEntries("src/phrased/", SpanMode.depth).filter!(dir => !dir.isDir);
}

void main(string[] args)
{
    if(!"docs".exists)
        mkdir("docs");
    
    foreach(file; all_files)
        execute(command.format(file.to_module, file).split(" "));
}
