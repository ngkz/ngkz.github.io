---
title: "Linux from Scratch - Automation Part 1"
date: 2020-01-02T23:34:04+09:00
categories:
- F²LFS
tags:
- LFS
---

## What happened after 50th LFS post

I can't progress Linux from Scratch building from May to October, because I spent time on other projects.

I restarted building in October in parallel with other projects and almost done a basic system. In December, I started writing a literate programming style automated build system, but I can't make much progress as I have been busy with work recently.

## Literate distro building
<!--more-->

I planned to build the LFS system and its HTML documentation using AsciiDoc documents.

The document contains package information (version, dependencies, source location, etc.), build scripts, and its explanation. My automated build system will solve and sort package dependencies, build packages, and output the working system and documentation, using Asciidoctor with a custom plugin.

I chose AsciiDoc + AsciiDoctor because of the following reasons:
- It has cleaner syntax and versatile table syntax than other lightweight markup languages.
- It's extensible
- Because I must build many packages twice (for temporary system and basic system), It's preprocessor directives are convenient.

But more and more the development progresses, I feel that AsciiDoctor is not suitable for this task strongly.
It is impossible to build complex AST nodes like a table with API. It lacks internal documentation, so I have to dig into source code and spend time to debug. And it lacks chunked HTML output, therefore I need a static site generator.

I ditched AsciiDoctor and migrating to Sphinx because it's much more extensible, has better documentation, and supports multi-pages.
