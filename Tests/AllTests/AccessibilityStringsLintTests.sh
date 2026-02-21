#!/usr/bin/env bash
set -euo pipefail

workspace_root="${TEST_SRCDIR}/${TEST_WORKSPACE}"

chat_history_file="${workspace_root}/submodules/TelegramUI/Sources/ChatHistoryListNode.swift"

if [[ ! -f "${chat_history_file}" ]]; then
  echo "Expected file not found: ${chat_history_file}"
  exit 1
fi

if grep -n -F "Scroll history" "${chat_history_file}"; then
  echo "Forbidden hardcoded English accessibility label found in ChatHistoryListNode.swift"
  exit 1
fi

exit 0
