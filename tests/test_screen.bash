#!./tools/bats/bin/bats

setup() {
  source "$BATS_TEST_DIRNAME/../src/screen.bash"
}

@test "cursor_position reads cursor coordinates" {
  input="$BATS_TEST_TMPDIR/terminal-input"
  output="$BATS_TEST_TMPDIR/terminal-output"

  printf '\033[7;25R' > "$input"

  run cursor_position "$input" "$output"

  [ "$status" -eq 0 ]
  [ "$output" = "7 25" ]
}

@test "cursor_up moves the cursor up by given number of lines, 1 by default" {
  run cursor_up

  [ "$status" -eq 0 ]
  [ "$output" = $'\033[1A' ]

  run cursor_up 10

  [ "$status" -eq 0 ]
  [ "$output" = $'\033[10A' ]
}

@test "cursor_down moves the cursor down by given number of lines, 1 by default" {
  run cursor_down
  [ "$status" -eq 0 ]
  [ "$output" = $'\033[1B' ]
  run cursor_down 5
  [ "$status" -eq 0 ]
  [ "$output" = $'\033[5B' ]
}

@test "cursor_right moves the cursor right by given number of columns, 1 by default" {
  run cursor_right
  [ "$status" -eq 0 ]
  [ "$output" = $'\033[1C' ]
  run cursor_right 3
  [ "$status" -eq 0 ]
  [ "$output" = $'\033[3C' ]
}

@test "cursor_left moves the cursor left by given number of columns, 1 by default" {
  run cursor_left
  [ "$status" -eq 0 ]
  [ "$output" = $'\033[1D' ]
  run cursor_left 2
  [ "$status" -eq 0 ]
  [ "$output" = $'\033[2D' ]
}

@test "cursor_home moves the cursor to the upper‑left corner" {
  run cursor_home
  [ "$status" -eq 0 ]
  [ "$output" = $'\033[H' ]
}

@test "cursor_save saves the current cursor position" {
  run cursor_save
  [ "$status" -eq 0 ]
  [ "$output" = $'\0337' ]
}

@test "cursor_restore restores the saved cursor position" {
  run cursor_restore
  [ "$status" -eq 0 ]
  [ "$output" = $'\0338' ]
}

@test "cursor_hide hides the cursor" {
  run cursor_hide
  [ "$status" -eq 0 ]
  [ "$output" = $'\033[?25l' ]
}

@test "cursor_show shows the cursor" {
  run cursor_show
  [ "$status" -eq 0 ]
  [ "$output" = $'\033[?25h' ]
}

@test "cursor_move moves the cursor to given coordinates" {
  run cursor_move 7 25

  [ "$status" -eq 0 ]
  [ "$output" = $'\033[7;25H' ]
}

@test "clear_line clears the line" {
  run clear_line

  [ "$status" -eq 0 ]
  [ "$output" = $'\033[2K' ]
}

@test "clear_eol clears from cursor to end of line" {
  run clear_eol

  [ "$status" -eq 0 ]
  [ "$output" = $'\033[K' ]
}

@test "clear_bol clears from beginning of line to cursor" {
  run clear_bol

  [ "$status" -eq 0 ]
  [ "$output" = $'\033[1K' ]
}

@test "clear_down clears from cursor down to end of screen" {
  run clear_down

  [ "$status" -eq 0 ]
  [ "$output" = $'\033[J' ]
}

@test "clear_up clears from cursor up to top of screen" {
  run clear_up

  [ "$status" -eq 0 ]
  [ "$output" = $'\033[1J' ]
}

@test "print_at prints the expected message at expected cursor position" {
  run print_at 7 25 "bats-test"

  expected=$'\033[7;25Hbats-test'

  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "prinft_at prints the formatted, expected message at expected cursor position" {
  run printf_at 7 25 "%s-%s %d" "bats" "test" "1"

  expected=$'\033[7;25Hbats-test 1'

  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "read_key read key sequences and print them" {
  input="$BATS_TEST_TMPDIR/terminal-input"

  printf $'\033[Z' > "$input"

  run read_key "$input"

  [ "$status" -eq 0 ]
  [ "$output" = $'\033[Z' ]

  printf $'\033[A' > "$input"

  run read_key "$input" "$output"

  [ "$status" -eq 0 ]
  [ "$output" = $'\e[A' ]

  printf "" > "$input"

  run read_key "$input" "$output"

  [ "$status" -eq 0 ]
  [ "$output" = "enter" ]

  printf ' ' > "$input"

  run read_key "$input" "$output"

  [ "$status" -eq 0 ]
  [ "$output" = "space" ]
}

register_key() {
    [[ -z "$1" || -z "$2" ]] && return 255
    key_functions["$1"]="$2"
}

@test "register_key register handler function for a key sequence" {
  register_key "key_up" "fn1"
  [ "$?" -eq 0 ]
  [ "${#key_functions[@]}" -eq 1 ]
  [ "${key_functions[key_up]}" = "fn1" ]

  register_key "key_down" "fn2"
  [ "$?" -eq 0 ]
  [ "${#key_functions[@]}" -eq 2 ]
  [ "${key_functions[key_down]}" = "fn2" ]

  register_key "key_enter" "fn3"
  [ "$?" -eq 0 ]
  [ "${#key_functions[@]}" -eq 3 ]
  [ "${key_functions[key_enter]}" = "fn3" ]

  register_key "key_tab" "fn4"
  [ "$?" -eq 0 ]
  [ "${#key_functions[@]}" -eq 4 ]
  [ "${key_functions[key_tab]}" = "fn4" ]
}

@test "key_dispatch read key sequence and dispatch corresponding handler function" {
  fn1() {
    echo -n "fn1"
  }
  register_key "key_up" "fn1"

  fn2() {
    echo -n "fn2"
  }
  register_key "key_down" "fn2"

  fn3() {
    echo -n "fn3"
  }
  register_key "key_enter" "fn3"

  fn4() {
    echo -n "fn4"
  }
  register_key "key_tab" "fn4"

  input="$BATS_TEST_TMPDIR/terminal-input"

  printf $'\033[A' > "$input"
  run key_dispatch "$input"

  [ "$status" -eq 0 ]
  [ "$output" = "fn1" ]

  printf $'\033[B' > "$input"
  run key_dispatch "$input"

  [ "$status" -eq 0 ]
  [ "$output" = "fn2" ]

  printf "" > "$input"
  run key_dispatch "$input"

  [ "$status" -eq 0 ]
  [ "$output" = "fn3" ]

  printf $'\t' > "$input"
  run key_dispatch "$input"

  [ "$status" -eq 0 ]
  [ "$output" = "fn4" ]
}

@test "prompt print a prompt and read the entered text" {
  input="$BATS_TEST_TMPDIR/terminal-input"

  printf "this is a bats-core test for prompt()\n" > "$input"

  prompt output "bats-core test prompt: " "$input"

  [ "$?" -eq 0 ]
  [ "$output" = "this is a bats-core test for prompt()" ]
}
