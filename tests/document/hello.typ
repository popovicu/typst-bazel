// Reads a file beside it, a file in another package, and a generated one.
#import "parts/part.typ": part
#import "/tests/shared/shout.typ": shout
#let made = json("made.json")

#set document(title: shout(part) + " " + made.by)

= Hello
