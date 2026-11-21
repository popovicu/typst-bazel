"""Finds the packages a Typst source imports."""

def _is_spec(name, version):
    return (
        name.replace("-", "").replace("_", "").isalnum() and
        [part.isdigit() for part in version.split(".")] == [True, True, True]
    )

def preview_imports(source):
    """Returns name:version for each @preview package a source names.

    Typst Universe does not say what a package imports, and this does not
    parse Typst: a string that starts with a package's name counts,
    wherever it is, unless its line is a comment. So it can find a package
    that is never imported, in an example, which costs a download. It
    misses only an import whose string is computed.

    Args:
      source: the text of a .typ file.
    """
    found = []
    for line in source.split("\n"):
        if line.strip().startswith("//"):
            continue
        for rest in line.split('"@preview/')[1:]:
            spec = rest.split('"')[0]
            name, _, version = spec.partition(":")
            if _is_spec(name, version) and spec not in found:
                found.append(spec)
    return found
