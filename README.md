# Based on AstroNvim

If you haven't installed AstroNvim, do [these](#dodo) first.



My key mappings are:

F1 : show help command

F4:  use cmake-tool build and run current file, CMakeLists.txt or run.sh required

F5:  debug by dap

F6:  dial your project in most of languages, but should include a file named 'main.xxx'(xxx is your language)

F7:  open a split screen terminal
$ <S-n> $: open terminal in new window

F8: build and run current file. Support c/cpp, java, js, Go, pyhton, lua, rust. Here I set b&r cpp by c++23

F9:  add a broken point for debug on hand

Press `space` then you will get some hint for key combinations



# <span id="dodo">AstroNvim Template</span>

**NOTE:** This is for AstroNvim v4+

A template for getting started with [AstroNvim](https://github.com/AstroNvim/AstroNvim)

## 🛠️ Installation

#### Make a backup of your current nvim and shared folder

```shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

#### Create a new user repository from this template

Press the "Use this template" button above to create a new repository to store your user configuration.

You can also just clone this repository directly if you do not want to track your user configuration in GitHub.

#### Clone the repository

```shell
git clone https://github.com/<your_user>/<your_repository> ~/.config/nvim
```

#### Start Neovim

```shell
nvim
```
