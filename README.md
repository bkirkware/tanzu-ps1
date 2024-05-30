tanzu-ps1: Tanzu CLI prompt for bash and zsh
============================================

A script that lets you add the current Tanzu project and space
configured on `tanzu` CLI to your Bash/Zsh prompt strings (i.e. the `$PS1`).

Inspired by `kube-ps1`.

## Installing

### From Source

1. Clone this repository
2. Source the tanzu-ps1.sh in your `~/.zshrc` or your `~/.bashrc`

### Zsh Plugin Managers

#### Using [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh)

Copy this script to the plugins folder:

```bash
mkdir ~/.oh-my-zsh/plugins/tanzu-ps1
cp tanzu-ps1.sh ~/.oh-my-zsh/plugins/tanzu-ps1/tanzu-ps1.plugin.zsh
```

Update `.zshrc` and add tanzu-ps1 to your list of plugins:

```
plugins=(kube-ps1 tanzu-ps1)
```

Add to the PROMPT variable at the bottom. Here is an example of using both kube-ps1 and tanzu-ps1 together:

```sh
PROMPT='$(kube_ps1) $(tanzu_ps1) %F{cyan}%1~%f %# '
```

## Requirements

The default prompt assumes you have the `tanzu` command line utility installed.
Official installation instructions and binaries are available:

[Install and Set up Tanzu CLI](https://docs.vmware.com/en/VMware-Tanzu-CLI/index.html)

## Prompt Structure

The default prompt layout is:

```
(<symbol>|<project>:<space>)
```

If the current-context is not set, tanzu-ps1 will return the following:

```
(<symbol>|N/A:N/A)
```

## Enabling/Disabling

If you want to stop showing Tanzu status on your prompt string temporarily
run `tanzuoff`. To disable the prompt for all shell sessions, run `tanzuoff -g`.
You can enable it again in the current shell by running `tanzuon`, and globally
with `tanzuon -g`.

```
tanzuon     : turn on tanzu-ps1 status for this shell.  Takes precedence over
              global setting for current session
tanzuon -g  : turn on tanzu-ps1 status globally
tanzuoff    : turn off tanzu-ps1 status for this shell. Takes precedence over
              global setting for current session
tanzuoff -g : turn off tanzu-ps1 status globally
```

## Customization

The default settings can be overridden in `~/.bashrc` or `~/.zshrc` by setting
the following environment variables:

| Variable | Default | Meaning |
| :------- | :-----: | ------- |
| `TANZU_PS1_BINARY` | `tanzu` | Default Tanzu CLI binary |
| `TANZU_PS1_SPACE_ENABLE` | `true` | Display the namespace. If set to `false`, this will also disable `TANZU_PS1_DIVIDER` |
| `TANZU_PS1_PREFIX` | `(` | Prompt opening character  |
| `TANZU_PS1_SYMBOL_ENABLE` | `true ` | Display the prompt Symbol. If set to `false`, this will also disable `TANZU_PS1_SEPARATOR` |
| `TANZU_PS1_SYMBOL_PADDING` | `false` | Adds a space (padding) after the symbol to prevent clobbering prompt characters |
| `TANZU_PS1_SYMBOL_DEFAULT` | `TZ ` | Default prompt symbol. |
| `TANZU_PS1_SYMBOL_USE_IMG` | `false` |  |
| `TANZU_PS1_SEPARATOR` | &#124; | Separator between symbol and context name |
| `TANZU_PS1_DIVIDER` | `:` | Separator between context and namespace |
| `TANZU_PS1_SUFFIX` | `)` | Prompt closing character |
| `TANZU_PS1_PROJECT_FUNCTION` | No default, must be user supplied | Function to customize how project is displayed |
| `TANZU_PS1_SPACE_FUNCTION` | No default, must be user supplied | Function to customize how space is displayed |
| `TANZU_PS1_TANZUCONFIG_SYMLINK` | `false` | Treat `TANZUCONFIG` and `~/.config/tanzu/config-ng.yaml` files as symbolic links |

To disable a feature, set it to an empty string:

```
TANZU_PS1_SEPARATOR=''
```

## Colors

The default colors are set with the following environment variables:

| Variable | Default | Meaning |
| :------- | :-----: | ------- |
| `TANZU_PS1_PREFIX_COLOR` | `null` | Set default color of the prompt prefix |
| `TANZU_PS1_SYMBOL_COLOR` | `green` | Set default color of the Tanzu symbol |
| `TANZU_PS1_CTX_COLOR` | `red` | Set default color of the context |
| `TANZU_PS1_SUFFIX_COLOR` | `null` | Set default color of the prompt suffix |
| `TANZU_PS1_NS_COLOR` | `cyan` | Set default color of the namespace |
| `TANZU_PS1_BG_COLOR` | `null` | Set default color of the prompt background |

Set the variable to an empty string if you do not want color for each
prompt section:

```
TANZU_PS1_PROJECT_COLOR=''
```

Names are usable for the following colors:

```
black, red, green, yellow, blue, magenta, cyan
```

256 colors are available by specifying the numerical value as the variable
argument.

## Customize display of cluster name and namespace

You can change how the project name and space name are displayed using the
`TANZU_PS1_PROJECT_FUNCTION` and `TANZU_PS1_SPACE_FUNCTION` variables
respectively.

For the following examples let's assume the following:

project: `test-project`
space: `test-space`

Let's say you would prefer the space to be displayed in all uppercase
(`TEST-SPACE`), here's one way you could do that:

```sh
function get_space_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

export TANZU_PS1_SPACE_FUNCTION=get_space_upper
```

In both cases, the variable is set to the name of the function, and you must have defined the function in your shell configuration before TANZU_PS1 is called. The function must accept a single parameter and echo out the final value.

## Contributors

Brian Kirkland adapted the original `kube-ps1` plugin to fit the `tanzu` CLI.

Credit to original contributors:
* Jon Mosco
* [Ahmet Alp Balkan](https://github.com/ahmetb)
* Jared Yanovich