"""Reading a lock file."""

def read_pins(text):
    """What a lock file pins.

    Args:
      text: what the file says.

    Returns:
      Each name:version to its sha256 and deps, or None if the text is
      not what the lock command writes: half a merge, say.
    """
    pins = json.decode(text, default = None)
    if type(pins) != "dict":
        return None
    for pin in pins.values():
        if type(pin) != "dict" or type(pin.get("sha256")) != "string" or type(pin.get("deps")) != "list":
            return None
    return pins
