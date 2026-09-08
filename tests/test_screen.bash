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
    [ -z "$1" || -z "$2" ] && return 255
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

@test "reset_style reset any graphic renditions" {
  run reset_style
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[0m' ]
}

@test "bold sets bold rendition" {
  run bold
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[1m' ]
}

@test "dim sets dim rendition" {
  run dim
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[2m' ]
}

@test "italic sets italic rendition" {
  run italic
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[3m' ]
}

@test "underline sets underline rendition" {
  run underline
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[4m' ]
}

@test "reverse sets reverse rendition" {
  run reverse
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[7m' ]
}

@test "fg sets foreground color" {
  run fg 125
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[38;5;125m' ]
}

@test "bg sets background color" {
  run bg 125
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[48;5;125m' ]
}

@test "rgb_fg sets rgb foreground" {
  run rgb_fg 255 0 128
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[38;2;255;0;128m' ]
}

@test "rgb_bg sets rgb background" {
  run rgb_bg 255 0 128
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[48;2;255;0;128m' ]
}

@test "bell produces bell character" {
  run bell
  [ "$status" -eq 0 ]
  [ "$output" = $'\a' ]
}

@test "highlight applies reverse, prints text, resets" {
  run highlight hello
  [ "$status" -eq 0 ]
  [ "$output" = $'\e[7mhello\e[0m' ]
}

@test "screen_resize fill up the screen buffer with empty lines" {
  num_rows=10

  screen_resize $num_rows

  [ "$?" -eq 0 ]
  [ "${#SCREEN[@]}" -eq 10 ]

  while [ "$num_rows" -gt -1 ]; do
    num_rows=$(($num_rows - 1))
    [ "${SCREEN[$num_rows]}" = "" ]
  done
}

@test "screen_put adds string at correct position into screen buffer" {
  screen_resize 5
  screen_put 2 3 "hello"

  [ "$?" -eq 0 ]
  [ "${SCREEN[2]}" = "  hello" ]

  screen_put 4 1 "world"
  [ "${SCREEN[4]}" = "world" ]
  [ "$?" -eq 0 ]
}

@test "screen_get retrieves correct line from the screen buffer" {
  screen_resize 5
  SCREEN[3]="  foo"

  output=$(screen_get 3)
  [ "$?" -eq 0 ]
  [ "$output" = "  foo" ]

  output=$(screen_get 1)
  [ "$?" -eq 0 ]
  [ "$output" = "" ]
}

@test "screen_render prints each line in the screen buffer" {
  screen_resize 3
  screen_put 0 1 "alpha"
  screen_put 1 1 "mike"
  screen_put 2 1 "victor"

  run screen_render 1 1

  expected=$'\e[1;1Halpha\e[2;1Hmike\e[3;1Hvictor'

  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "selection_copy copy lines from screen buffer into selection buffer" {
  screen_resize 3
  screen_put 0 1 "alpha"
  screen_put 1 1 "mike"
  screen_put 2 1 "victor"

  selection_start=1
  selection_end=2

  selection_copy

  [ "$?" -eq 0 ]
  [ "${#selection_buffer}" -ne 0 ]
  [ "$selection_buffer" = $'mike\nvictor\n' ]
}

@test "selection_paste print lines yanked into the selection buffer" {
  screen_resize 3
  screen_put 0 1 "alpha"
  screen_put 1 1 "mike"
  screen_put 2 1 "victor"

  selection_start=0
  selection_end=1

  selection_copy
  run selection_paste 1 1

  expected=$'\e[1;1Halpha\nmike'

  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "print_newline outputs a newline" {
    stdout="$BATS_TEST_TMPDIR/terminal-output"

    print_newline > "$stdout"

    [ "$?" -eq 0 ]
    [ $(wc -c < "$stdout") -eq 1 ]
    [ "$(xxd -p "$stdout")" = "0a" ]
}

@test "prints prints argument without trailing newline" {
    run prints "hello"

    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}

@test "printsln prints argument with trailing newline" {
    stdout="$BATS_TEST_TMPDIR/terminal-output"

    printsln "world" > "$stdout"

    expected="$(echo world | xxd -p)"

    [ "$?" -eq 0 ]
    [ $(xxd -p < "$stdout") = "$expected" ]
}

@test "print_array_fmt joins array elements with separator" {
    myarr=(a b c)

    run print_array_fmt "myarr" ","

    [ "$status" -eq 0 ]
    [ "$output" = "a,b,c" ]
}

@test "print_array prints array starting at cursor position" {
    input="$BATS_TEST_TMPDIR/terminal-input"
    output="$BATS_TEST_TMPDIR/terminal-output"

    arr=(x y)

    printf '\033[7;25R' > "$input"

    run print_array "arr" "$input" "$output"

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[7;25Hx\e[8;25Hy' ]
}

@test "print_array_at prints each array element at given coordinates" {
    arr=(foo bar)

    run print_array_at "2" "3" "arr"

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[2;3Hfoo\e[3;3Hbar' ]
}

@test "print_var_at prints variable content at coordinates" {
    var="testvar"

    run print_var_at "5" "5" "$var"


    [ "$status" -eq 0 ]
    [ "$output" = $'\e[5;5Htestvar' ]
}

@test "print_file_at prints each line of a file at coordinates" {
    tmpdir=$(mktemp -d)
    cat > "${tmpdir}/file.txt" <<EOF
line1
line2
line3
EOF
    run print_file_at "1" "1" "${tmpdir}/file.txt"

    [ "$output" = $'\e[1;1Hline1\e[2;1Hline2\e[3;1Hline3' ]
    rm -rf "$tmpdir"
}

@test "repeat_char repeats a character the requested number of times" {
    run repeat_char "*" 5

    [ "$status" -eq 0 ]
    [ "$output" = "*****" ]
}

@test "repeat_char returns an empty string for zero repetitions" {
    run repeat_char "x" 0

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "indent adds spaces before text" {
    run indent 4 "hello"

    [ "$status" -eq 0 ]
    [ "$output" = "    hello" ]
}

@test "indent does not add spaces when indentation is zero" {
    run indent 0 "hello"

    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}

@test "pad_right pads text on the right to the requested width" {
    run pad_right "cat" 6

    [ "$status" -eq 0 ]
    [ "$output" = "cat   " ]
}

@test "pad_right does not truncate text wider than the requested width" {
    run pad_right "elephant" 4

    [ "$status" -eq 0 ]
    [ "$output" = "elephant" ]
}

@test "pad_left pads text on the left to the requested width" {
    run pad_left "cat" 6

    [ "$status" -eq 0 ]
    [ "$output" = "   cat" ]
}

@test "pad_left does not truncate text wider than the requested width" {
    run pad_left "elephant" 4

    [ "$status" -eq 0 ]
    [ "$output" = "elephant" ]
}

@test "center adds left padding based on the requested width" {
    stdout="$BATS_TEST_TMPDIR/terminal-output"

    center 10 "cat" > "$stdout"

    [ "$?" -eq 0 ]
    [ "$(cat  "$stdout")" = "   cat" ]
}

@test "center uses integer division for odd remaining space" {
    run center 9 "cat"

    [ "$status" -eq 0 ]
    [ "$output" = "   cat" ]
}

@test "align_right aligns text to the right edge of the requested width" {
    run align_right 8 "hi"

    [ "$status" -eq 0 ]
    [ "$output" = "      hi" ]
}

@test "align_right does not truncate text wider than the requested width" {
    run align_right 3 "hello"

    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}

@test "margin_left adds a margin before text" {
    run margin_left 3 "hello"

    [ "$status" -eq 0 ]
    [ "$output" = "   hello" ]
}

@test "margin_left joins multiple arguments with spaces" {
    run margin_left 2 hello world

    [ "$status" -eq 0 ]
    [ "$output" = "  hello world" ]
}

@test "margin_left does not add spaces when the margin is zero" {
    run margin_left 0 "hello world"

    [ "$status" -eq 0 ]
    [ "$output" = "hello world" ]
}

@test "print_hline prints the requested number of heavy horizontal characters" {
    run print_hline 5

    [ "$status" -eq 0 ]
    [ "$output" = "━━━━━" ]
}

@test "print_hline prints one character for a length of one" {
    run print_hline 1

    [ "$status" -eq 0 ]
    [ "$output" = "━" ]
}

@test "print_vline defaults to a height of one" {
    run print_vline

    [ "$status" -eq 0 ]
    [ "$output" = "┃" ]
}

@test "print_vline prints the requested number of heavy vertical characters" {
    run print_vline 4

    [ "$status" -eq 0 ]
    [ "$output" = "┃┃┃┃" ]
}

@test "print_ul prints the upper-left corner" {
    run print_ul

    [ "$status" -eq 0 ]
    [ "$output" = "┏" ]
}

@test "print_ur prints the upper-right corner" {
    run print_ur

    [ "$status" -eq 0 ]
    [ "$output" = "┓" ]
}

@test "print_ll prints the lower-left corner" {
    run print_ll

    [ "$status" -eq 0 ]
    [ "$output" = "┗" ]
}

@test "print_lr prints the lower-right corner" {
    run print_lr

    [ "$status" -eq 0 ]
    [ "$output" = "┛" ]
}

@test "print_box prints a box at the default position" {
    run print_box "Hi"

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[1;1H┏━━━━┓\n\e[2;1H┃ Hi ┃\n\e[3;1H┗━━━━┛' ]
}

@test "print_box prints a box at the specified row and column" {
    run print_box 4 7 "OK"

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[4;7H┏━━━━┓\n\e[5;7H┃ OK ┃\n\e[6;7H┗━━━━┛' ]
}

@test "print_box supports specifying only the row" {
    run print_box 3 "Test"

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[3;1H┏━━━━━━┓\n\e[4;1H┃ Test ┃\n\e[5;1H┗━━━━━━┛' ]
}

@test "print_box preserves spaces in the box content" {
    run print_box 2 5 "hello world"

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[2;5H┏━━━━━━━━━━━━━┓\n\e[3;5H┃ hello world ┃\n\e[4;5H┗━━━━━━━━━━━━━┛' ]
}

@test "assoc_array_find succeeds when an associative-array value exists" {
    declare -A fruits=(
        [red]="Strawberry"
        [yellow]="Banana"
        [purple]="Grape"
    )

    run assoc_array_find fruits "Banana"

    [ "$status" -eq 0 ]
}

@test "assoc_array_find fails when an associative-array value does not exist" {
    declare -A fruits=(
        [red]="Strawberry"
        [yellow]="Banana"
        [purple]="Grape"
    )

    run assoc_array_find fruits "Mango"

    [ "$status" -ne 0 ]
}

@test "assoc_array_find finds the first associative-array value" {
    declare -A fruits=(
        [red]="Strawberry"
        [yellow]="Banana"
    )

    run assoc_array_find fruits "Strawberry"

    [ "$status" -eq 0 ]
}

@test "assoc_array_find finds the last associative-array value" {
    declare -A fruits=(
        [red]="Strawberry"
        [yellow]="Banana"
        [purple]="Grape"
    )

    run assoc_array_find fruits "Grape"

    [ "$status" -eq 0 ]
}

@test "assoc_array_find handles an empty associative array" {
    declare -A values=()

    run assoc_array_find values "missing"

    [ "$status" -ne 0 ]
}

@test "assoc_array_find does not match a partial value" {
    declare -A fruits=(
        [red]="Strawberry"
        [yellow]="Banana"
    )

    run assoc_array_find fruits "App"

    [ "$status" -ne 0 ]
}

@test "indexed_array_find succeeds when an element exists" {
    items=("Strawberry" "Banana" "Cherry")

    run indexed_array_find items "Banana"

    [ "$status" -eq 0 ]
}

@test "indexed_array_find fails when an element does not exist" {
    items=("Strawberry" "Banana" "Cherry")

    run indexed_array_find items "Mango"

    [ "$status" -ne 0 ]
}

@test "indexed_array_find finds the first element" {
    items=("Strawberry" "Banana" "Cherry")

    run indexed_array_find items "Strawberry"

    [ "$status" -eq 0 ]
}

@test "indexed_array_find finds the last element" {
    items=("Strawberry" "Banana" "Cherry")

    run indexed_array_find items "Cherry"

    [ "$status" -eq 0 ]
}

@test "indexed_array_find handles an empty indexed array" {
    items=()

    run indexed_array_find items "Strawberry"

    [ "$status" -ne 0 ]
}

@test "indexed_array_find supports values containing spaces" {
    items=("Red Strawberry" "Green Pear" "Yellow Banana")

    run indexed_array_find items "Green Pear"

    [ "$status" -eq 0 ]
}

@test "indexed_array_find does not match a partial value" {
    items=("Strawberry" "Banana" "Cherry")

    run indexed_array_find items "App"

    [ "$status" -ne 0 ]
}

@test "indexed_array_find succeeds when duplicate elements exist" {
    items=("Strawberry" "Banana" "Strawberry")

    run indexed_array_find items "Strawberry"

    [ "$status" -eq 0 ]
}

@test "remove_assoc_array_item removes an existing value" {
    declare -A fruits=(
        [red]="Strawberry"
        [yellow]="Banana"
        [purple]="Grape"
    )

    remove_assoc_array_item fruits "Banana"

    [ -n "${fruits[red]+present}" ]
    [ -z "${fruits[yellow]+present}" ]
    [ -n "${fruits[purple]+present}" ]
    [ "${#fruits[@]}" -eq 2 ]
}

@test "remove_assoc_array_item removes the value with spaces" {
    declare -A fruits=(
        [first]="Red Strawberry"
        [second]="Green Pear"
        [third]="Yellow Banana"
    )

    remove_assoc_array_item fruits "Green Pear"

    [ -n "${fruits[first]+present}" ]
    [ -z "${fruits[second]+present}" ]
    [ -n "${fruits[third]+present}" ]
    [ "${#fruits[@]}" -eq 2 ]
}

@test "remove_assoc_array_item does nothing when the value is absent" {
    declare -A fruits=(
        [red]="Strawberry"
        [yellow]="Banana"
        [purple]="Grape"
    )

    remove_assoc_array_item fruits "Mango"

    [ "${#fruits[@]}" -eq 3 ]
    [ "${fruits[red]}" = "Strawberry" ]
    [ "${fruits[yellow]}" = "Banana" ]
    [ "${fruits[purple]}" = "Grape" ]
}

@test "remove_assoc_array_item removes only one duplicate value" {
    declare -A fruits=(
        [first]="Strawberry"
        [second]="Banana"
        [third]="Strawberry"
    )

    remove_assoc_array_item fruits "Strawberry"

    [ "${#fruits[@]}" -eq 2 ]

    echo "${fruits[@]}"
    echo "${!fruits[@]}"

    strawberry_count=0
    for key in "${!fruits[@]}"; do
        [ "${fruits[$key]}" = "Strawberry" ] && \
          strawberry_count=$(($strawberry_count + 1))
    done

    echo "$strawberry_count"
    [ "$strawberry_count" -eq 1 ]
}

@test "remove_assoc_array_item removes an empty value" {
    declare -A values=(
        [empty]=""
        [present]="value"
    )

    remove_assoc_array_item values ""

    [ -z "${values[empty]+present}" ]
    [ -n "${values[present]+present}" ]
    [ "${#values[@]}" -eq 1 ]
}

@test "remove_assoc_array_item preserves the associative-array keys of remaining entries" {
    declare -A colors=(
        [primary]="Red"
        [secondary]="Blue"
        [neutral]="Gray"
    )

    remove_assoc_array_item colors "Blue"

    [ -n "${colors[primary]+present}" ]
    [ -z "${colors[secondary]+present}" ]
    [ -n "${colors[neutral]+present}" ]
}

@test "remove_indexed_array_item removes the first matching element" {
    items=("Strawberry" "Banana" "Cherry")

    remove_indexed_array_item items "Banana"

    [ "${items[0]}" = "Strawberry" ]
    [ -z "${items[1]+present}" ]
    [ "${items[2]}" = "Cherry" ]
    [ "${#items[@]}" -eq 2 ]
}

@test "remove_indexed_array_item removes only the first duplicate" {
    items=("Strawberry" "Banana" "Banana" "Cherry")

    remove_indexed_array_item items "Banana"

    [ "${items[0]}" = "Strawberry" ]
    [ -z "${items[1]+present}" ]
    [ "${items[2]}" = "Banana" ]
    [ "${items[3]}" = "Cherry" ]
    [ "${#items[@]}" -eq 3 ]
}

@test "remove_indexed_array_item does nothing when the element is absent" {
    items=("Strawberry" "Banana" "Cherry")

    remove_indexed_array_item items "Mango"

    [ "${items[0]}" = "Strawberry" ]
    [ "${items[1]}" = "Banana" ]
    [ "${items[2]}" = "Cherry" ]
    [ "${#items[@]}" -eq 3 ]
}

@test "remove_indexed_array_item matches the complete element" {
    items=("Strawberry" "Pineapple" "Banana")

    remove_indexed_array_item items "Straw"

    [ "${items[0]}" = "Strawberry" ]
    [ "${items[1]}" = "Pineapple" ]
    [ "${items[2]}" = "Banana" ]
    [ "${#items[@]}" -eq 3 ]
}

@test "remove_indexed_array_item supports elements containing spaces" {
    items=("Red Strawberry" "Green Pear" "Yellow Banana")

    remove_indexed_array_item items "Green Pear"

    [ "${items[0]}" = "Red Strawberry" ]
    [ -z "${items[1]+present}" ]
    [ "${items[2]}" = "Yellow Banana" ]
    [ "${#items[@]}" -eq 2 ]
}

@test "term_size prints terminal rows and columns" {
    # Mock tput so the test does not depend on an actual terminal.
    tput() {
        case "$1" in
            lines) printf "24" ;;
            cols)  printf "80" ;;
        esac
    }

    run term_size

    [ "$status" -eq 0 ]
    [ "$output" = "24 80" ]
}

@test "reserve_space reserves the requested number of lines" {
    actual="$(mktemp)"
    expected="$(mktemp)"

    reserve_space 3 >"$actual"
    printf '\e7\n\n\n' >"$expected"

    [ "$__RESERVED_LINES" -eq 3 ]
    cmp "$expected" "$actual"

    rm -f "$actual" "$expected"
}

@test "reserve_space defaults to ten lines" {
    actual="$(mktemp)"
    expected="$(mktemp)"

    reserve_space >"$actual"
    printf '\e7\n\n\n\n\n\n\n\n\n\n' >"$expected"

    [ "$__RESERVED_LINES" -eq 10 ]
    cmp "$expected" "$actual"

    rm -f "$actual" "$expected"
}

@test "release_space clears and removes all reserved lines" {
    __RESERVED_LINES=2

    run release_space

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[2K\e[1A\e[2K\e[1A\e[2K\e8' ]
}

@test "release_space handles zero reserved lines" {
    __RESERVED_LINES=0

    run release_space

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[2K\e8' ]
}

@test "insert_lines inserts one line by default" {
    run insert_lines

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[1L' ]
}

@test "insert_lines inserts the requested number of lines" {
    run insert_lines 4

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[4L' ]
}

@test "delete_lines deletes one line by default" {
    run delete_lines

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[1M' ]
}

@test "delete_lines deletes the requested number of lines" {
    run delete_lines 3

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[3M' ]
}

@test "scroll_down scrolls down one line by default" {
    run scroll_down

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[1T' ]
}

@test "scroll_down scrolls down the requested number of lines" {
    run scroll_down 5

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[5T' ]
}

@test "scroll_up scrolls up one line by default" {
    run scroll_up

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[1S' ]
}

@test "scroll_up scrolls up the requested number of lines" {
    run scroll_up 2

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[2S' ]
}

@test "viewport_begin sets the scrolling region and moves to its first row" {
    run viewport_begin 3 20

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[3;20r\e[3;1H' ]
}

@test "viewport_end resets the scrolling region" {
    run viewport_end

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[r' ]
}

@test "push_screen pushes the screen by the requested number of lines" {
    run push_screen 3

    [ "$status" -eq 0 ]
    [ "$output" = $'\n\n\n\e[3A' ]
}

@test "pop_screen clears and removes the requested number of lines" {
    run pop_screen 2

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[2K\e[1A\e[2K\e[1A\e[2K' ]
}

@test "screen_enter switches to the alternate screen and hides the cursor" {
    run screen_enter

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[?1049h\e[?25l\e[2J\e[H' ]
}

@test "screen_leave clears the screen and restores the normal screen" {
    run screen_leave

    [ "$status" -eq 0 ]
    [ "$output" = $'\e[2J\e[?25h\e[?1049l' ]
}

@test "is_sourced reports that the functions file was sourced" {
    run is_sourced

    [ "$status" -eq 0 ]
}
