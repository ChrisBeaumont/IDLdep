IDLdep
======

IDLdep is a package that attempts to find all of the IDL source code
files needed to run another piece of IDL software. It does this by
recursively parsing source code files, looking for calls to procedures
and functions.

Installation
============

To install, simply place these files in your IDL path. In addition,
you will need two external libraries:

The Beaumont IDL library
http://www.ifa.hawaii.edu/users/beaumont/code/

The Markwardt IDL library
http://www.physics.wisc.edu/~craigm/idl/idl.html


Use
=====
Lets consider the test file test.pro::

     IDL> print, finddep_all('test.pro')

     { abs }{ alog }{ arrgen /Users/beaumont/idl/pro/local/documented/arrgen.pro}{
     ceil }{ findgen }{ keyword_set }{ lindgen }{ message }{ n_elements }{ n_params }
     { on_error }{ print }{ return }{ round }{ test test.pro}{
     this_function_doesnt_exist }

finddep_all returns an array of structures, one for each
dependency. The first entry in the structure (tag name = func)
contains the name of a function or procedure. The second entry (tag
name = source) lists the file name that contains the source code for
that function, if one was found.

Many entries correspond to built in IDL routines (abs, alog, etc). You can filter these out
by specifying the /no_builtin flag::

   IDL> print, finddep_all('test.pro', /no_builtin)

   { arrgen /Users/beaumont/idl/pro/local/documented/arrgen.pro}{ test test.pro}{
   this_function_doesnt_exist }

There are just 3 dependencies beyond calls to IDL builtins: arrgen,
test, and this_function_doesnt_exist. Note that the last function
doesn't have any source file associated with it. This is likely a
missing dependency. You can look at only the missing dependencies::

	IDL> print, finddep_all('test.pro', /no_source, /no_builtin)
	
	{ this_function_doesnt_exist }

Or instead filter them out::

   IDL> print, finddep_all('test.pro', /only_source)

   { arrgen /Users/beaumont/idl/pro/local/documented/arrgen.pro}{ test test.pro}


The other useful function in this library is bundle_dep. This routine
will copy all of the dependencies for a given file into a new directory. This
can be helpful when distributing your code to others::

    IDL> bundle_dep, 'test.pro', 'test_directory'
    IDL> exit
    bash> ls test_directory
    arrgen.pro test.pro

Limitations
===========
IDLdep is not perfect. In particular, you should be aware of the following limitations.

- IDLdep assumes that all code follows the modern convention that
  parenthesis are used for function calls, and not array
  subscripting. Thus, it will occasionally misinterpret a variable as
  a function name.
- IDLdep does not understand function calls within quotation marks,
  and thus cannot propery parse the inputs to commands like EXECUTE,
  CALL_FUNCTION, etc. For example, IDLdep will not find the call to
  'testing' in the following line of code: result = call_function('testing', 5)
- IDLdep does not parse calls to object methods like stack->push.
