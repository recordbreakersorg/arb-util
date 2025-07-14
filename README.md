# arb-util

When managing application code, with layout and so stuff, having to handle additionaly
arb translation files can be a real burden, especially when it involves several languages.

this helps you to solve this via a few operations, done in a loop every 5 seconds.

1. Text translations extraction
   It is somehow common to use _"..." strings to mark strings for translations when using
   tools like gettext, `arb-util` uses this to detect what should be sent to arb files.
   - Goes through all the `.dart` files in ```$(project.root)/lib``` and searches for
     _"..." strings(Take note of the double quote).
   - generates a valid dart variable name of the text, like _helloWorld_ then add's
     the key and it's string value to the [template-arb-file], the latter auto-sync will
     do add it in the other files.
   - then replaces the string in the original file with `AppLocalizations` call.
2. Arb files synchronization
   - Goes through all the arb files and copies every missing key to the other, prepending
     with a '#'.
3. Rebuld localizations
   - If the arb files mtime have changed it runs
     using `flutter gen-l10n --project-dir=$(project.root)``.

## Usage

First, make sure you have julia installed, or install from <https://julialang.com/download>.
You can clone the repo with:

- `git clone https://github.com/recordbreakersorg/arb-util.git`
- `gh repo clone recordbreakersorg/arb-util`

Then to run the script, run the app change working directory to your project root.

### Running with Julia JIT

if you have fish run:
`/path/to/repo/manage.fish run`
else manually run:
`julia /path/ro/repo/src/main.jl`

### Precompiling

With julia installed, go to the cloned project and run:
`./manage.fish compile`, runs on my low-end pc in _11m 15s_ seconds and produces an ~224.9MB
executable.
Then running `./manage.fish run` will detect the executable and use it.

> !NOTE:
> adding the compiled executable to path may result in errors. Prefer creating a shell
> script to run it using it's full path.

> !NOTE:
> Make sure you run the script in a compatible flutter project else you may get ugly
> errors.

#### Trimmed compilation

> Not implemented

Trimmed compilation uses to take less than a minute on similar projects, but the JSON
package seems not to work well with juliac.jl, still looking for a fix...

## To implement

- Add config file.
- Add import `AppLocalizations` when not imported.
- Allow customized `AppLocalizations` call.
- Allow diferent arb translations folder location.
- Implement ai translation of the strings for other arb files.
- Use file content hash to check for modificaitons instead of mtime.
