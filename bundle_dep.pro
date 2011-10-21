;+
; PURPOSE:
;  Attempt to use finddep_all to bundle all dependencies needed to run
;  a given IDL program. 
;
; INPUTS:
;  file: The name of an IDL source file to bundle
;  output_dir: The name of a directory in which to copy 'file' and its
;              dependencies. It will be created if it doesn't exist
;
; RESTRICTIONS:
;  The program uses finddep_all to find dependencies, and it
;  isn't perfect. See its documentation for details.
;
; MODIFICATION HISTORY:
;  July 2011: Written by Chris Beaumont
;-
pro bundle_dep, file, output_dir
  if n_params() ne 2 then begin
     print, 'calling sequence'
     print, 'bundle_dep, file, output_dir'
     return
  endif

  if size(file, /type) ne 7 || size(output_dir, /type) ne 7 $
  then message, 'file and output_dir must be strings'

  if ~file_test(file) then $
     message, 'File does not exist: '+file

  dep = finddep_all(file, /only_source)

  ;- compile all of the unique source files
  src = dep.source
  src = src[uniq(src, sort(src))]
  
  if ~file_test(output_dir) then file_mkdir, output_dir
  file_copy, src, output_dir, /over
end
