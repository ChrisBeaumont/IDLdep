;+
; PURPOSE:
;  Search an IDL code file for calls to other functions and
;  procedures.
;
; INPUTS:
;  file: The name of a file to search
;  count: On output, will hold the number of found dependencies. 
;
; KEYWORD PARAMETERS:
;  definition: A string array that will hold the names of any
;  functions/procedures that are defined within this file
;
;  defct: On output, will hold the number of function/procedure
;  definitions in the file
;
;  verbose: If set, print extra output
;
; OUTPUTS:
;  A string array, holding the names of all dependencies found
;
; RESTRICTIONS:
;  This method inherits all of the restrictions to finddep_line.
;
; MODIFICATION HISTORY:
;  January 2011: Written by Chris Beaumont
;-
function finddep_file, file, count, definition = definition, defct = defct, verbose = verbose
  compile_opt idl2

  if n_params() eq 0 || n_params() gt 2 then begin
     print, 'calling sequence'
     print, 'result = finddep_file(file, [count, definition=definition, defct=defct'
     print, '                             /verbose])'
     return, !values.f_nan
  endif

  if ~file_test(file) then $
     message, 'File not found: ' + file
  
  data = finddep_preprocess(file)
  s = obj_new('stack')
  ds = obj_new('stack')
  count = 0

  for i = 0, n_elements(data) - 1, 1 do begin
     if keyword_set(verbose) then print, data[i]
     d = finddep_line(data[i], count = ct, def = def)
     if keyword_set(verbose) then print, '-----', d
     if ct ne 0 then s->push, d
     if def ne '' then ds->push, def
  endfor

  result = s->toArray()
  definition = ds->toArray()
  sct = s->getSize()
  defct =ds->getSize()

  obj_destroy, [s, ds]

  if sct eq 0 then return, ''
  if defct eq 0 then definition = ''
  
  count = sct
  return, result

end
