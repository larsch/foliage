= foliage

* FIX (url)

== DESCRIPTION:

Foliage is a code coverage analysis tool for decision/condition
coverage. Foliage will examine all code branching point in your code
and report untested branch conditions. Coverage analysis such as
'rcov' analyses only code-line coverage and may easily miss untested
code. Here's an example:

   some_method(some_argument + 8) if some_condition

When this line of code is reached, some_condition is evaluted, but
depending on the outcome, some_method may never be called. RCov can
not detect this, but Foliage can. Here is another example:

   variable = condition ? one_method(2) : other_method(5)

Foliage will detect whether both cases (non-nil/false and nil/false)
has been tested.

== FEATURES/PROBLEMS:

* Limitation: Foliage can only detect coverage for a single ruby
  interpreter instance. This means you need to run all of your tests
  in the same Ruby instance to generate meaningful coverage analysis
  results (Aggregate results are not currently possible).

== SYNOPSIS:

  FIX (code sample of usage)

== REQUIREMENTS:

* FIX (list of requirements)

== INSTALL:

* FIX (sudo gem install, anything else)

== LICENSE:

(The MIT License)

Copyright (c) 2009 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
