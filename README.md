## opam-manager (early-alpha release)

Opam-manager helps in managing binaries in OPAM installation and it eases switching between multiple compiler version or multiple OPAMROOTs. It should completely avoids the usage of `eval $(opam config env)`.

Opam-manager maintains in the directory `~/.ocp/manager/bin` a wrapper for each binaries found in known OPAMROOTs. This wrapper is a small binary that:
* determines the current OPAMROOT and OPAMSWITCH,
* setups the correct environment variables (such as `CAML_LD_LIBRARY_PATH`, ...), and
* execute the corresponding binary in the selected switch.

When no corresponding binary is found in the current switch Opam-manager may execute a default binary (typically the corresponding binary in a fixed OPAM switch).

## Installation

```
opam pin add opam-lib --dev-repo 
opam pin add opam-manager https://github.com/OCamlPro/opam-manager.git
opam manager
```

*Warning*: this will update your `.opam` to `opam-1.3~dev`! Subsequently, you have to use the current development version of opam. You may install `opam-1.3~dev` with `opam pin add opam-devel https://github.com/ocaml/opam.git`.

Then edit your shell configuration and update your PATH. For instance,
add the following line to your `.bashrc`

```
export PATH=${HOME}/.ocp/manager/bin:${PATH}
```

Further call to `opam install` will automatically create wrappers for the newly installed binaries.

Running `opam manager` again will perform maintenance tasks, such as removing dangling wrapper.

## Manage default binary

When a binary is not available in the current switch, you may define a default binary either a binary from a specific switch or an 'external' binary. There is currently no CLI for managing default binary. You have to manually create (absolute) symbolic link in `~/.ocp/manager/defaults`. For instance:

```
ln -s ${HOME}/.opam/4.02.2/bin/ocp-indent ${HOME}/.ocp/manager/defaults/ocp-indent
```

Then `ocp-indent` will be available in any OPAMSWITCH.

## Manage multiple OPAMROOTs

Opam-manager is able to manage multiple OPAMROOT. Managed OPAMROOT must be named and registred by editing `~/.ocp/manager/config`. For instance:

```
default-root: "home"
known-roots: [
  ["home" "/home/henry/.opam"]
  ["typerex" "/home/henry/OCamlPro/Typerex/.opam"]
  ["flambda" "/home/henry/OCamlPro/Flambda/.opam"]
]
```

## Current switch

The current switch is determined with the following procedure:

* when the binary is named `opam`, and `--root` or `--switch` are found in its arguments, use them as default;
* if OPAMROOT and OPAMSWITCH are defined, use them;
* if only OPAMROOT is defines, use the 'default' switch of it;
* if only OPAMSWITCH is defined, look for it in the default 'root';
* if neither OPAMROOT or OPAMSWITCH are defined:
  * recursively look after an `.opam-switch` file in the current directory or its ancestors;
  * otherwise, use the default 'switch' of the default 'root'.

The `--switch` passed to `opam`, the OPAMSWITCH variable, or an `.opam-switch` file may contains a string `<root>:<switch>`, where:
* `<root>` correspond to a root name in `~/.ocp/manager/config`, and 
* `<switch>` a valid switch in this root.

The `--root` passed to `opam`,or the OPAMROOT variable may contains a PATH or a known root name.

For instance: `OPAMSWITCH=typerex:4.02.2+ocp1 ocaml` will run the OCaml toplevel found in the switch `4.02.2+ocp1` in the root named `typerex`. This is equivalent to `OPAMROOT=typerex OPAMSWITCH=4.02.2+ocp1 ocaml`.

## Work-in-progress

Opam-manager is in early-alpha stage. The `wrapper` is almost features complete but the CLI is far from complete.
