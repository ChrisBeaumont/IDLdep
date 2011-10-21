;+
; PURPOSE:
;  Search a single line of IDL source code for calls to other procedures,
;  functions, and classes
;
; INPUTS:
;  linein: The line of code to consider. A string
;  
; KEYWORD PARAMETERS:
;  count: On output, holds the number of found dependencies
;  definition: If linein is the definition of a procedure or function,
;              this keyword will hold the name of that
;              procedure/function.
; OUTPUTS:
;  A string array, containing the names of any procedure/function
;  calls found. If none are found, returns the empty string
;
; RESTRICTIONS:
;  0) Most importantly, this assumes that the idl code adheres to the
;     modern convention of reserving parenthesis for function calls
;     and square brackets for array subscripting, Otherwise, array
;     subscripts will be mistaken for function calls. This is
;     enforced by the IDL compiler if you include compile_opt idl2 in
;     your source code (though finddep_line doesn't check for
;     this). If you use parenthesis for array indexing, finddep_line
;     will mistakenly interpret these as function calls.
;  1) Does not consider object method calls (i.e. stack->push)
;  2) Does not search inside strings, and thus cannot find
;     dependencies inside calls to execute, call_function, call_pro,
;     etc. E.g., if linein is " result = execute('myfunction(5)')", 
;     this function will not find the call to myfunction
;
; MODIFICATION HISTORY:
;  January 2011: Written by Chris Beaumont
;  July 2011: Fixed bug when parsing tabs. cnb.
;-
function finddep_line, linein, count = count, definition = definition
  if n_params() ne 1 then begin
     print, 'Calling sequence'
     print, 'result = finddep_line(linein, [count=count, definition=definition]'
     return, !values.f_nan
  endif

  count = 0
  definition = ''
  DEBUG = 0

  ;- tokenize string.
  tab = string(9B)
  delim = ' .:~#$%^&*()-=+[{]}\|/?><,' + tab
  s = strsplit(linein+' 0', delim)
  tokens = strsplit(linein+' 0', delim, /extract)
  tokens = strlowcase(tokens)

  ns = n_elements(s)
  d_old = ''
  inCurly = 0

  quote = "'"
  if DEBUG then print, "Processing line:     ", linein
  for i = 0, ns - 2, 1 do begin
     token = tokens[i]
     if DEBUG then print, i, quote, token, quote, $
                          format='("Token ", i0, ": ", a1, a, a1)'
     dlen = s[i+1] - s[i] - strlen(token)
     delim = strmid(linein, s[i] + strlen(token), dlen)
     delim = strjoin(strsplit(delim, ' ', /extract))
     d0 = strmid(delim, 0, 1)

     ;- ignore procedure/function definition statements
     if i eq 0 && (token eq 'pro' or token eq 'function') then begin
        if ns gt 2 then definition = tokens[i+1]
        if DEBUG then print, 'function/pro definition found'
        return, ''
     endif

     ;- ignores quoted strings
     if inquotes(linein, s[i]) then begin
        if DEBUG then print, 'Skipping quoted token'
        continue
     endif

     ;- ignore object method calls
     if d_old eq '->' then begin
        if DEBUG then print, 'Skipping object method'
        goto, endloop
     endif

     ;- procedure call: first token, followed by comma
     ;- OR: first token after 'then'
     if (i eq 0 && d0 eq ',') || $
        (i gt 0 && tokens[i-1] eq 'then' && d0 eq ',') $
     then begin
        if DEBUG then print, 'adding procedure call'
        result = append(result, token)
     endif
     
     ;- function call: some alphanumeric string followed by (
     if stregex(token, '^[a-zA-Z]') ne -1 && d0 eq '(' then begin
        if DEBUG then print, 'Adding function call'
        result = append(result, token)
     endif

     ;- call to obj_new
     if token eq 'obj_new' then begin
        if DEBUG then print, 'Adding obj_new call'
        assert, i lt (ns -1)
        obj = strmid(tokens[i+1], 1, strlen(tokens[i+1])-2)+'__define'
        result = append(result, obj)
     endif


     ;- object definition declares a superclass
     if token eq 'inherits' && i lt (ns -1) && inCurly then begin
        result = append(result, tokens[i+1]+'__define')
     endif
     
     endloop:
     if strmatch(delim, '*{*') then inCurly++
     if strmatch(delim, '*}*') then inCurly--
     d_old = delim
  endfor

  count = n_elements(result)
  if count eq 0 then return, ''
  return, strlowcase(result)
end

pro test

  assert, array_equal( finddep_line(' print, 3, 4, 5'), 'print')
  assert, array_equal( finddep_line(' if 3 gt 5 then print, 5'), 'print')
  assert, array_equal( finddep_line(' print , 3, 4, 5'), 'print')
  assert, array_equal( finddep_line(' x = fltarr(3, 4, 5)'), 'fltarr')
  assert, array_equal( finddep_line(' x=fltarr(3,4,findgen(5))', count = ct), ['fltarr', 'findgen'])
  assert, ct eq 2
  assert, array_equal( finddep_line(' x = "protected fltarr(5)"'), '')
  assert, array_equal( finddep_line(' x->go()'), '')
  assert, array_equal( finddep_line(' array = [1, 2, fltarr(3)]'),'fltarr')
  assert, array_equal( finddep_line(' x = 3 > findgen(4) < 5'),'findgen')
  assert, array_equal( finddep_line(' x##fltarr(3)'), 'fltarr')
  assert, array_equal( finddep_line(' x * (1 + 2)'), '')
  assert, array_equal( finddep_line(' x = obj_new("stack", 3, 5)'), ['obj_new', 'stack__define'])
  assert, array_equal( finddep_line(" x = obj_new('stack', 3, 5)"), ['obj_new', 'stack__define'])
  x = finddep_line('pro pro_definition', count = ct, definition = d)
  assert, x eq '' && ct eq 0 && d eq 'pro_definition'
  x = finddep_line('function function_definition', count = ct, definition = d)
  assert, x eq '' && ct eq 0 && d eq 'function_definition'
  assert, array_equal( finddep_line(" self.hub->addClent, obj_new('cloudiso', self.hub)"), $
                       ['obj_new', 'cloudiso__define'] )
  assert, array_equal( finddep_line("class = {newclass, inherits old_class}"), $
                       'old_class__define' )
  print, 'all tests passed'
end
