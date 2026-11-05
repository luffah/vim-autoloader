# vim autoloader : source files given vim events

Load files only when they are needed (given autocmd events) instead of
loading everything at startup.

```vim
" load Autoload.vim when first .vim is openned
AutoLoad BufEnter *.vim $VIMPLUGINS/Autoload.vim
" open a new file in /tmp/foo with extension .vim
AutoLoadDefaultExt vim /tmp/foo
" use ':' inside filepaths as : followed by a command to run
AutoLoadUseCommandChar :
```

# Example installation
```sh
mkdir -p ~/.vim/pack/ui/start
cp -r autoloader ~/.vim/pack/ui/start/
```

```vim
" init.vim
packloadall  " if using vim pack structure
```
License GPLv3.
