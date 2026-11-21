"""The Typst releases the module extension can download.

Each release maps the target triples it was built for to the SHA-256 of
that archive, as GitHub reports it on the release page.
"""

VERSIONS = {
    "0.15.1": {
        "aarch64-apple-darwin": "48f62ed034aa3a7978309579ac6ca00045e2ef0da73114e8af27cfd8e74dc05a",
        "aarch64-pc-windows-msvc": "4ab28e1b71ec3184d38d580ab797f499b6770d952b6b19167be5cea5c2662e14",
        "aarch64-unknown-linux-musl": "5aa8d74a3d906e60ea12a66ac2f37f8eef1b14cbad7182a745e393a10c23dcee",
        "armv7-unknown-linux-musleabi": "44986312e557b9ac0f2c71d5d5156c0ad93b2da374d54c859d6c0c7c0b73709f",
        "riscv64gc-unknown-linux-gnu": "ec735f732c6a9940c4ef08223b50404396537ad34713eb883ef3bb310b396e5a",
        "x86_64-apple-darwin": "7f9fdd9584866245de9a79e0add8f9236fae6f40a8a45e2c4771ccc14db4e0fa",
        "x86_64-pc-windows-msvc": "19ce3551153c2fe7ee9fa2f95208310c8f4d3209fedb699e0333faf8913f6736",
        "x86_64-unknown-linux-musl": "a6d077d0a95eed5a2eba715b2dae06be954f624ccbf85758a03f389ded33118c",
    },
}

# The machine each target triple runs on, as constraints under @platforms.
PLATFORMS = {
    "aarch64-apple-darwin": ["os:macos", "cpu:aarch64"],
    "aarch64-pc-windows-msvc": ["os:windows", "cpu:aarch64"],
    "aarch64-unknown-linux-musl": ["os:linux", "cpu:aarch64"],
    "armv7-unknown-linux-musleabi": ["os:linux", "cpu:armv7"],
    "riscv64gc-unknown-linux-gnu": ["os:linux", "cpu:riscv64"],
    "x86_64-apple-darwin": ["os:macos", "cpu:x86_64"],
    "x86_64-pc-windows-msvc": ["os:windows", "cpu:x86_64"],
    "x86_64-unknown-linux-musl": ["os:linux", "cpu:x86_64"],
}
