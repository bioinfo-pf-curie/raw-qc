***********************************
version-3.0.0

NEW FEATURES
  - DSL2 version of raw-qc
  - support PDX samples with Xengsort (--pdx)
  - Support smartSeq v4 trimming
  
DEPRECATED
  - Atropos is not longer supported
  - Preset '--picoV1' is no longer supported

***********************************
version-2.2.0

NEW FEATURES
  - Update code template

BUG FIXES
  - Fix typo in fastqscreen annotation path

***********************************
version-2.1.0

NEW FEATURES
  - Add FastqScreen module

BUG FIXES
  - Fix bug with --skip_trimming option where MultiQC was stuck

***********************************
version-2.0.0

NEW FEATURES
  - Add '-adapter' option to skip the detect step
  - Add options '--ntrim', '--two_colour', '--qualtrim', '--minlen'. Note that '--ntrim' does not work with fastp 
  - Add preset for 3'seq protocol
  - Add preset for 'pico' protocol. Do not work for atropos
  - Add MultiQC report
  - Add support for Atropos, TrimGalore!, and fastp trimmers



