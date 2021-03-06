# BIDS for MATLAB / Octave

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-8-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->
[![Build Status](https://travis-ci.com/bids-standard/bids-matlab.svg?branch=master)](https://travis-ci.com/bids-standard/bids-matlab)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/bids-standard/bids-matlab/master?filepath=examples/tutorial.ipynb)

This repository aims at centralising MATLAB/Octave tools to interact with datasets conforming to the BIDS (Brain Imaging Data Structure) format.

For more information about BIDS, visit https://bids.neuroimaging.io/.

Join our chat on the [BIDS-MATLAB channel](https://mattermost.brainhack.org/brainhack/channels/bids-matlab) on the brainhack mattermost.

See also [PyBIDS](https://github.com/bids-standard/pybids) for Python and the [BIDS Starter Kit](https://github.com/bids-standard/bids-starter-kit).


## Features

### What this toolbox can do

- read the layout of a BIDS dataset (see `bids.layout`),
- perform queries on that layout to get information about the subjects, sessions, runs, modalities, metadata... contained within that dataset (see `bids.query`),
- generate a human readable report of the content of BIDS data set containing anatomical MRI, functional MRI, diffusion weighted imaging, field map data (see `bids.report`)
- read and write JSON files (see `bids.util.jsondecode` and `bids.util.jsonencode`) provided that the right [dependencies](#reading-and-writing-json-files) are installed,
- read and write TSV files (see `bids.util.tsvread` and `bids.util.tsvwrite`),

The behavior of this toolbox assumes that it is interacting with a valid BIDS dataset that should have been validated using [BIDS-validator](https://bids-standard.github.io/bids-validator/). If the Node.js version of the validator is [installed on your computer](https://github.com/bids-standard/bids-validator#quickstart), you can call it from the matlab prompt using `bids.validate`. Just be aware that any unvalidated components may produce undefined behavior. Although, if you're BIDS-y enough, the behavior may be predictable.


### What this toolbox cannot do... yet

- parse the layout of "BIDS-derivative compatible" datasets (like those generated by fMRIprep),
- create BIDS compatible filenames or folder structures for raw or derivatives datasets,
- do basic copying of files to help with derivative dataset generation,
- generate human readable reports of the content of BIDS data with EEG, MEG, iEEG, physio and events data,
- deal with some of the most recent updates or incoming BIDS extensions (basic derivatives, ASL, PET, BIDS model...)
- ...

We are trying to centralize the requests for new features in this [issue](https://github.com/bids-standard/bids-matlab/issues/60): have a browse to see what could be coming soon or if we have missed something obvious.


## Installation

Download this repository and add it to your MATLAB/Octave path.

```Matlab
unzip('https://github.com/bids-standard/bids-matlab/archive/master.zip');
addpath('bids-matlab-master');
```
If your version of MATLAB/Octave does not support JSON natively, please also install [SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/) or [JSONio](https://github.com/gllmflndn/JSONio).

## Usage

```Matlab
BIDS = bids.layout('/home/data/ds000117');
bids.query(BIDS, 'subjects')
```

A [tutorial](https://github.com/bids-standard/bids-matlab/blob/master/examples/tutorial.ipynb) is available as a Jupyter Notebook and can be run interactively via [Binder](https://mybinder.org/v2/gh/bids-standard/bids-matlab/master?filepath=examples/tutorial.ipynb).

## Requirements

BIDS-MATLAB works with: 

- Octave 5.2.0 or newer
- MATLAB R2014a or newer  

We aim for compatibility with the latest stable release of Octave at any time. Compatibility can sometimes also be achieved with older versions of Octave but this is not guaranteed.


### Reading and writing JSON files

If you are using MATLAB R2016b or newer, nothing else needs to be installed.

If you are using MATLAB R2016a or older, or using Octave, you need to install a supported JSON library for your MATLAB or Octave. This can be any of:

  * [JSONio](https://github.com/gllmflndn/JSONio) for MATLAB or Octave
  * [SPM12](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/)

## Implementation

Starting point was `spm_BIDS.m` from [SPM12](https://github.com/spm/spm12) ([documentation](https://en.wikibooks.org/wiki/SPM/BIDS#BIDS_parser_and_queries)) reformatted in a `+bids` package with dependencies to other SPM functions removed.

## Other tools (MATLAB only)
- [dicm2nii](https://github.com/xiangruili/dicm2nii): A DICOM to BIDS converter
- [imtool3D_BIDS](https://github.com/tanguyduval/imtool3D_td): A 3D viewer for BIDS directory
- [Brainstorm](https://github.com/brainstorm-tools/brainstorm3): Comprehensive brain analysis toolbox (includes BIDS [import and export](https://neuroimage.usc.edu/brainstorm/ExportBids) and different examples dealing with BIDS datasets (e.g. [group analysis from a MEG visual dataset](https://neuroimage.usc.edu/brainstorm/Tutorials/VisualGroup), [resting state analysis from OMEGA datasets](https://neuroimage.usc.edu/brainstorm/Tutorials/RestingOmega#BIDS_specifications) )

## Contributors ???

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/gllmflndn"><img src="https://avatars0.githubusercontent.com/u/5950855?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Guillaume</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=gllmflndn" title="Code">????</a> <a href="#design-gllmflndn" title="Design">????</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=gllmflndn" title="Documentation">????</a> <a href="#example-gllmflndn" title="Examples">????</a> <a href="#ideas-gllmflndn" title="Ideas, Planning, & Feedback">????</a> <a href="#infra-gllmflndn" title="Infrastructure (Hosting, Build-Tools, etc)">????</a> <a href="#maintenance-gllmflndn" title="Maintenance">????</a> <a href="#question-gllmflndn" title="Answering Questions">????</a> <a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Agllmflndn" title="Reviewed Pull Requests">????</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=gllmflndn" title="Tests">??????</a></td>
    <td align="center"><a href="https://remi-gau.github.io/"><img src="https://avatars3.githubusercontent.com/u/6961185?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Remi Gau</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=Remi-Gau" title="Code">????</a> <a href="#design-Remi-Gau" title="Design">????</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=Remi-Gau" title="Documentation">????</a> <a href="#example-Remi-Gau" title="Examples">????</a> <a href="#ideas-Remi-Gau" title="Ideas, Planning, & Feedback">????</a> <a href="#maintenance-Remi-Gau" title="Maintenance">????</a> <a href="#question-Remi-Gau" title="Answering Questions">????</a> <a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3ARemi-Gau" title="Reviewed Pull Requests">????</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=Remi-Gau" title="Tests">??????</a></td>
    <td align="center"><a href="http://apjanke.net"><img src="https://avatars2.githubusercontent.com/u/2618447?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Andrew Janke</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=apjanke" title="Code">????</a> <a href="#design-apjanke" title="Design">????</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=apjanke" title="Documentation">????</a> <a href="#ideas-apjanke" title="Ideas, Planning, & Feedback">????</a> <a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Aapjanke" title="Reviewed Pull Requests">????</a> <a href="#infra-apjanke" title="Infrastructure (Hosting, Build-Tools, etc)">????</a></td>
    <td align="center"><a href="https://github.com/tanguyduval"><img src="https://avatars1.githubusercontent.com/u/7785316?v=4?s=100" width="100px;" alt=""/><br /><sub><b>tanguyduval</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=tanguyduval" title="Code">????</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=tanguyduval" title="Documentation">????</a> <a href="#ideas-tanguyduval" title="Ideas, Planning, & Feedback">????</a></td>
    <td align="center"><a href="https://github.com/robertoostenveld"><img src="https://avatars1.githubusercontent.com/u/899043?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Robert Oostenveld</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/commits?author=robertoostenveld" title="Code">????</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=robertoostenveld" title="Documentation">????</a> <a href="#ideas-robertoostenveld" title="Ideas, Planning, & Feedback">????</a> <a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Arobertoostenveld" title="Reviewed Pull Requests">????</a></td>
    <td align="center"><a href="http://www.cmadan.com"><img src="https://avatars0.githubusercontent.com/u/6385051?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Christopher Madan</b></sub></a><br /><a href="#content-cMadan" title="Content">????</a></td>
    <td align="center"><a href="http://guiomarniso.com"><img src="https://avatars1.githubusercontent.com/u/4451818?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Julia Guiomar Niso Gal??n</b></sub></a><br /><a href="https://github.com/bids-standard/bids-matlab/pulls?q=is%3Apr+reviewed-by%3Aguiomar" title="Reviewed Pull Requests">????</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/mslw"><img src="https://avatars1.githubusercontent.com/u/11985212?v=4?s=100" width="100px;" alt=""/><br /><sub><b>Micha?? Szczepanik</b></sub></a><br /><a href="#infra-mslw" title="Infrastructure (Hosting, Build-Tools, etc)">????</a> <a href="#ideas-mslw" title="Ideas, Planning, & Feedback">????</a> <a href="https://github.com/bids-standard/bids-matlab/commits?author=mslw" title="Code">????</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
