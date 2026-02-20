#!/usr/bin/env python3

import argparse
import json
import os
import re
from pathlib import Path


def _first_non_empty_line_after(lines: list[str], start_index: int) -> str | None:
    for i in range(start_index + 1, len(lines)):
        value = lines[i].strip()
        if value:
            return value
    return None


def _extract_api_credentials_from_postmaster_api_txt(path: Path) -> tuple[str | None, str | None]:
    if not path.exists():
        return None, None

    text = path.read_text(encoding="utf-8", errors="replace")
    lines = [line.rstrip("\n") for line in text.splitlines()]

    api_id: str | None = None
    api_hash: str | None = None

    for idx, line in enumerate(lines):
        normalized = line.strip().lower()

        if api_id is None and "api_id" in normalized:
            m = re.search(r"\bapi_id\b\s*[:=]\s*(\d+)", normalized)
            if m:
                api_id = m.group(1)
            else:
                candidate = _first_non_empty_line_after(lines, idx)
                if candidate and re.fullmatch(r"\d+", candidate.strip()):
                    api_id = candidate.strip()

        if api_hash is None and "api_hash" in normalized:
            m = re.search(r"\bapi_hash\b\s*[:=]\s*([0-9a-f]{32,})", normalized)
            if m:
                api_hash = m.group(1)
            else:
                candidate = _first_non_empty_line_after(lines, idx)
                if candidate and re.fullmatch(r"[0-9a-fA-F]{32,}", candidate.strip()):
                    api_hash = candidate.strip()

        if api_id is not None and api_hash is not None:
            break

    return api_id, api_hash


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="build-system/appstore-configuration.json")
    parser.add_argument("--output", default="build-system/ci-configuration.json")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    base_config = json.loads(input_path.read_text(encoding="utf-8"))

    api_id = os.environ.get("POSTMASTER_API_ID")
    api_hash = os.environ.get("POSTMASTER_API_HASH")

    if not api_id or not api_hash:
        extracted_id, extracted_hash = _extract_api_credentials_from_postmaster_api_txt(Path("postmaster_api.txt"))
        api_id = api_id or extracted_id
        api_hash = api_hash or extracted_hash

    if not api_id or not api_hash:
        raise SystemExit(
            "Missing API credentials. Set POSTMASTER_API_ID and POSTMASTER_API_HASH (recommended), "
            "or provide postmaster_api.txt locally."
        )

    base_config["api_id"] = str(api_id)
    base_config["api_hash"] = str(api_hash)

    # Sideload-friendly defaults (can still be overridden by editing the base config).
    base_config["is_internal_build"] = "true"
    base_config["is_appstore_build"] = "false"
    base_config["appstore_id"] = "0"
    base_config["premium_iap_product_id"] = ""
    base_config["enable_siri"] = False
    base_config["enable_icloud"] = False

    output_path.write_text(json.dumps(base_config, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

