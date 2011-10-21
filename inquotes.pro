;+
; PURPOSE:
;  Determines whether a certain character within a string is inside
;  quotation marks. 
;
; INPUTS:
;  line: The string to consider
;  pos: The position to test
;
; OUTPUTS:
;  1 if pos is inside quotation marks. 0 otherwise
;
; EXAMPLE:
;  Consider the line
;   "Inside 'quotes' " outside 'quotes'
;   01234567890123456789012345678901234
;  inquotes(line, 1) = 1
;  inquotes(line, 10) = 1
;  inquotes(line, 20) = 0
;  inquotes(line, 30) = 1
;
; MODIFICATION HISTORY:
;  January 2011: Written by Chris Beaumont
;-
function inquotes, line, pos
  compile_opt idl2
  on_error, 2

  if n_params() ne 2 then begin
     print, 'Calling sequence:'
     print, ' result = inquotes(line, pos)'
     return, !values.f_nan
  endif

  if size(line, /type) ne 7 then $
     message, 'line must be a string'
  
  if strlen(line) le pos then $
     message, 'position is out of range'

  inDouble = 0
  inSingle = 0
  for j = 0, pos-1, 1 do begin
     char = strmid(line, j, 1)
     if char eq '"' && ~inSingle then inDouble = ~inDouble
     if char eq "'" && ~inDouble then inSingle = ~inSingle
  endfor        
  assert, inDouble + inSingle le 1
  return, inDouble || inSingle
end
