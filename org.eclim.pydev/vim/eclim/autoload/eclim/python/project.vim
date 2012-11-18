" Author:  Eric Van Dewoestine
"
" License: {{{
"
" Copyright (C) 2012 - 2013  Eric Van Dewoestine
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" }}}

" Script Variables {{{
let s:command_list_interperters = '-command python_list_interpreters'
let s:command_add_interperter = '-command python_add_interpreter -p "<path>"'
let s:command_remove_interperter = '-command python_remove_interpreter -p "<path>"'
let s:command_interperter = '-command python_interpreter -p "<project>"'
let s:command_list_versions = '-command python_list_versions'
" }}}

function! eclim#python#project#ProjectCreatePre(folder) " {{{
  return s:InitPydev(a:folder)
endfunction " }}}

function! eclim#python#project#ProjectNatureAddPre(project) " {{{
  return s:InitPydev(eclim#project#util#GetProjectRoot(a:project))
endfunction " }}}

function! eclim#python#project#InterpreterList() " {{{
  let interpreters = eclim#python#project#GetInterpreters('')
  if !type(interpreters) == g:LIST_TYPE
    return
  endif

  let pad = 0
  for interpreter in interpreters
    let pad = len(interpreter.name) > pad ? len(interpreter.name) : pad
  endfor

  let output = []
  for interpreter in interpreters
    let name = eclim#util#Pad(interpreter.name, pad)
    call add(output, name . ' - ' . interpreter.path)
  endfor

  call eclim#util#Echo(join(output, "\n"))
endfunction " }}}

function! eclim#python#project#InterpreterAdd(args) " {{{
  let args = eclim#util#ParseCmdLine(a:args)
  if len(args) != 1 && len(args) != 3
    call eclim#util#EchoError(
      \ "You must supply either just the path to the interpreter or\n" .
      \ "-n followed by the name to give to the interpreter followed\n" .
      \ "by the interpreter path.")
    return 0
  endif

  let path = args[-1]
  let path = substitute(path, '\ ', ' ', 'g')
  let path = substitute(path, '\', '/', 'g')
  if has('win32unix')
    let path = eclim#cygwin#WindowsPath(path)
  endif

  call eclim#util#Echo("Adding interpreter...")
  let command = s:command_add_interperter
  let command = substitute(command, '<path>', path, '')
  if args[0] == '-n'
    let name = args[1]
    let command .= ' -n "' . name . '"'
  endif

  let result = eclim#Execute(command)
  if type(result) == g:STRING_TYPE
    call eclim#util#Echo(result)
  endif
endfunction " }}}

function! eclim#python#project#InterpreterRemove(path) " {{{
  call eclim#util#Echo("Removing interpreter...")
  let command = substitute(s:command_remove_interperter, '<path>', a:path, '')
  let result = eclim#Execute(command)
  if type(result) == g:STRING_TYPE
    call eclim#util#Echo(result)
  endif
endfunction " }}}

function! eclim#python#project#GetInterpreter() " {{{
  if !eclim#project#util#IsCurrentFileInProject(0)
    if executable('python2')
      return 'python2'
    endif
    if executable('python')
      return 'python'
    endif
  endif

  let project = eclim#project#util#GetCurrentProjectName()
  let command = s:command_interperter
  let command = substitute(command, '<project>', project, '')
  let result = eclim#Execute(command)
  if executable(result)
    return result
  endif
  return ''
endfunction " }}}

function! eclim#python#project#GetInterpreters(folder) " {{{
  let results = eclim#Execute(s:command_list_interperters, {'dir': a:folder})
  if type(results) != g:LIST_TYPE
    if type(results) == g:STRING_TYPE
      call eclim#util#EchoError(results)
    endif
    return
  endif
  return results
endfunction " }}}

function! s:InitPydev(folder) " {{{
  let interpreters = eclim#python#project#GetInterpreters(a:folder)
  if type(interpreters) != g:LIST_TYPE
    return 0
  endif

  if len(interpreters) == 0
    call eclim#util#EchoError(
      \ 'No python interpreters configured. Please use :PythonInterpreterAdd to add one.')
    return 0
  endif

  if len(interpreters) == 1
    let interpreter = interpreters[0].name
  else
    let answer = eclim#util#PromptList(
      \ "Please choose the interpreter to use",
      \ map(copy(interpreters), 'v:val.name'))
    if answer == -1
      return 0
    endif

    let interpreter = interpreters[answer].name
    redraw
  endif
  return '--interpreter ' . interpreter
endfunction " }}}

function! eclim#python#project#CommandCompleteInterpreter(argLead, cmdLine, cursorPos) " {{{
  let cmdLine = strpart(a:cmdLine, 0, a:cursorPos)
  let cmdTail = strpart(a:cmdLine, a:cursorPos)
  let argLead = substitute(a:argLead, cmdTail . '$', '', '')

  let interpreters = eclim#python#project#GetInterpreters('')
  if !type(interpreters) == g:LIST_TYPE
    return []
  endif

  let names = map(interpreters, "v:val.path")
  if cmdLine !~ '[^\\]\s$'
    let argLead = escape(escape(argLead, '~'), '~')
    " remove escape slashes
    let argLead = substitute(argLead, '\', '', 'g')
    call filter(names, 'v:val =~ "^' . argLead . '"')
  endif

  call map(names, 'escape(v:val, " ")')
  return names
endfunction " }}}

" vim:ft=vim:fdm=marker
