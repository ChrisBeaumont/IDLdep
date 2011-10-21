function finddep_builtin
  file = file_which('builtin_71.dat')
  if strlen(file) eq 0 then $
     message, 'Cannot find list of built in functions: builtin_71.dat'
  file = file[0]
  lines = file_lines(file)
  result = strarr(lines)

  openr, lun, file, /get
  readf, lun, result, format='(a)'
  free_lun, lun

  return, strlowcase(result)
end
