#!/usr/bin/env bash
# Тесты для convert.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONVERT="$SCRIPT_DIR/convert.sh"
PASS=0; FAIL=0; TOTAL=0

# --- Helpers ---
setup() {
  TMPDIR="$(mktemp -d)"
  cat > "$TMPDIR/test.md" <<'EOF'
# Test Document
Some text paragraph.

## Section 1
Content of section 1 with **bold** and *italic*.

| Col A | Col B |
|-------|-------|
| 1     | 2     |

## Section 2
More content here.

```python
def hello():
    print("world")
```

## Section 3 — Filler for multi-page

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit.

At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi.

## Section 4
Final section with more text to push to page 2.

Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur. Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur.
EOF
}

teardown() { rm -rf "$TMPDIR"; }

assert_ok() {
  local name="$1"; shift; TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1)); echo "FAIL: $name"
  fi
}

assert_fail() {
  local name="$1"; shift; TOTAL=$((TOTAL + 1))
  if ! "$@" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1)); echo "FAIL: $name (expected failure)"
  fi
}

assert_file_exists() {
  local name="$1" file="$2"; TOTAL=$((TOTAL + 1))
  if [ -f "$file" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1)); echo "FAIL: $name — file not found: $file"
  fi
}

assert_file_size_gt() {
  local name="$1" file="$2" min_size="$3"; TOTAL=$((TOTAL + 1))
  local size; size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
  if [ "$size" -gt "$min_size" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1)); echo "FAIL: $name — size $size <= $min_size"
  fi
}

# --- Тесты ---

# 1. Базовая конвертация
test_basic() {
  setup
  assert_ok "basic conversion runs" bash "$CONVERT" -i "$TMPDIR/test.md" -o "$TMPDIR/out.pdf"
  assert_file_exists "basic output exists" "$TMPDIR/out.pdf"
  assert_file_size_gt "basic output not empty" "$TMPDIR/out.pdf" 1000
  teardown
}

# 2. Дефолтное имя выхода
test_default_output() {
  setup
  assert_ok "default output name" bash "$CONVERT" -i "$TMPDIR/test.md"
  assert_file_exists "default .pdf exists" "$TMPDIR/test.pdf"
  teardown
}

# 3. Все темы
test_themes() {
  for theme in professional modern academic dark minimal; do
    setup
    assert_ok "theme $theme" bash "$CONVERT" -i "$TMPDIR/test.md" -o "$TMPDIR/$theme.pdf" -t "$theme"
    assert_file_exists "theme $theme output" "$TMPDIR/$theme.pdf"
    teardown
  done
}

# 4. Невалидная тема
test_invalid_theme() {
  setup
  assert_fail "invalid theme fails" bash "$CONVERT" -i "$TMPDIR/test.md" -t nonexistent
  teardown
}

# 5. Без входного файла
test_no_input() {
  assert_fail "no input fails" bash "$CONVERT"
}

# 6. Несуществующий входной файл
test_missing_input() {
  assert_fail "missing input fails" bash "$CONVERT" -i /tmp/nonexistent_file_12345.md
}

# 7. Landscape ориентация
test_landscape() {
  setup
  assert_ok "landscape flag" bash "$CONVERT" -i "$TMPDIR/test.md" -o "$TMPDIR/land.pdf" -l
  assert_file_exists "landscape output" "$TMPDIR/land.pdf"
  teardown
}

# 8. Landscape + тема
test_landscape_with_theme() {
  setup
  assert_ok "landscape+theme" bash "$CONVERT" -i "$TMPDIR/test.md" -o "$TMPDIR/lt.pdf" -t modern -l
  assert_file_exists "landscape+theme output" "$TMPDIR/lt.pdf"
  teardown
}

# 9. Справка
test_help() {
  assert_ok "help flag" bash "$CONVERT" -h
}

# --- Run ---
test_basic
test_default_output
test_themes
test_invalid_theme
test_no_input
test_missing_input
test_landscape
test_landscape_with_theme
test_help

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
