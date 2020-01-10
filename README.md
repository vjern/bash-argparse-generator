Ever tired of writing argument parsers for your bash scripts ?

This tool is meant to alleviate some of the burden.

It allows one to generate bash code to parse arguments.

Let's say I have a script that requires a file and a remote URL to upload it to. 

In bash, I could this simply enough:

```bash
#!/bin/bash
filepath="$1"
url="$2"
upload $filepath --to $url
```

But doing it this way can rapidly get out of hand as we increase the number of arguments and thus potential argument permutations.

## What it does

This tool generates code to parse arguments using a simple syntax.

It supports:
* Simple positional arguments (no cardinality option) (`./myscript.sh <file> <url>`);
* Flags (e.g. `--verbose`);
* Keywords arguments (`--file /path/to/file`, but not `--file=/path/to/file` yet);

Let's say we want to write a parser that allows the user to both pass `file` and `url` as positional arguments, or allow them to be passed as keyword arguments to enhance readability. We'll also a `verbose` boolean flag for good measure.

## How to use it

This is how you would do it with this tool in its current version:

```bash
 ./parse_args.sh arg make \
    file \ # A positional argument
    url \ # A positional argument
    -f,--file {} \ # A keyword argument, here to allow both forms of providing the 'file' argument
    -v,--verbose \ # A boolean flag
    -u,--url {}
```
The generated code looks like this:
```bash

posargs=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            file="$2"; shift;
            echo KW.ARG: file = $file;
            ;;
        -v|--verbose)
            verbose=true;
            echo KW.ARG: verbose = $verbose;
            ;;
        -u|--url)
            url="$2"; shift;
            echo KW.ARG: url = $url;
            ;;
        *)
            posargs="$posargs:$1"
    esac;
    shift;
done

# Parse positional arguments
echo posargs=$posargs
if [[ -n "$posargs" ]]; then
    file=$(echo "$posargs" | cut -d: -f2)
    echo POS.ARG: file = $file
    url=$(echo "$posargs" | cut -d: -f3)
    echo POS.ARG: url = $url
fi

```

Let's say we place this code in a file called `parser.sh`, and we try running it with various arguments:
```
$ ./parser.sh /my/file //example.com
posargs=:/my/file:example.com
POS.ARG: file = /my/file
POS.ARG: url = example.com

$ ./parser.sh /my/file //example.com -f aa
KW.ARG: file = aa
posargs=:/my/file:example.com
POS.ARG: file = /my/file
POS.ARG: url = example.com

# We can see that positional arguments take precedence over keywords args, since they are parsed afterwards

$ ./parser.sh --file /my/file --url example.com -v
KW.ARG: file = /my/file
KW.ARG: url = example.com
KW.ARG: verbose = true
posargs=
```

## Specifying arguments

### Positional arguments

A simple name such as `file` will be considered a positional argument.

### Boolean flags

You can create a flag argument by prefixing it with a dash. You should always provide a 2-dash version and a shorthand version (one dash, one character) for good measure. You can add several aliases separated by commas:

```bash
-v,--verbose,--VERBOSE
```

If the flag argument is provided, a variable of the same name (last alias from left to right) will be set to `'true'`. Otherwise, the variable will be unset.

### Keyword arguments

Keyword arguments are described like boolean flags, plus you need to specify that the actual value is found in the next argument with `{}`:

```bah
-u,--url {}
```

When parsing, it will simply take the value of the next argument on its right, whether it exists (hopefully it's not another flag/keyword argument and you made a mistake) or not (then it is empty).

## Naming arguments

For positional arguments, the name you give it will create a variable with the same name.

For keyword arguments, it is recommended that you give it at least a full name with two dashes (--verbose). The word after the dashes of the last alias will be used as the name:

```js
-v,--verbose => verbose
--verbose => verbose
-v,--verbose,--VERBOSE => VERBOSE
```

## Hot use in a script / function

You can directly insert the code in your script by first sourcing the `parse_args.sh` script in your own:

```bash
source parse_args.sh # this is a relative path, so we assume it is found in the cwd from where your script is run.

# To force the script to be sourced from the same location as your script, here's a way to do it:

__FOLDER__=$(dirname $0) # Exract the parent folder of the executing script
if [ __FOLDER__ ]; then
    __FOLDER__="$__FOLDER__/" # Add a slash if it is non empty
fi
echo __FOLDER__=$__FOLDER__
source ${__FOLDER__}parse_args.sh # Source==import from the folder path
```
Then, to parse arguments at the top-level or in a function, source the code execution:
```sh
source <(
    arg make \
      file \
      url \
      -f,--file {} \
      -u,--url {} \
      -v,--verbose
)

echo file=$file
echo url=$url
echo verbose=$verbose
```
It's especially useful when you have several subcommands:
```bash
upload() {
    source <(
        arg make \
          file \
          ip \
          -f,--file {} \
          -i,--ip {} \
          -v,--verbose
    )
    scp $file $(whoami)@$ip:
}

download() {
    source <(
        arg make \
          url \
          file \
          -i,--ip {} \
          -f,--file {} \
          -t,--to {}
    )
    scp $(whoami)@$ip:$file $to
}
```
