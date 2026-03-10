#!/usr/bin/env python3

import argparse
import os
import shutil
import tempfile
import zipfile
from pathlib import Path


STRIP_FILE_NAMES = {
    "embedded.mobileprovision",
}

STRIP_DIR_NAMES = {
    "_CodeSignature",
    "SC_Info",
}

STRIP_SUFFIXES = (
    ".xcent",
    ".xcent.der",
)


def should_strip_file(path: Path) -> bool:
    if path.name in STRIP_FILE_NAMES:
        return True
    return any(path.name.endswith(suffix) for suffix in STRIP_SUFFIXES)


def strip_signing_artifacts(root: Path) -> None:
    for path in sorted(root.rglob("*"), key=lambda value: len(value.parts), reverse=True):
        if path.is_dir() and path.name in STRIP_DIR_NAMES:
            shutil.rmtree(path, ignore_errors=True)
        elif path.is_file() and should_strip_file(path):
            path.unlink(missing_ok=True)


def repackage_ipa(source_dir: Path, output_path: Path) -> None:
    with zipfile.ZipFile(output_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(source_dir.rglob("*")):
            if path.is_dir():
                continue
            archive.write(path, path.relative_to(source_dir))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    input_path = Path(args.input).resolve()
    output_path = Path(args.output).resolve()

    if not input_path.exists():
        raise SystemExit(f"Input IPA does not exist: {input_path}")

    with tempfile.TemporaryDirectory(prefix="postmaster_sideload_") as temp_dir:
        temp_root = Path(temp_dir)
        extracted_dir = temp_root / "extracted"
        extracted_dir.mkdir(parents=True, exist_ok=True)

        with zipfile.ZipFile(input_path, "r") as archive:
            archive.extractall(extracted_dir)

        payload_path = extracted_dir / "Payload"
        if not payload_path.exists():
            raise SystemExit(f"IPA payload is missing in {input_path}")

        strip_signing_artifacts(payload_path)

        output_path.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(
            prefix="postmaster_sideload_",
            suffix=".ipa",
            dir=output_path.parent,
            delete=False
        ) as temp_output_file:
            temp_output_path = Path(temp_output_file.name)

        try:
            repackage_ipa(extracted_dir, temp_output_path)
            os.replace(temp_output_path, output_path)
        finally:
            temp_output_path.unlink(missing_ok=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
