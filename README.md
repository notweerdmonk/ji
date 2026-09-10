# ji

**A minimal terminal todo list manager**

This bash script is a minimal terminal action item tracker. It loads action
items from a text file. Navigate and mark any item as complete. The updated list
is written back to the same file.

Utilizes another bash script, `screen.bash` as the terminal rendering and
keyboard input framework.

An installation script is also provided that can either create symlinks or copy
over the installation package items to supplied path. The items can also be
cataloged in an XML manifest.

## Usage

```console
Usage: ji [-q] [-l] [-m markdown-file] file

Options

	-q	Do not print remaining action items
	-l	List only, do not update todo items
	-m	Write todo list to a Markdown file
	-h	Display this message

Upon update of a todo item, the list gets written back to the todo list file.
Listing the items only does not modify the file.

Key bindings

	Up/Down arrow keys	Cycle all items under a parent todo item
	Right arrow key		Expand current todo item
	Left arrow key		Collapse current todo item
	k/j			Cycle all items under a parent todo item
	l			Expand current todo item
	j			Collapse current todo item
	Tab			Expand current todo item
	S-Tab			Collapse current todo item
	Enter key		Mark current todo item as completed
	Spacebar		Mark current todo item as completed
	q			Quit updating todo items without saving
	Ctrl - C		Quit updating todo items without saving
```

## Testing

The `screen.bash` script is tested using `bats-core` testing automation
framework. It is included as a submodule under the `tools/` subdirectory.

## License

[UNLICENSE](/UNLICENSE)
