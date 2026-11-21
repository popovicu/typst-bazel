// The look of a resume: a template, and the blocks a resume is made of.

#let accent = rgb("#1f4e79")
#let date-column = 4cm

// Wraps the whole document: #show: resume.with(name: "...").
#let resume(name: none, keywords: (), body) = {
  set document(title: "Resume - " + name, author: name, keywords: keywords)
  set page(
    paper: "us-letter",
    margin: (left: 2cm, right: 2cm, top: 1.7cm, bottom: 2cm),
  )
  set text(font: "New Computer Modern", size: 9pt, hyphenate: false)
  set par(justify: true, leading: 0.85em, spacing: 0.85em)
  show link: set text(fill: accent)

  // A section is a heading, so that it is one in the PDF's outline too.
  show heading: it => block(above: 1.6em, below: 1.5em, {
    text(size: 12pt, weight: "regular", fill: accent, it.body)
    v(-0.5em)
    line(length: 100%, stroke: 0.4pt + accent)
  })
  body
}

#let header(name, ..contact) = grid(
  columns: (1fr, auto),
  inset: (left: 6pt),
  text(size: 15pt, fill: accent, name),
  align(right, contact.pos().join(linebreak())),
)

// A number worth noticing inside a description.
#let metric(body) = text(size: 0.9em, weight: "bold", body)

// One row: dates on the left, in the font the library brings; title,
// place and description on the right.
#let entry(when, title: none, where: none, body) = block(
  breakable: false,
  below: 0.85em,
  grid(
    columns: (date-column, 1fr),
    column-gutter: 12pt,
    inset: (left: 6pt),
    text(font: "Fira Mono", size: 0.85em, when),
    {
      if title != none {
        text(size: 9.5pt, weight: "bold", fill: accent, title)
        if where != none { h(5mm); text(fill: accent, where) }
        linebreak()
      }
      body
    },
  ),
)
