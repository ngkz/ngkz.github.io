---
title: "Building Linux from Scratch (Part 51)"
date: 2020-01-02T23:34:04+09:00
categories:
- F²LFS
tags:
- LFS
---

I can't progress Linux from Scratch building from May to November, because I spent time on other projects.

I restarted building in December but I can't make much progress as I have been busy with work recently.

## Literate distro building
I am building a literate programming style automated build system recently.

<!--more-->

I planned to build the LFS system and its HTML documentation using AsciiDoc documents.

The document contains package information (version, dependencies, source location, etc.), build scripts, and its explanation. My automated build system will solve and sort package dependencies, build packages, and output the working system and documentation, using Asciidoctor with a custom plugin.

I chose AsciiDoc + AsciiDoctor because I prefer its overall cleaner syntax and versatile table syntax, and it is extensible.

But more and more the development progresses, I feel that AsciiDoctor is not suitable for this task strongly.
It is difficult to build complex AST with API. It lacks internal documentation, so I have to dig into source code and spend time to debug. And it lacks chunked HTML output, therefore I need a static site generator.

I discarded AsciiDoctor and migrating to Sphinx because it's much more extensible, has better documentation, and supports multi-pages.
