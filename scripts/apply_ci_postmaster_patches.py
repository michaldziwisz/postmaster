#!/usr/bin/env python3

from pathlib import Path


def replace_once(text: str, old: str, new: str, path: Path) -> str:
    if new in text:
        return text
    if old not in text:
        raise SystemExit(f"Could not find expected snippet in {path}")
    return text.replace(old, new, 1)


def patch_codesigningtool(repo_root: Path) -> None:
    path = repo_root / "build-system" / "bazel-rules" / "rules_apple" / "tools" / "codesigningtool" / "codesigningtool.py"
    text = path.read_text(encoding="utf-8")
    patched = replace_once(
        text,
        """def _parse_mobileprovision_file(mobileprovision_file):\n  \"\"\"Reads and parses a mobileprovision file.\"\"\"\n  plist_xml = subprocess.check_output([\n      \"security\",\n      \"cms\",\n      \"-D\",\n      \"-i\",\n      mobileprovision_file,\n  ])\n  return plist_from_bytes(plist_xml)\n""",
        """def _parse_mobileprovision_file(mobileprovision_file):\n  \"\"\"Reads and parses a mobileprovision file.\"\"\"\n  with open(mobileprovision_file, \"rb\") as mobileprovision:\n    raw_content = mobileprovision.read()\n\n  if raw_content.startswith(b\"<?xml\"):\n    return plist_from_bytes(raw_content)\n\n  plist_xml = subprocess.check_output([\n      \"security\",\n      \"cms\",\n      \"-D\",\n      \"-i\",\n      mobileprovision_file,\n  ])\n  return plist_from_bytes(plist_xml)\n""",
        path,
    )
    if patched != text:
        path.write_text(patched, encoding="utf-8")


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    patch_codesigningtool(repo_root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
