// The resume of someone who does not exist.
#import "style.typ": entry, footer, header, metric, resume

// The rule says which resume this is: bazel build :resume or :short.
#let variant = sys.inputs.at("variant", default: "full")
#let full = variant == "full"

#show: resume.with(name: "Ada Example", keywords: (variant,))

#header(
  "Ada Example",
  link("https://example.com"),
  "ada@example.com",
)

= Experience

#entry([2021 -- present], title: [Staff Engineer], where: [Example Corp, Springfield])[
  Leads the build team. Moved the company's documents from LaTeX to Typst,
  and their builds from minutes to #metric[under a second].
]

#entry([2016 -- 2021], title: [Software Engineer], where: [Placeholder Inc, Shelbyville])[
  Wrote the service that renders invoices, #metric[40 million] a year, and
  the tests that say they still add up.
]

#if full [
  #entry([2014 -- 2016], title: [Junior Developer], where: [Sample & Sons, Ogdenville])[
    Kept a point-of-sale system running, and learned why builds should not
    depend on the machine they run on.
  ]
]

= Education

#entry([2010 -- 2014], title: [BSc, Computer Science], where: [University of Examples])[
  Thesis on reproducible builds.
]

#if full [
  = Projects

  #entry([2023], title: [lorem-lint])[
    A linter for placeholder text. Finds the lorem ipsum that shipped.
  ]
]

#footer[
  Updated #datetime.today().display("[month repr:long] [day padding:none], [year]")
]
