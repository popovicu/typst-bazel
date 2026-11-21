"""Rules for Typst."""

load("//typst/private:document.bzl", _typst_document = "typst_document")
load("//typst/private:library.bzl", _typst_library = "typst_library")
load("//typst/private:providers.bzl", _TypstLibraryInfo = "TypstLibraryInfo")

typst_document = _typst_document
typst_library = _typst_library
TypstLibraryInfo = _TypstLibraryInfo
