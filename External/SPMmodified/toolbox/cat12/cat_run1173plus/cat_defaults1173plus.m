function cat_defaults1173plus
% Sets the defaults for CAT
% FORMAT cat_defaults
%_______________________________________________________________________
%
% This file is intended to be customised for the site.
%
% Care must be taken when modifying this file
%_______________________________________________________________________
% $Id: cat_defaults1173plus.m 1584 2020-03-16 10:19:58Z dahnke $

clear global cat1173plus 
global cat1173plus


% Options for inital SPM12 segmentation that is used as starting point for CAT12. 
%=======================================================================
cat1173plus.opts.tpm       = {fullfile(spm('dir'),'tpm','TPM.nii')};
cat1173plus.opts.ngaus     = [1 1 2 3 4 2];           % Gaussians per class (SPM12 default = [1 1 2 3 4 2]) - alternative: [3 3 2 3 4 2] 
cat1173plus.opts.affreg    = 'mni';                   % Affine regularisation (SPM12 default = mni) - '';'mni';'eastern';'subj';'none';'rigid'
cat1173plus.opts.warpreg   = [0 0.001 0.5 0.05 0.2];  % Warping regularisation (SPM12 default) - no useful modification found
cat1173plus.opts.biasstr   = 0.5;                     % Strength of the bias correction that controls the biasreg and biasfwhm parameter (CAT only!)
                                              %   0 - use SPM parameter; eps - ultralight, 0.25 - light, 0.5 - medium, 0.75 - strong, and 1 - heavy corrections
                                              %   job.opts.biasreg	= min(  10 , max(  0 , 10^-(job.opts.biasstr*2 + 2) ));
                                              %   job.opts.biasfwhm	= min( inf , max( 30 , 30 + 60*job.opts.biasstr ));  
cat1173plus.opts.biasreg   = 0.001;                   % Bias regularisation (cat.opts.biasstr has to be 0!) - 10,1,0.1,...,0.00001
                                              %   smaller values for stronger bias fields
cat1173plus.opts.biasfwhm  = 60;                      % Bias FWHM (cat.opts.biasstr has to be 0!) - 30:10:120,inf 
                                              %   lower values for strong bias fields, but check for overfitting of the thalamus (values <45 mm)
cat1173plus.opts.samp      = 3;                       % Sampling distance - alternative: 1.5 
                                              %   Initial SPM segmentation resolution, whereas the AMAP runs on the full or speciefied resolution
                                              %   described by cat.extopts.restype and cat.extopts.resval. Higher resolution did not improve the
                                              %   results in most results (but increase caluculation time were.  

                                              
% Writing options
%=======================================================================

% options:
%   native    0/1     (none/yes)
%   warped    0/1     (none/yes)
%   mod       0/1/2/3 (none/affine+nonlinear/nonlinear only/both)
%   dartel    0/1/2/3 (none/rigid/affine/both)

% save surface and thickness
cat1173plus.output.surface     = 0;     % surface and thickness creation:   0 - no (default), 1 - lh+rh, 2 - lh+rh+cerebellum, 
                                %   3 - lh, 4 - rh, 5 - lh+rh (fast, no registration, only for quick quality check and not for analysis),
                                %   6 - lh+rh+cerebellum (fast, no registration, only for quick quality check and not for analysis)

% save ROI values
cat1173plus.output.ROI         = 1;     % write xml-file with ROI data (0 - no, 1 - yes (default))

% bias and noise corrected, global intensity normalized
cat1173plus.output.bias.native = 0;
cat1173plus.output.bias.warped = 1;
cat1173plus.output.bias.dartel = 0;

% bias and noise corrected, (locally - if LAS>0) intensity normalized
cat1173plus.output.las.native = 0;
cat1173plus.output.las.warped = 0;
cat1173plus.output.las.dartel = 0;

% GM tissue maps
cat1173plus.output.GM.native  = 0;
cat1173plus.output.GM.warped  = 0;
cat1173plus.output.GM.mod     = 1;
cat1173plus.output.GM.dartel  = 0;

% WM tissue maps
cat1173plus.output.WM.native  = 0;
cat1173plus.output.WM.warped  = 0;
cat1173plus.output.WM.mod     = 1;
cat1173plus.output.WM.dartel  = 0;
 
% CSF tissue maps
cat1173plus.output.CSF.native = 0;
cat1173plus.output.CSF.warped = 0;
cat1173plus.output.CSF.mod    = 0;
cat1173plus.output.CSF.dartel = 0;

% WMH tissue maps (only for opt.extopts.WMHC==3) - in development
cat1173plus.output.WMH.native  = 0;
cat1173plus.output.WMH.warped  = 0;
cat1173plus.output.WMH.mod     = 0;
cat1173plus.output.WMH.dartel  = 0;

% label 
% background=0, CSF=1, GM=2, WM=3, WMH=4 (if opt.extropts.WMHC==3)
cat1173plus.output.label.native = 1; 
cat1173plus.output.label.warped = 0;
cat1173plus.output.label.dartel = 0;

% jacobian determinant 0/1 (none/yes)
cat1173plus.output.jacobian.warped = 0;

% deformations
% order is [forward inverse]
cat1173plus.output.warps        = [0 0];


% Expert options
%=======================================================================
% general GUI compatible definition of most *str parameter: 
% 0    - no correction
% eps  - ultralight correction
% 0.25 - light  correction
% 0.50 - medium correction 
% 0.75 - strong correction 
% 1    - heavy  correction
% [inf - automatic correction] 

% skull-stripping options
cat1173plus.extopts.gcutstr      = 2;   % Strength of skull-stripping:               0 to 1; default 0.5
cat1173plus.extopts.cleanupstr   = 0.5; % Strength of the cleanup process:           0 to 1; default 0.5

% segmentation options
cat1173plus.extopts.NCstr        =-Inf; % Strength of the noise correction:          0 to 1; 0 - no filter; -Inf - auto; 1 - full; 2 - ISARNLM (else SANLM), default -Inf
cat1173plus.extopts.LASstr       = 0.5; % Strength of the local adaption:            0 to 1; default 3
cat1173plus.extopts.BVCstr       = 0.5; % Strength of the Blood Vessel Correction:   0 to 1; default 3
cat1173plus.extopts.regstr       = 0;   % Strength of Shooting registration:         0 - Dartel, eps (fast) to 1 (accurate) optimized Shooting, 4 - default Shooting;
cat1173plus.extopts.WMHC         = 1;   % Correction of WM hyperintensities:         0 - no correction; 1 - only for Dartel (default); 
                                %                                            2 - also correct segmentation (to WM); 3 - handle as separate class
cat1173plus.extopts.WMHCstr      = 0.5; % Strength of WM hyperintensity correction:  0 to 5; default 3
cat1173plus.extopts.mrf          = 1;   % MRF weighting:                             0 to <1, 1 - auto; default = 1
cat1173plus.extopts.INV          = 1;   % Invert PD/T2 images for preprocessing:     0 - no processing, 1 - try intensity inversion (default), 2 - synthesize T1 image

% resolution options
cat1173plus.extopts.restype      = 'best';        % resolution handling: 'native','fixed','best'
cat1173plus.extopts.resval       = [0.50 0.30];   % resolution value and its variance for the 'fixed' and 'best' restype

%{
native:
    Preprocessing with native resolution.
    In order to avoid interpolation artifacts in the Dartel output the lowest spatial resolution is always limited to the voxel size of the normalized images (default 1.5mm). 

    Examples:
      native resolution       internal resolution 
       0.95 0.95 1.05     >     0.95 0.95 1.05
       0.45 0.45 1.70     >     0.45 0.45 1.70 

best:
    Preprocessing with the best (minimal) voxel dimension of the native image or at least 1.0 mm.'
    The first parameters defines the lowest spatial resolution for every dimension, while the second is used to avoid tiny interpolations for almost correct resolutions.
    In order to avoid interpolation artifacts in the Dartel output the lowest spatial resolution is always limited to the voxel size of the normalized images (default 1.5mm). 

    Examples:
      Parameters    native resolution       internal resolution
      [1.00 0.10]    0.95 1.05 1.25     >     0.95 1.00 1.00
      [1.00 0.10]    0.45 0.45 1.50     >     0.45 0.45 1.00
      [0.75 0.10]    0.45 0.45 1.50     >     0.45 0.45 0.75  
      [0.75 0.10]    0.45 0.45 0.80     >     0.45 0.45 0.80  
      [0.50 0.10]    0.45 0.45 0.80     >     0.45 0.45 0.50  
      [0.50 0.30]    0.50 0.50 1.50     >     0.50 0.50 0.50
      [0.50 0.30]    1.50 1.50 3.00     >     1.00 0.00 1.00 % here the internal minimum of 1.0 mm is important. 
      [0.00 0.10]    0.45 0.45 1.50     >     0.45 0.45 0.45  

fixed:
    This options prefers an isotropic voxel size that is controlled by the first parameter.  
    The second parameter is used to avoid tiny interpolations for almost correct resolutions. 
    In order to avoid interpolation artifacts in the Dartel output the lowest spatial resolution is always limited to the voxel size of the normalized images (default 1.5mm). 
    There is no upper limit, but we recommend to avoid unnecessary interpolation.

    Examples: 
      Parameters     native resolution       internal resolution
      [1.00 0.10]     0.45 0.45 1.70     >     1.00 1.00 1.00
      [1.00 0.10]     0.95 1.05 1.25     >     0.95 1.05 1.00
      [1.00 0.02]     0.95 1.05 1.25     >     1.00 1.00 1.00
      [1.00 0.10]     0.95 1.05 1.25     >     0.95 1.05 1.00
      [0.75 0.10]     0.75 0.95 1.25     >     0.75 0.75 0.75

%}


% registration and normalization options 
% Subject species: - 'human';'ape_greater';'ape_lesser';'monkey_oldworld';'monkey_newwold' (in development)
cat1173plus.extopts.species      = 'human';  
% Affine PreProcessing (APP) with rough bias correction and brain extraction for special anatomies (nonhuman/neonates) 
cat1173plus.extopts.APP          = 1070;   % 0 - none; 1070 - default; [1 - light; 2 - full; 3 - strong; 4 - heavy, 5 - animal (no affreg)]
cat1173plus.extopts.vox          = 1.5; % voxel size for normalized data (EXPERIMENTAL:  inf - use Tempate values)
cat1173plus.extopts.darteltpm    = {fullfile(spm('dir'),'toolbox','cat12','templates_volumes','Template_1_IXI555_MNI152.nii')};     % Indicate first Dartel template (Template_1)
cat1173plus.extopts.shootingtpm  = {fullfile(spm('dir'),'toolbox','cat12','templates_volumes','Template_0_IXI555_MNI152_GS.nii')};  % Indicate first Shooting template (Template 0) - not working
cat1173plus.extopts.cat12atlas   = {fullfile(spm('dir'),'toolbox','cat12','templates_volumes','cat.nii')};                       % CAT atlas with major regions for VBM, SBM & ROIs
cat1173plus.extopts.brainmask    = {fullfile(spm('Dir'),'MapsAdded','brainmask_2mm.nii')};                                 % Brainmask for affine registration
cat1173plus.extopts.T1           = {fullfile(spm('Dir'),'MapsAdded','T1_2mm.nii')};                                        % T1 for affine registration

% surface options
cat1173plus.extopts.pbtres         = 0.5;   % internal resolution for thickness estimation in mm (default 0.5) 
cat1173plus.extopts.close_parahipp = 0;     % optionally apply closing inside mask for parahippocampal gyrus to get rid of the holes that lead to large
                                    % cuts in gyri after topology correction. However, this may also lead to poorer quality of topology 
                                    % correction for other data and should be only used if large cuts in the parahippocampal areas occur
cat1173plus.extopts.scale_cortex   = 0.7;   % scale intensity values for cortex to start with initial surface that is closer to GM/WM border to prevent that gyri/sulci are glued 
                                    % if you still have glued gyri/sulci (mainly in the occ. lobe) you can try to decrease this value (start with 0.6)
                                    % please note that decreasing this parameter also increases the risk of an interrupted parahippocampal gyrus
cat1173plus.extopts.add_parahipp   = 0.1;   % increase values in the parahippocampal area to prevent large cuts in the parahippocampal gyrus (initial surface in this area
                                    % will be closer to GM/CSF border)
                                    % if the parahippocampal gyrus is still cut you can try to increase this value (start with 0.15)

% visualisation, print, developing, and debugging options
cat1173plus.extopts.colormap     = 'BCGWHw'; % {'BCGWHw','BCGWHn'} and matlab colormaps {'jet','gray','bone',...};
cat1173plus.extopts.verb         = 2;     % verbose output:        1 - default; 2 - details; 3 - write debugging files 
cat1173plus.extopts.ignoreErrors = 0;     % catch errors:          0 - stop with error (default); 1 - catch preprocessing errors (requires MATLAB 2008 or higher); 
cat1173plus.extopts.expertgui    = 0;     % control of user GUI:   0 - common user modus with simple GUI; 1 - expert modus with extended GUI; 2 - development modus with full GUI
cat1173plus.extopts.subfolders   = 1;     % use subfolders such as mri, surf, report, and label to organize your data
cat1173plus.extopts.experimental = 0;     % experimental functions: 0 - default, 1 - call experimental unsave functions
cat1173plus.extopts.print        = 2;     % display and print out pdf-file of results: 0 - off, 2 - volume only, 2 - volume and surface (default)


% Expert options - ROIs
%=======================================================================
% ROI maps from different sources mapped to Dartel CAT-space of IXI-template
%  { filename , GUIlevel , tissue , use }
%  filename    = ''                                  - path to the ROI-file
%  GUIlevel    = [ 0 | 1 | 2 ]                       - avaible in GUI level         
%  tissue      = {['csf','gm','wm','brain','none']}  - tissue classes for volume estimation
%  use         = [ 0 | 1 ]                           - default setting to use this atlas 
cat1173plus.extopts.atlas       = { ... 
  fullfile(spm('dir'),'toolbox','cat12','templates_volumes','neuromorphometrics.nii')  0      {'csf','gm'}        1; ... % atlas based on 35 subjects
  fullfile(spm('dir'),'toolbox','cat12','templates_volumes','lpba40.nii')              0      {'gm'}              0; ... % atlas based on 40 subjects
  fullfile(spm('dir'),'toolbox','cat12','templates_volumes','cobra.nii')               0      {'gm','wm'}         0; ... % hippocampus-amygdala-cerebellum, 5 subjects, 0.6 mm voxel size 
  fullfile(spm('dir'),'toolbox','cat12','templates_volumes','hammers.nii')             0      {'csf','gm','wm'}   0; ... % atlas based on 20 subjects
  fullfile(spm('dir'),'toolbox','cat12','templates_volumes','ibsr.nii')                1      {'csf','gm'}        0; ... % less regions, 18 subjects, low T1 image quality
  fullfile(spm('dir'),'toolbox','cat12','templates_volumes','aal3.nii')                 1      {'gm'}              0; ... % many regions, but only labeled on one subject 
  fullfile(spm('dir'),'toolbox','cat12','templates_volumes','mori.nii')                1      {'gm','wm'}         0; ... % only one subject, but with WM regions
  fullfile(spm('dir'),'toolbox','cat12','templates_volumes','anatomy.nii')             1      {'gm','wm'}         0; ... % ROIs requires further work >> use Anatomy toolbox
}; 


%=======================================================================
% PRIVATE PARAMETER (NOT FOR GENERAL USE)
%=======================================================================


% Additional maps
%=======================================================================
% Tissue classes 4-6 to create own TPMs
cat1173plus.output.TPMC.native = 0; 
cat1173plus.output.TPMC.warped = 0;
cat1173plus.output.TPMC.mod    = 0;
cat1173plus.output.TPMC.dartel = 0;

% atlas maps (for evaluation)
cat1173plus.output.atlas.native = 0; 
cat1173plus.output.atlas.warped = 0; 
cat1173plus.output.atlas.dartel = 0; 

% IDs of the ROIs in the cat atlas map (cat.nii). Do not change this!
cat1173plus.extopts.LAB.NB =  0; % no brain 
cat1173plus.extopts.LAB.CT =  1; % cortex
cat1173plus.extopts.LAB.CB =  3; % Cerebellum
cat1173plus.extopts.LAB.BG =  5; % BasalGanglia 
cat1173plus.extopts.LAB.BV =  7; % Blood Vessels
cat1173plus.extopts.LAB.TH =  9; % Hypothalamus 
cat1173plus.extopts.LAB.ON = 11; % Optical Nerve
cat1173plus.extopts.LAB.MB = 13; % MidBrain
cat1173plus.extopts.LAB.BS = 13; % BrainStem
cat1173plus.extopts.LAB.VT = 15; % Ventricle
cat1173plus.extopts.LAB.NV = 17; % no Ventricle
cat1173plus.extopts.LAB.HC = 19; % Hippocampus 
cat1173plus.extopts.LAB.HD = 21; % Head
cat1173plus.extopts.LAB.HI = 23; % WM hyperintensities
cat1173plus.extopts.LAB.PH = 25; % Gyrus parahippocampalis
cat1173plus.extopts.LAB.LE = 27; % lesions
 

