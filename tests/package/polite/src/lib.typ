// Imports another package, and reads a file from the top of this one.
#import "@local/greet:0.1.0": greet
#let polite(who) = greet(who) + json("/words.json").please
