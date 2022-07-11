# News

## v0.3.0

* Updates to "modern" Julia, compat with Julia 1.6
* Use BinaryBuilder artifacts for both casacore and the wrapper

## v0.2.2

*2018-03-05*

* Adds an undocumented (for now) `MeasurementSets` module for creating CasaCore measurement sets
* Fix some errors in the way column shapes are computed

## v0.2.1

*2017-12-15*

* Arithmetic on `Direction` produces an `UnnormalizedDirection`, which can be converted back to a
  regular normalized `Direction`. This allows intermediate operations to be unnormalized before
  explicitly normalizing at the last step.
* Experimental (unexported) support for rotation matrices.
* Julia will no longer crash when trying to operate on a closed table. This used to occur because
  the C++ code throws an exception. Now Julia will throw an exception instead.

## v0.2.0

*2017-11-21*

* Package reorganization for compatibilitiy with Julia v0.6.
* Documentation improvements.
* Array keywords are now allowed.
* Subtable keywords are functional again.
* Some arithmetic operations on measures are now defined.

