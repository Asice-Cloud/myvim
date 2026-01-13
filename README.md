# Based on AstroNvim

If you haven't installed AstroNvim, do [these](#dodo) first.


My key mappings are:

F1 : show help command

F3 : macro record

F4:  use cmake-tool build and run current file, CMakeLists.txt or run.sh required

F5:  debug by dap\lldb

F6: compile c/cpp , rust  with debug info

F7:  open a split screen terminal

F8: build and run current file. Support c/cpp, java, js, Go, pyhton, lua, rust. Here I set build&run cpp by c++23

F9:  add a broken point for debug on hand
`<S-F9>`: conditon break point

`<C-z> <C-x>` shift opened file (buffer)

gd: Goto defination
ga: get code actions
gh: lsp_finder

normal, click `<S-l>` (L) , then will show preview of definition or macro expansion

`<C-o>`: return to (gd)before place

`<C-up/down/left/right>`: adjust size of one window

`<C-N>`: select a word, come into multi-cursor mode

`\ or |`: devide termial split or vertical

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
