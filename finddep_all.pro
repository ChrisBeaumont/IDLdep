;+
; PURPOSE:
;  Recursively searches for all of the dependencies contained a file
;  of IDL code. Useful for determing what files to include in a
;  self-contained bundle of IDL code.
;
; INPUTS:
;  start: The name of a file to find dependencies for.
;  count: On output, will hold the number of found dependencies.
;
; KEYWORD PARAMETERS:
;  only_source: If set, only return dependencies for which
;  corresponding source code is found. This will filter out
;  dependencies to IDL built in functions (like print), but will also
;  ignore potentially problematic missing dependencies. 
;
;  no_source: If set, only return dependencies for which corresponding
;  source code is not found. This will return calls to built-in
;  functions, as well as missing dependencies.
;
;  no_builtin: If set, this will remove entries corresponding
;  to calls to built-in IDL calls/procedures like print. This keyword
;  can be used in addition to only_source and no_source.
;
; OUTPUTS:
;  A structure array corresponding to each time a function/procedure
;  call was detected. The structure has the following tags:
;   func: The name of a function/procedure recognized as a dependency
;   source: The path of the IDL file that was found to contain the
;           code for func, if found. Otherwise, the empty string
;
; RESTRICTIONS:
;  This code inherits all the restrictions in finddep_line. Please see
;  that file for details. Caveat emptor.
;
; MODIFICATION HISTORY:
;  January 2011: Written by Chris Beaumont
;-
function finddep_all, start, count, only_source = only_source, no_source = no_source, $
                      no_builtin = no_builtin
  compile_opt idl2
  on_error, 2

  count = 0
  if n_params() eq 0 || n_params() gt 2 then begin
     print, 'Calling sequence:'
     print, 'result = finddep_all(start, [count, /only_source, /no_source])'
     return, !values.f_nan
  endif
  
  if keyword_set(only_source) && keyword_set(no_source) then $
     message, 'Cannot set /only_source and /no_source'

  ;catch, error
  ;if error ne 0 then begin
  ;   catch, /cancel
  ;   if obj_valid(x) then obj_destroy, x
  ;   if obj_valid(h) then obj_destroy, h
  ;   if obj_valid(r) then obj_destroy, r
  ;   print, !error_state.msg_prefix + !error_state.msg
  ;  print, 'aborting'
  ;   return, 0
  ;endif

  todo = obj_new('stack')            ;- holds list of dependencies to resolve
  result_hash = obj_new('hashtable') ;- hold structure list of dependencies
  done = obj_new('hashtable')           ;- holds list of already-processed deps

  rec={func:'', source:''}

  ;- find dependencies, schedule them for processing
  dep = finddep_file(start, count, definition = d, defct = dct)
  if count ne 0 then todo->push, dep

  ;- for each dependency, create an empty entry in result_hash
  for i = 0, count - 1, 1 do $
     result_hash->add, dep[i], {func:dep[i], source:''}, /replace
  
  ;- for each definition, create a full entry in result_hash
  for i = 0, dct - 1, 1 do begin
     result_hash->add, d[i], {func:d[i], source:start}, /replace
     done->add, d[i]
  endfor

  ;- process the next dependency
  while ~todo->isEmpty() do begin
     func = todo->pop()
     func = func[0]


     ;- skip case 1-- already visited
     if done->iscontained(func) then continue
     done->add, func, 1

     entry = result_hash->get(func)
     
     ;- sanity check -- can't get here if we've already
     ;- resolved the dependency
     assert, entry.source eq '', 'Already processed dependency'
     
     ;- guess at file
     file = (file_which(func+'.pro'))[0]

     ;- skip case 2-- can't find source code
     if ~file_test(file) then continue

     ;- process depdendencies for new file
     dep = finddep_file(file, count, definition = d, defct = dct)
     assert, size(dep, /type) eq 7

     ;- schedule new dependencies
     if count ne 0 then todo->push, dep
     for i = 0, count - 1, 1 do begin
        if result_hash->iscontained(dep[i]) then continue
        result_hash->add, dep[i], {func:dep[i], source:''}, /replace
     endfor

     ;- process new file definitions
     for i = 0, dct - 1, 1 do begin
        result_hash->add, d[i], {func:d[i], source:file}, /replace
        done->add, d[i], 1
     endfor

  endwhile
  
  obj_destroy, [todo, done]

  ;- convert hashtable to structure array
  k = result_hash->keys()
  count = result_hash->count()
  if count eq 0 then begin
     obj_destroy, result_hash
     return, rec
  endif

  result = replicate(rec, count)
  for i = 0, n_elements(k)-1 do result[i] = result_hash->get(k[i])

  obj_destroy, result_hash

  s = sort(result.func)
  result = result[s]
  if keyword_set(only_source) then begin
     good = where(result.source ne '', count)
     if count ne 0 then result = result[good] $
     else result = rec
  endif
  if keyword_set(no_source) then begin
     good = where(result.source eq '', count)
     if count ne 0 then result = result[good] $
     else result = rec
  endif

  if keyword_set(no_builtin) then begin
     builtin = finddep_builtin()
     builtin = builtin[sort(builtin)]
     ind = value_locate(builtin, result.func) > 0
     good = builtin[ind] ne result.func
     hit = where(good, count)
     
     if count ne 0 then result = result[hit] $
     else result = rec
  endif

  return, result
end
     
pro test

  d = finddep_all('finddep_all.pro')
  s = sort(d.func)
  d = d[s]
  for i = 0, n_elements(d) - 1, 1 do begin
     p = strsplit(d[i].source, '/', /extract)
     p = p[n_elements(p)-1]
     print, d[i].func, p, format='(a15, 5x, a25)'
  endfor
end
