" autoloader.vim -- Source files on demand given vim events
" @Author:      luffah (luffah AT runbox com)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2018-03-26
" @Last Change: 2026-11-05
" @Revision:    1
"
" @Overview
" Load files, register default filetype for given directory, given
" :AutoLoad :AutoLoadReset :AutoLoadDefaultExt :AutoLoadUseCommandChar
if exists("g:loaded_autoloader") || &cp || v:version < 700
  finish
endif

let g:loaded_autoloader = 1

" Files already sourced (do not source them twice).
let g:autoloader_loaded_files=[]

" @global g:autoloader_cmd_char
" Char to use in a filepath to add a command to apply once
" after the file openning (see |AutoLoadUseCommandChar|).
" Default ':'.
let s:cmd_char = get(g:, 'autoloader_cmd_char', ':')

"""""""
" Internal helpers
"""""""

" @function s:SourceOnce(path, discharge)
" Source [path], then execute [discharge] (used to remove the autocmd
" that triggered the loading).
fu! s:SourceOnce(path, discharge)
  if index(g:autoloader_loaded_files, a:path) < 0
    call add(g:autoloader_loaded_files, a:path)
    silent echo "$< ".a:path
    exe 'source ' . a:path
    exe a:discharge
  endif
endfu

" @function s:RemoveLastAutocmd(event, pattern)
" Remove the last autocmd registered for [event] [pattern].
" e.g. for a source-once pattern 'au! Autoloader <event> <pattern>'
" (only matching the registration done by |s:RegisterOnEvent|).
fu! s:RemoveLastAutocmd(event, pattern)
  exe 'au! Autoloader '.a:event.' '.a:pattern
endfu

" @function s:vimString(string)
" Return [string] quoted as a vimscript string (with simple quotes).
fu! s:vimString(str)
  return "'".substitute(a:str, "'", "''", 'g')."'"
endfu

" @function s:RegisterOnEvent(event, pattern, required, path)
" Register an autocmd [event] [pattern] sourcing [path] on trigger.
" If [required] is false, the file is registered only if it already
" exists (filereadable).
fu! s:RegisterOnEvent(event, pattern, required, path)
  if !a:required && !filereadable(a:path)
    return
  endif
  let l:path = s:vimString(a:path)
  let l:discharge = 'call s:RemoveLastAutocmd('.s:vimString(a:event).','.s:vimString(a:pattern).')'
  augroup Autoloader
    exe 'au '.a:event.' '.a:pattern.' call s:SourceOnce('.l:path.','.s:vimString(l:discharge).')'
  augroup END
endfu

" @function s:AutoSource(required, event, pattern, file(s))
" For each file, register an autocmd [event] [pattern] sourcing it
" (only if not sourced yet). (|AutoLoad|)
fu! s:AutoSource(required, ...)
  let [l:event, l:pattern] = a:000[0:1]
  for l:f in a:000[2:]
    let l:path = expand(l:f)
    if index(g:autoloader_loaded_files, l:path) < 0
      call s:RegisterOnEvent(l:event, l:pattern, a:required, l:path)
    endif
  endfor
endfu

" @function s:Reset()
" Remove all registered autocmds of the plugin. (|AutoLoadReset|)
fu! s:Reset()
  augroup Autoloader
    autocmd!
  augroup END
endfu

" @function s:OpenFileDroppingCurrent(path)
" Open [path], then delete the buffer previously displayed.
" Used to switch from a placeholder buffer name like 'file:command'
" to the real 'file'.
fu! s:OpenFileDroppingCurrent(path)
  let l:placeholder_buf = bufnr()
  exe 'e '.fnameescape(a:path)
  exe l:placeholder_buf.'bd'
endfu

" @function s:RegisterFiletypeReplacement(ft)
" For the current new buffer, register the commands given
" :AutoLoadUseCommandChar and :AutoLoadDefaultExt (|s:reopft|).
" Called by the autocmd registered by those commands (BufNewFile).
fu! s:reopft(ft)
  let l:name = expand('%')

  " Command char in the name : reopen the file without the suffix,
  " keep the command to apply once on buffer enter.
  let l:cmd = ''
  if stridx(l:name, s:cmd_char) != -1
    let l:path  = trim(substitute(l:name, s:cmd_char.'.*$', '', ''))
    let l:cmd   = trim(substitute(l:name, '^.*'.s:cmd_char, '', ''))
    call s:OpenFileDroppingCurrent(l:path)
  endif

  " No extension yet : reopen with the default extension. (AutoLoadDefaultExt)
  if strlen(a:ft) && expand('%:e') == ''
    call s:OpenFileDroppingCurrent(expand('%:r').'.'.a:ft)
  endif

  " Run the command given after the command char, once.
  if strlen(l:cmd)
    exe 'au BufEnter <buffer> ++once '.l:cmd
  endif
endfu

" @function s:RegisterDefaultExtForDirectory(ft, directories)
" Register that any new file under one of [directories] opens with
" the extension [ft] (if not given). (|AutoLoadDefaultExt|)
fu! s:RegisterDefaultExtForDirectory(ft, ...)
  augroup Autoloader
    for l:dir in a:000
      exe 'au BufNewFile '.substitute(l:dir, '/$', '', '').'/* ++nested call s:reopft("'.a:ft.'")'
    endfor
  augroup END
endfu

" @function s:RegisterCmdCharInFilename(chr)
" Allow using [chr] in a filepath to append a command applied once after
" the file openning. (|AutoLoadUseCommandChar|)
fu! s:RegisterCmdCharInFilename(chr)
  let s:cmd_char = a:chr
  augroup Autoloader
    exe 'au BufNewFile *'.a:chr.'* ++nested call s:reopft("")'
  augroup END
endfu

"""""""
" Commands
"""""""

" @command :AutoLoad [event] [pattern] [file(s)]
" Source given file(s) when the autocmd [event] matches [pattern].
" The files are loaded once (g:autoloader_loaded_files).
command! -nargs=* AutoLoad call s:AutoSource(0, <f-args>)

" @command :AutoLoadReset [event] [pattern] [file(s)]
" Remove every autocmd of the plugin (then |:AutoLoad| may re-register).
command! -nargs=* AutoLoadReset call s:Reset()

" @command :AutoLoadDefaultExt <ft> <pattern(s)>
" Setup a default extension to be used if the file have no extension
" given directory path pattern.
command! -nargs=* -complete=dir AutoLoadDefaultExt call s:RegisterDefaultExtForDirectory(<f-args>)

" @command :AutoLoadUseCommandChar <char>
" While openning a file, allow to use shortcut <filename>:<command>
command! -nargs=* -complete=dir AutoLoadUseCommandChar call s:RegisterCmdCharInFilename(<f-args>)
