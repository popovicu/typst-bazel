"""Rules for Typst."""

load("//typst/private:document.bzl", _typst_document = "typst_document")
load("//typst/private:library.bzl", _typst_library = "typst_library")
load("//typst/private:package.bzl", _typst_package = "typst_package")
load("//typst/private:providers.bzl", _TypstLibraryInfo = "TypstLibraryInfo", _TypstPackageInfo = "TypstPackageInfo")

typst_document = _typst_document
typst_library = _typst_library
typst_package = _typst_package
TypstLibraryInfo = _TypstLibraryInfo
TypstPackageInfo = _TypstPackageInfo
