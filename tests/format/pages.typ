#set page(width: 100pt, height: 60pt, margin: 10pt)

#for page in range(1, 13) {
  [Page #page]
  if page < 12 { pagebreak() }
}
