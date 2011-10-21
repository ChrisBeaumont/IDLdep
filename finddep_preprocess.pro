;+
; PURPOSE:
;  Preprocess a file of IDL source code for further analysis in the
;  finddep suite. Used by finddep_file.
;
; INPUTS:
;  file: The name of a file to preprocess
;
; OUTPUTS:
;  A string array, were each element contains one logical line of IDL
;  code in the input file. A logical line is one stripped of comments,
;  and where lines split by the line continuation operator $ are
;  joined (and the $ removed)
;
; MODIFICATION HISTORY:
;  January 2011: Written by Chris Beaumont
;-
function finddep_preprocess, file
  if n_params() ne 1 then begin
     print, 'calling sequence'
     print, 'result = finddep_preprocess(file)'
     return, !values.f_nan
  endif

  if ~file_test(file) then $
     message, 'File not found: '+ file
  
  nline = file_lines(file)
  data = strarr(nline)

  openr, lun, file, /get
  readf, lun, data, format='(a)'
  free_lun, lun

  ;- remove comments
  for i = 0, nline - 1, 1 do begin
     line = data[i]
     hit = strpos(line, ';')
     while hit ne -1 do begin
        if ~inquotes(line, hit) then begin
           line = strmid(line, 0, hit)
           data[i] = line
           break
        endif
        hit = strpos(line, ';', hit+1)
     endwhile
  endfor

  ;- merge lines separated by $
  doContinue = intarr(nline) - 1
  for i = 0, nline - 1, 1 do begin
     line = data[i]
     hit = strpos(line, '$')
     while hit ne -1 do begin
        if ~inquotes(line, hit) then begin
           doContinue[i] = hit
           break
        endif
        hit = strpos(line, '$', hit+1)
     endwhile
  endfor

  s = obj_new('stack')
  pos = 0
  while pos lt nline do begin
     l = ''
     while  doContinue[pos] ne - 1 do begin
        l += ' ' + strmid(data[pos], 0, doContinue[pos])
        pos++
     endwhile
     l += ' ' + data[pos++]
     s->push, l
  endwhile
  
  data = s->toArray()
  obj_destroy, s
     
  return, data
end
