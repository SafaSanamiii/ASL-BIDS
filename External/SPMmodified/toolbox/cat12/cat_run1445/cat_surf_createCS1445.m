function [Yth1,S,Psurf,EC,defect_size] = cat_surf_createCS(V,V0,Ym,Ya,Yp0,YMF,opt)
% ______________________________________________________________________
% Surface creation and thickness estimation.
%
% [Yth1,S,Psurf,EC]=cat_surf_createCS(V,V0,Ym,Ya,YMF,opt)
%
% Yth1  = thickness map
% S     = structure with surfaces, like the left hemishere, that contains
%        vertices, faces, GM thickness (th1), and the transformation to
%        map to nifti space (vmat) and back (vmati).
% Psurf = name of surface files
% EC    = Euler characteristics
% defect_size = size of topology defects
% V     = spm_vol-structure of internally interpolated image
% V0    = spm_vol-structure of original image
% Ym    = the (local) intensity, noise, and bias corrected T1 image
% Ya    = the atlas map with the ROIs for left and right hemispheres
%        (this is generated with cat_vol_partvol)
% Yp0   = label image for surface deformation
% YMF   = a logical map with the area that has to be filled
%        (this is generated with cat_vol_partvol)
%   
% opt.surf       = {'lh','rh'[,'lc','rc']} - side
%    .reduceCS   = 100000 - number of faces
%
% Options set by cat_defaults.m
%    .interpV    = 0.5    - mm-resolution for thickness estimation
% 
% Here we used the intensity normalized image Ym, rather that the Yp0
% image, because it has more information about sulci that we need 
% especialy for asymetrical sulci.
% Furthermore, all non-cortical regions and blood vessels were removed 
% (for left and right surface). Blood vessels (with high contrast) can 
% lead to strong error in the topology correction. Higher resolution 
% also helps to reduce artifacts.
% ______________________________________________________________________
% Robert Dahnke 
% Structural Brain Mapping Group
% University Jena
% ______________________________________________________________________
% $Id: cat_surf_createCS1445.m 1523 2019-11-21 23:12:24Z gaser $ 

% Turn off gifti data warning in gifti/subsref (line 45)
%   Warning: A value of class "int32" was indexed with no subscripts specified. 
%            Currently the result of this operation is the indexed value itself, 
%            but in a future release, it will be an error. 
warning('off','MATLAB:subscripting:noSubscriptsSpecified');

%#ok<*AGROW>
  dbs   = dbstatus; debug = 0; for dbsi=1:numel(dbs), if strcmp(dbs(dbsi).name,mfilename); debug = 1; break; end; end
 
  % set defaults
  vx_vol  = sqrt(sum(V.mat(1:3,1:3).^2));   % further interpolation based on internal resolution 
  vx_vol0 = sqrt(sum(V0.mat(1:3,1:3).^2));  % final surface resolution based on original image resolution
  if ~exist('opt','var'), opt=struct(); end
  def.verb      = 2; 
  def.surf      = {'lh','rh'};
  
  % reducepatch has some issues with self intersections and should only be used for "fast" option
  def.reduceCS = 0;
  
  def.vdist     = max(1,mean(vx_vol0)); % distance between vertices ... at least 1 mm ?
  def.LAB       = cat_get_defaults('extopts.LAB');  
  def.SPM       = 0; 
  def.add_parahipp    = cat_get_defaults('extopts.add_parahipp');
  def.scale_cortex    = cat_get_defaults('extopts.scale_cortex');
  def.close_parahipp  = cat_get_defaults('extopts.close_parahipp');
  def.opt.pbtmethod   = 'pbt2x';
  def.WMT       = 0; % WM/CSF width/depth/thickness
  def.sharpenCB = 0; % in development
  def.extract_pial_white = 0; % Estimate pial and white matter surface (in development and very slow!)

  def.new_release       = 0; % developer flag to test new functionality for new release

  opt           = cat_io_updateStruct(def,opt);
  opt.fast      = any(~cellfun('isempty',strfind(opt.surf,'fst'))) + any(~cellfun('isempty',strfind(opt.surf,'sfst')));
  opt.vol       = any(~cellfun('isempty',strfind(opt.surf,'v')));
  opt.interpV   = max(0.1,min([opt.interpV,1.5]));
  opt.interpVold = opt.interpV; 
  opt.surf      = cat_io_strrep(opt.surf,{'sfst','fst','v'},'');
  
  if opt.new_release || opt.extract_pial_white
    force_no_selfintersections = 1;
  else
    force_no_selfintersections = 0;
  end
  
  if opt.fast==2, opt.reduceCS = 40000; end
  if opt.fast
    opt.fsavgDir  = fullfile(spm('dir'),'toolbox','cat12','templates_surfaces_32k'); 
  else
    opt.fsavgDir  = fullfile(spm('dir'),'toolbox','cat12','templates_surfaces'); 
  end

  Psurf = struct(); 

  % correction for 'n' prefix for noise corrected and/or interpolated files
  [pp,ff]   = spm_fileparts(V.fname);

  if cat_get_defaults('extopts.subfolders')
    if strcmp(opt.pbtmethod,'pbt3')
      surffolder = sprintf('surf_%s_%0.2f',opt.pbtmethod,opt.interpV);
    elseif strcmp(opt.pbtmethod,'pbt2xf')
      opt.pbtmethod = 'pbt2x';
      surffolder = sprintf('surf_%s_%0.2f',opt.pbtmethod,opt.interpV);
    else
      surffolder = 'surf';
    end
    mrifolder = 'mri';
    pp = spm_str_manip(pp,'h'); % remove 'mri' in pathname that already exists
    if ~exist(fullfile(pp,surffolder),'dir'), mkdir(fullfile(pp,surffolder)); end
  else
    surffolder = '';
    mrifolder = '';
  end

  if ff(1)=='n'
    if (exist(fullfile(pp,[ff(2:end) '.nii']), 'file')) || (exist(fullfile(pp,[ff(2:end) '.img']), 'file'))
      ff = ff(2:end);
    end
  end

  %% get both sides in the atlas map
  NS = @(Ys,s) Ys==s | Ys==s+1; 
    
  % noise reduction for higher resolutions (>=1 mm full correction, 1.5 mm as lower limit)
  % (added 20160920 ~R1010 due to servere sulcus reconstruction problems with 1.5 Tesla data)
  Yms = Ym + 0; cat_sanlm(Yms,3,1);
  %noise = std(Yms(Yms(:)>0) - Ym(Yms(:)>0)); % more selective filtering?
  %vx_vol = [0.5;0.75;1;1.25;1.5;2]; [vx_vol
  %min(1,max(0,3-2*mean(vx_vol,2))) min(1,max(0,1-mean(vx_vol,2))/2) 0.5*min(1,max(0,1.5-mean(vx_vol,2)))] % filter test 
  mf  = min(1,max(0,3-2*mean(vx_vol,2))); 
  Ym  = mf * Yms  +  (1-mf) * Ym;
  clear Yms;
   
  % filling
  Ymf  = max(Ym,min(0.95,YMF)); 
  Ymfs = cat_vol_smooth3X(Ymf,1); 
  Ytmp = cat_vol_morph(YMF,'d',3) & Ymfs>2.3/3;
  Ymf(Ytmp) = max(min(Ym(Ytmp),0),Ymfs(Ytmp)); clear Ytmp Ymfs; 
  Ymf = Ymf*3;
  
  %% reduction of artifact, blood vessel, and meninges next to the cortex
  % (are often visible as very thin structures that were added to the WM 
  % or removed from the brain)
  if ~opt.SPM
    Ydiv  = cat_vol_div(Ymf,vx_vol); 
    Ycsfd = cat_vbdist(single(Ymf<1.5),Ymf>1,vx_vol);
    Yctd  = cat_vbdist(single(Ymf<0.5),Ymf>0,vx_vol); 
    Ysroi = Ymf>2  &  Yctd<10  & Ycsfd>0 & Ycsfd<2 & ...
            cat_vol_morph(~NS(Ya,opt.LAB.HC) & ~NS(Ya,opt.LAB.HI) & ...
              ~NS(Ya,opt.LAB.PH) & ~NS(Ya,opt.LAB.VT),'erode',4); 
    Ybv   = cat_vol_morph(Ymf+Ydiv./max(1,Ymf)>3.5,'d') & Ymf>2; 
    Ymf(Ybv) = 1.4; 
    Ymfs  = cat_vol_median3(Ymf,Ysroi | Ybv,Ymf>eps & ~Ybv,0.1); % median filter
    %%
    Ymf   = mf * Ymfs  +  (1-mf) * Ymf;

    %% closing of small WMHs and blood vessels
    %vols = [sum(round(Ymf(:))==1 & Ya(:)>0) sum(round(Ymf(:))==2)  sum(round(Ymf(:))==3)] / sum(round(Ymf(:))>0); 
    %volt = min(1,max(0,mean([ (vols(1)-0.20)*5  (1 - max(0,min(0.3,vols(3)-0.2))*10) ]))); 
    %Ywmh = cat_vol_morph(Ymf>max(2.2,2.5 - 0.3*volt),'lc',volt); 
    %Ymf  = max(Ymf,smooth3(Ywmh)*2.9); 
  
    % gaussian filter? ... only in tissue regions
    %Ymfs = cat_vol_smooth3X(max(1,Ymf),0.5*min(1,max(0,1.5-mean(vx_vol)))); 
    %Ymf(Ymf>1) = Ymfs(Ymf>1);
  end
  if ~debug, clear Ysroi Ymfs Yctd Ybv Ymfs; end
  
  %% sharpening of thin structures (gyri and sulci)
  % WARNING: this will change cortical thickness!
  if ~opt.SPM && opt.sharpenCB
    Ydiv = cat_vol_div(Ymf); %Ydivl  = cat_vol_div(Ymf,vx_vol); 
    Ywmd = cat_vbdist(single(Ymf>2.5),Ymf>1,vx_vol);
    if 0
      %% divergence based
      %  this works in principle but gyral crones and sulcal values are
      %  overestimated ... need limit
      Ymsk = (NS(Ya,opt.LAB.CB) & ((Ymf<2.8 & Ymf>2.0          ) | (Ymf<1.9 & Ymf>1.2         )) ) | ... sulci and gyri in the cerebellum 
             (NS(Ya,opt.LAB.CT) & ((Ymf<2.8 & Ymf>2.0 & Ycsfd>3) | (Ymf<1.9 & Ymf>1.2 & Ywmd>3)) ) | ... distant gyri and sulci in the cerebrum
             (NS(Ya,opt.LAB.PH) & ((Ymf<2.8 & Ymf>2.0 & Ycsfd>3) | (Ymf<1.9 & Ymf>1.2 & Ywmd>3)) );
      Ymf  = min(3,max( min(1,Ymf) , Ymf - (abs(Ydivl) .* Ydiv) .* Ymsk));
    end
    
    if 1
      %% biascorrection based
      % WM 
      Ymsk = ((NS(Ya,opt.LAB.CB) | YMF) & ( Ymf>2.2 | (Ymf>2 & Ydiv<-0.01) ) ) | ...                     % sulci and gyri in the cerebellum 
             (NS(Ya,opt.LAB.PH) & ( Ymf>2.2 | (Ymf>2 & Ydiv<-0.01) ) ) | ...                             % hippocampal gyri
             (NS(Ya,opt.LAB.CT) & ( Ymf>2.2 | (Ymf>2 & Ydiv<-0.01 & Ycsfd>cat_stat_nanmean(Ycsfd(Ycsfd(:)>0 & Ycsfd(:)<100)) )*1.0) ); % distant gyri and sulci in the cerebrum
      Yi   = cat_vol_localstat(Ymf,Ymsk,1,3);
      % GM
      Ymsk = (NS(Ya,opt.LAB.CB) & ( Ymf>1.9 & Ymf<2.2 & Ycsfd>0 & Ydiv>-0.05) ) | ...                   % sulci and gyri in the cerebellum 
             (NS(Ya,opt.LAB.PH) & ( Ymf>1.3 & Ymf<2.2 & Ycsfd>0 ) ) | ...                               % hippocampal gyri
             (NS(Ya,opt.LAB.CT) & ( Ymf>1.3 & Ymf<2.2 & Ycsfd>0 & Ywmd>cat_stat_nanmean(Ywmd(Ywmd(:)>0 & Ywmd(:)<100))*0.2 ) );   % distant gyri and sulci in the cerebrum
      Yi   = Yi + cat_vol_localstat(Ymf,Yi==0 & Ymsk,1,1)/2*3;
      Yi   = cat_vol_localstat(Yi,Yi>0,1,3);
      Yi   = cat_vol_localstat(Yi,Yi>0,1,1); 
      if ~debug, clear Ywmd; end
      %% CSF - instable and not required
      %Ymsk = NS(Ya,opt.LAB.VT) & Ymf>=0.5 & Ymf<1.5;                               % sulci and gyri in the cerebellum 
      %Yi  = Yi + cat_vol_localstat(Ymf,Yi==0 & Ymsk,1,3)*3;
      %%
      Ywi = cat_vol_approx(Yi,'nn',1,2,struct('lfO',2)); 
      
      %%
      Ymf = Ymf./Ywi * 3; 
      if ~debug, clear Ywi Yi; end
    end
    if ~debug, clear Ymsk; end
  end
  if ~debug, clear Ydiv Ycsfd; end
  
  Yth1 = zeros(size(Ymf),'single'); 
  if opt.WMT > 1
    Ywd  = zeros(size(Ymf),'single'); 
    Ycd  = zeros(size(Ymf),'single'); 
  end
  
  [D,I] = cat_vbdist(single(Ya>0)); Ya = Ya(I); % for sides
  
  % use sum of EC's and defect sizes for all surfaces, thus set values initially to 0
  EC = 0;
  defect_size = 0;

  for si=1:numel(opt.surf)
   
    % surface filenames
    Praw       = fullfile(pp,surffolder,sprintf('%s.central.nofix.%s.gii',opt.surf{si},ff));    % raw
    Psphere0   = fullfile(pp,surffolder,sprintf('%s.sphere.nofix.%s.gii',opt.surf{si},ff));     % sphere.nofix
    Pcentral   = fullfile(pp,surffolder,sprintf('%s.central.%s.gii',opt.surf{si},ff));          % central
    Ppial      = fullfile(pp,surffolder,sprintf('%s.pial.%s.gii',opt.surf{si},ff));             % pial (GM/CSF)
    Pwhite     = fullfile(pp,surffolder,sprintf('%s.white.%s.gii',opt.surf{si},ff));            % white (WM/GM)
    Pthick     = fullfile(pp,surffolder,sprintf('%s.thickness.%s',opt.surf{si},ff));            % thickness / GM depth
    Pmask      = fullfile(pp,surffolder,sprintf('%s.mask.%s',opt.surf{si},ff));                 % mask
    Ptemp      = fullfile(pp,surffolder,sprintf('%s.temp.%s',opt.surf{si},ff));                 % temporary file
    Pgwo       = fullfile(pp,surffolder,sprintf('%s.depthWMo.%s',opt.surf{si},ff));             % gyrus width / GWM depth / gyral span
    Pgw        = fullfile(pp,surffolder,sprintf('%s.depthGWM.%s',opt.surf{si},ff));             % gyrus width / GWM depth / gyral span
    Pgww       = fullfile(pp,surffolder,sprintf('%s.depthWM.%s',opt.surf{si},ff));              % gyrus witdh of the WM / WM depth
    Pgwwg      = fullfile(pp,surffolder,sprintf('%s.depthWMg.%s',opt.surf{si},ff));             % gyrus witdh of the WM / WM depth
    Psw        = fullfile(pp,surffolder,sprintf('%s.depthCSF.%s',opt.surf{si},ff));             % sulcus width / CSF depth / sulcal span
    Pdefects0  = fullfile(pp,surffolder,sprintf('%s.defects.%s',opt.surf{si},ff));              % defects temporary file
    Pdefects   = fullfile(pp,surffolder,sprintf('%s.defects.%s.gii',opt.surf{si},ff));          % defects
    Psphere    = fullfile(pp,surffolder,sprintf('%s.sphere.%s.gii',opt.surf{si},ff));           % sphere
    Pspherereg = fullfile(pp,surffolder,sprintf('%s.sphere.reg.%s.gii',opt.surf{si},ff));       % sphere.reg
    Pfsavg     = fullfile(opt.fsavgDir, sprintf('%s.central.freesurfer.gii',opt.surf{si}));     % fsaverage central
    Pfsavgsph  = fullfile(opt.fsavgDir, sprintf('%s.sphere.freesurfer.gii',opt.surf{si}));      % fsaverage sphere    
    Pfsavgmask = fullfile(opt.fsavgDir, sprintf('%s.mask',opt.surf{si}));                       % fsaverage mask    
    
    surffile = {'Praw','Psphere0','Pcentral','Pthick','Pgw','Pgww','Psw',...
      'Pdefects0','Pdefects','Psphere','Pspherereg','Pfsavg','Pfsavgsph','Pwhite','Ppial'};
    for sfi=1:numel(surffile)
      eval(sprintf('Psurf(si).%s = %s;',surffile{sfi},surffile{sfi})); 
    end
        
    % reduce for object area
    switch opt.surf{si}
      case {'lh'},  Ymfs = Ymf .* (Ya>0) .* ~(NS(Ya,opt.LAB.CB) | NS(Ya,opt.LAB.BV) | NS(Ya,opt.LAB.ON) | NS(Ya,opt.LAB.MB)) .* (mod(Ya,2)==1); Yside = mod(Ya,2)==1; 
      case {'rh'},  Ymfs = Ymf .* (Ya>0) .* ~(NS(Ya,opt.LAB.CB) | NS(Ya,opt.LAB.BV) | NS(Ya,opt.LAB.ON) | NS(Ya,opt.LAB.MB)) .* (mod(Ya,2)==0); Yside = mod(Ya,2)==0;  
      case {'lc'},  Ymfs = Ymf .* (Ya>0) .*   NS(Ya,opt.LAB.CB).* (mod(Ya,2)==1); Yside = mod(Ya,2)==1; 
      case {'rc'},  Ymfs = Ymf .* (Ya>0) .*   NS(Ya,opt.LAB.CB).* (mod(Ya,2)==0); Yside = mod(Ya,2)==0; 
    end 
    
    switch opt.surf{si}
      case {'lh','rh'}, opt.interpV = opt.interpVold; 
      case {'lc','rc'}, opt.interpV = opt.interpVold / 2 ; 
    end 
    
    % check for cerebellar hemis
    iscerebellum = strcmp(opt.surf{si},'lc') || strcmp(opt.surf{si},'rc');
    
    % scaling factor for reducing patches and refinement for cerebellar hemis 2..4 according to voxel size
    % or 1 for cerebrum
    scale_cerebellum  = 1 + (iscerebellum*max(1,min(3,1/mean(vx_vol,2))));
    
    % get dilated mask of gyrus parahippocampalis and hippocampus of both sides
    if ~iscerebellum
      mask_parahipp = cat_vol_morph(NS(Ya,opt.LAB.PH) | NS(Ya,opt.LAB.HC),'d',6);
    end
    
    %% thickness estimation
    if si==1, fprintf('\n'); end
    
    switch opt.fast
      case 2, fprintf('%s - fast with registration:\n',opt.surf{si});
      case 1, fprintf('%s - fast without registration:\n',opt.surf{si});
      case 0, fprintf('%s:\n',opt.surf{si});
    end
    
    stime = cat_io_cmd(sprintf('  Thickness estimation (%0.2f mm%s)',opt.interpV,native2unicode(179, 'latin1'))); stimet =stime;
    
    % removing background (smoothing to remove artifacts)
    switch opt.surf{si}
      case {'lh','rh'},  [Ymfs,Yside,mask_parahipp,BB] = cat_vol_resize({Ymfs,Yside,mask_parahipp},'reduceBrain',vx_vol,4,smooth3(Ymfs)>1.5); 
      case {'lc','rc'},  [Ymfs,Yside,BB] = cat_vol_resize({Ymfs,Yside},'reduceBrain',vx_vol,4,smooth3(Ymfs)>1.5); 
    end
    
    imethod = 'linear'; %cubic'; % cubic should be better in general - however, linear is better for small thickness 
    [Ymfs,resI]     = cat_vol_resize(max(1,Ymfs),'interp',V,opt.interpV,imethod);                  % interpolate volume
    Yside           = cat_vol_resize(Yside,'interp',V,opt.interpV,imethod)>0.5;                    % interpolate volume (small dilatation)
    
    if ~iscerebellum
      mask_parahipp   = cat_vol_resize(mask_parahipp,'interp',V,opt.interpV)>0.5;          % interpolate volume
    end 
    
    Ymfs = min(3,max(1,Ymfs));

    %% pbt calculation
    if strcmp(opt.pbtmethod,'pbt3')
      [Yth1i,Yppi] = cat_vol_pbt3(Ymfs,struct('method',opt.pbtmethod,'cb',iscerebellum,'resV',opt.interpV,'vmat',V.mat(1:3,:)*[0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1])); % avoid underestimated thickness in gyri
    else
      [Yth1i,Yppi] = cat_vol_pbt(Ymfs,struct('method',opt.pbtmethod,'resV',opt.interpV,'vmat',V.mat(1:3,:)*[0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1])); % avoid underestimated thickness in gyri
    end  
    %%
    if ~opt.WMT && ~debug, clear Ymfs; end
    Yth1i(Yth1i>10)=0; Yppi(isnan(Yppi))=0;  
    [D,I] = cat_vbdist(Yth1i,Yside); Yth1i = Yth1i(I); clear D I;       % add further values around the cortex
    Yth1t = cat_vol_resize(Yth1i,'deinterp',resI); clear Yth1i;         % back to original resolution
    Yth1t = cat_vol_resize(Yth1t,'dereduceBrain',BB);                   % adding background
    Yth1  = max(Yth1,Yth1t);                                            % save on main image
    clear Yth1t;
    %fprintf('%5.0fs\n',etime(clock,stime)); 
    
    if opt.vol
      S = struct(); Psurf = '';
      fprintf('%5.0fs\n',etime(clock,stime)); 
      continue
    end
    
    %% PBT estimation of the gyrus and sulcus width 
    if opt.WMT > 1 
      %% gyrus width / WM depth
      %  For the WM depth estimation it is better to use the L4 boundary
      %  and correct later for thickness, because the WM is very thin in
      %  gyral regions and will cause bad values. 
      %  On the other side we do not want the whole filled block of the 
      %  Yppi map and so we have to mix both the original WM map and the
      %  Yppi map. 
      %  As far as there is no thickness in pure WM regions there will
      %  be no correction. 
      %
      %    figure, isosurface(smooth3(Yppi),0.5,Yth1i), axis equal off
      stime = cat_io_cmd('  WM depth estimation');
      [Yar,Ymr,BB] = cat_vol_resize({Ya,Ym},'reduceBrain',vx_vol,BB.BB);    % removing background
      Yar   = uint8(cat_vol_resize(Yar,'interp',V,opt.interpV,'nearest'));  % interpolate volume
      Ymr   = cat_vol_resize(Ymr,'interp',V,opt.interpV);                   % interpolate volume
      switch opt.surf{si}
        case {'lh'}, 
          Ymr = Ymr .* (Yar>0) .* ~(NS(Yar,3) | NS(Yar,7) | NS(Yar,11) | NS(Yar,13)) .* (mod(Yar,2)==1);
          Ynw = smooth3(cat_vol_morph(NS(Yar,5) | NS(Yar,9) | NS(Yar,15) | NS(Yar,23),'d',2) | ...
                 (cat_vol_morph(Yppi==1,'e',2) & Ymr>1.7/3 & Ymr<2.5/3) & (mod(Yar,2)==1)); 
        case {'rh'},
          Ymr = Ymr .* (Yar>0) .* ~(NS(Yar,3) | NS(Yar,7) | NS(Yar,11) | NS(Yar,13)) .* (mod(Yar,2)==0);    
          Ynw = smooth3(cat_vol_morph(NS(Yar,5) | NS(Yar,9) | NS(Yar,15) | NS(Yar,23),'d',2) | ...
                 (cat_vol_morph(Yppi==1,'e',2) & Ymr>1.7/3 & Ymr<2.5/3) & (mod(Yar,2)==0)); 
        case {'lc'}, Ymr = Ymr .* (Yar>0) .* NS(Yar,3) .* (mod(Yar,2)==1);
        case {'rc'}, Ymr = Ymr .* (Yar>0) .* NS(Yar,3) .* (mod(Yar,2)==0);
      end 
     % clear Yar; 
      %%
      Yppis = Yppi .* (1-Ynw) + max(0,min(1,Ymr*3-2)) .* Ynw;                         % adding real WM map 
      Ywdt  = cat_vol_eidist(1-Yppis,ones(size(Yppis),'single'));                     % estimate distance map to central/WM surface
      Ywdt  = cat_vol_pbtp(max(2,4-Ymfs),Ywdt,inf(size(Ywdt),'single'))*opt.interpV;
      [D,I] = cat_vbdist(single(Ywdt>0.01),Yppis>0); Ywdt = Ywdt(I); clear D I Yppis; % add further values around the cortex
      Ywdt  = cat_vol_median3(Ywdt,Ywdt>0.01,Ywdt>0.01);                    
      Ywdt = cat_vol_localstat(Ywdt,Ywdt>0.1,1,1);     % smoothing
      Ywdt  = cat_vol_resize(Ywdt,'deinterp',resI);                                   % back to original resolution
      Ywdt  = cat_vol_resize(Ywdt,'dereduceBrain',BB);                                % adding background
      Ywd   = max(Ywd,Ywdt); 
      clear Ywdt;
      
      %% sulcus width / CSF depth
      %  for the CSF depth we cannot use the origal data, because of
      %  sulcal blurring, but we got the PP map at half distance and
      %  correct later for half thickness
      fprintf('%5.0fs\n',etime(clock,stime)); 
      stime = cat_io_cmd('  CSF depth estimation');
      YM    = single(smooth3(cat_vol_morph(Ymr<0.1,'o',4))<0.5); YM(YM==0)=nan;       % smooth CSF/background-skull boundary 
      Yppis = Yppi .* ((Ymr+0.25)>Yppi) + min(1,Ymr*3-1) .* ((Ymr+0.25)<=Yppi);       % we want also CSF within the ventricle (for tests)
      Ycdt  = cat_vol_eidist(Yppis,YM);                                               % distance to the cental/CSF-GM boundary
      Ycdt  = cat_vol_pbtp(max(2,Ymfs),Ycdt,inf(size(Ycdt),'single'))*opt.interpV; Ycdt(isnan(Ycdt))=0;
      [D,I] = cat_vbdist(single(Ycdt>0),Yppis>0 & Yppis<3); Ycdt = Ycdt(I); clear D I Yppis; % add further values around the cortex
      Ycdt  = cat_vol_median3(Ycdt,Ycdt>0.01,Ycdt>0.01);                              % median filtering
      Ycdt = cat_vol_localstat(Ycdt,Ycdt>0.1,1,1);                                    % smoothing
      Ycdt  = cat_vol_resize(Ycdt,'deinterp',resI);                                   % back to original resolution
      Ycdt  = cat_vol_resize(Ycdt,'dereduceBrain',BB);                                % adding background
      Ycd   = max(Ycd,Ycdt); 
      clear Ycdt;
      %fprintf('%5.0fs\n',etime(clock,stime));
      clear Ymr;
    end
    
    if ~debug, clear Ymfs; else Yppio=Yppi; end
    fprintf('%5.0fs\n',etime(clock,stime));
    
    %% Replace isolated voxels and holes in Ypp by its median value
    
    % indicate isolated holes and replace by median of the neighbors
    Yppi(Yppi<0.35 & ~cat_vol_morph(Yppi<1,'l'))=1;  % close major wholes in the WM 
    Ymsk = Yppi==0 & cat_vol_morph(Yppi>0.9,'d',1); % filter small wholes close to the WM
    Yppi = cat_vol_median3(single(Yppi),Ymsk,~Ymsk); 
    
    %% indicate isolated objects and replace by median of the neighbors
    Yppi(Yppi>0.65 & cat_vol_morph(Yppi==0,'l'))=0;
    Ymsk = Yppi>0.95 & cat_vol_morph(Yppi<0.1,'d',1); 
    Yppi = cat_vol_median3(single(Yppi),Ymsk,~Ymsk);
    if ~debug, clear Ymsk; end
    
    %% Write Ypp for final deformation
    %  Write Yppi file with 1 mm resolution for the final deformation, 
    %  because CAT_DeformSurf achieved better results using that resolution
    Yppt = cat_vol_resize(Yppi,'deinterp',resI);                        % back to original resolution
    Yppt = cat_vol_resize(Yppt,'dereduceBrain',BB);                     % adding of background
    Vpp  = cat_io_writenii(V,Yppt,'','pp','percentage position map','uint8',[0,1/255],[1 0 0 0]);

    % save hemisphere of Yp0 label image 
    if opt.extract_pial_white
      % mask hemispheres and regions
      switch opt.surf{si}
        case {'lh'},  Yp0s = Yp0 .* (Ya>0) .* ~(NS(Ya,opt.LAB.CB) | NS(Ya,opt.LAB.ON) | NS(Ya,opt.LAB.MB)) .* (mod(Ya,2)==1);  
        case {'rh'},  Yp0s = Yp0 .* (Ya>0) .* ~(NS(Ya,opt.LAB.CB) | NS(Ya,opt.LAB.ON) | NS(Ya,opt.LAB.MB)) .* (mod(Ya,2)==0);   
        case {'lc'},  Yp0s = Yp0 .* (Ya>0) .*   NS(Ya,opt.LAB.CB).* (mod(Ya,2)==1);  
        case {'rc'},  Yp0s = Yp0 .* (Ya>0) .*   NS(Ya,opt.LAB.CB).* (mod(Ya,2)==0); 
      end 
      Vyp0s  = cat_io_writenii(V,Yp0s,'','yp0s','scaled image','uint8',[0,1/255],[1 0 0 0]);
    end
    
    Vpp1 = Vpp; 
    Vpp1.fname    = fullfile(pp,mrifolder,['pp1' ff '.nii']);
    vmat2         = spm_imatrix(Vpp1.mat);
    Vpp1.dim(1:3) = round(Vpp1.dim .* abs(vmat2(7:9)*(1 + iscerebellum)));   % use double resolution in case of cerebellum
    vmat2(7:9)    = sign(vmat2(7:9)).*[1 1 1]/(1 + iscerebellum);            % use double resolution in case of cerebellum
    Vpp1.mat      = spm_matrix(vmat2);

    Vpp1 = spm_create_vol(Vpp1); 
    for x3 = 1:Vpp1.dim(3),
      M    = inv(spm_matrix([0 0 -x3 0 0 0 1 1 1]) * inv(Vpp1.mat) * Vpp.mat); %#ok<MINV>
      v    = spm_slice_vol(Vpp,M,Vpp1.dim(1:2),1);       
      Vpp1 = spm_write_plane(Vpp1,v,x3);
    end;
    clear M v x3; 

    %% surface coordinate transformations
    fprintf('%s %4.0fs\n',repmat(' ',1,66),etime(clock,stimet)); 
    stime = cat_io_cmd('  Create initial surface','g5','',opt.verb); if opt.verb>2, fprintf('\n'); end
    vmatBBV = spm_imatrix(V.mat);

    vmat  = V.mat(1:3,:)*[0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];
    vmati = inv([vmat; 0 0 0 1]); vmati(4,:) = [];    

    % smooth mask to have smooth border
    if ~iscerebellum
      mask_parahipp_smoothed = zeros(size(mask_parahipp));
      spm_smooth(double(mask_parahipp),mask_parahipp_smoothed,[8 8 8]);
    end 

    % parameter for isosurface of Yppi
    th_initial = 0.5;

    ind0 = find(Yppi<=0);
    Yppi = opt.scale_cortex*Yppi;
    
    if ~iscerebellum
      Yppi  = Yppi + opt.add_parahipp/opt.scale_cortex*mask_parahipp_smoothed;
    end
    Yppi(ind0) = 0;
    clear ind0;

    % optionally apply closing inside mask for parahippocampal gyrus to get rid of the holes that lead to large cuts in gyri
    % after topology correction
    if opt.close_parahipp && ~iscerebellum
      tmp = cat_vol_morph(Yppi,'labclose',1);
      Yppi(mask_parahipp) = tmp(mask_parahipp);
    end

    if opt.reduceCS>0
      txt = evalc('[tmp,CS.faces,CS.vertices] = cat_vol_genus0(Yppi,th_initial);');

      % correction for the boundary box used within the surface creation process 
      CS.vertices = CS.vertices .* repmat(abs(opt.interpV ./ vmatBBV([8,7,9])),size(CS.vertices,1),1);
      CS.vertices = CS.vertices +  repmat( BB.BB([3,1,5]) - 1,size(CS.vertices,1),1);
    else
      % if no mesh reduction is selected use lower-scaled Yppt with original voxel size
      Yppt = cat_vol_resize(Yppi,'deinterp',resI);                        % back to original resolution
      Yppt = cat_vol_resize(Yppt,'dereduceBrain',BB);                     % adding of background
      txt = evalc('[tmp,CS.faces,CS.vertices] = cat_vol_genus0(Yppt,th_initial);');
    end
    
    if opt.verb>2, fprintf(txt); end
    if ~debug, clear tmp Yppi Yppt; end

    if opt.verb>2   
      fprintf('%s %4.0fs\n',repmat(' ',1,66),etime(clock,stime)); 
    end
      
    % correct the number of vertices depending on the number of major objects
    if opt.reduceCS>0 
      CS = reducepatch(CS,opt.reduceCS * scale_cerebellum); % adaption for cerebellum
      if opt.verb>2     
        stime = cat_io_cmd(sprintf('  Reduce surface to %d faces:',size(CS.faces,1)),'g5','',opt.verb);
      elseif opt.verb>0
        stime = cat_io_cmd(sprintf('  Reduce surface to %d faces:',size(CS.faces,1)),'g5','',opt.verb,stime);
      end
    end
    
    
    %% transform coordinates 
    if opt.fast==1
      %%
      CS.vertices = (vmat*[CS.vertices' ; ones(1,size(CS.vertices,1))])'; 
      mati = spm_imatrix(V.mat); 
      if mati(7)<0, CS.faces = [CS.faces(:,1) CS.faces(:,3) CS.faces(:,2)]; end
      save(gifti(struct('faces',CS.faces,'vertices',CS.vertices)),Pcentral);    

      % remove some unconnected meshes
      cmd = sprintf('CAT_SeparatePolygon "%s" "%s" -1',Pcentral,Pcentral); % CAT_SeparatePolygon works here
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
      
      % deform initial surface to central surface
      % CAT_DeformSurf "vol" "activity_file?|none" nx ny nz "inputmesh" "outputmesh" "originalposition|none" maxdist n_modls  
      %'CAT_DeformSurf "%s" none 0 0 0 "%s" "%s" ' ... "vol" "activity_file?|none" nx ny nz "inputmesh" "outputmesh"
      %              'none 0 1 -1 .1 ' ...                  "originalposition|none"   maxdist  n_modls  up_to_n_points  model_weight
      %               'avg -0.1 0.1 ' ...                    "model_file...|avg|none"  mincurv  maxcurv 
      %               '.2 .1 5 0 ' ...                       fract_step  max_step  max_search_distance  degrees_continuity  
      %               '"%g" "%g" n ' ...                     min_isovalue  max_isovalue  +/-/n 
      %               '0 0 0 ' ...                           gradient_threshold  angle tolerance  
      %               '150 0.01 0.0 0'], ...                 max_iterations movement_threshold  stop_treshold force_no_selfintersections
                     
      th = 0.5;
      cmds = sprintf(['CAT_DeformSurf "%s" none 0 0 0 "%s" "%s" ' ... "vol" "activity_file?|none" nx ny nz "inputmesh" "outputmesh"
                     'none  0  1  -1  .1 ' ...               "originalposition|none"   maxdist  n_modls  up_to_n_points  model_weight
                     'avg  -0.1  0.1 ' ...                   "model_file...|avg|none"  mincurv  maxcurv 
                     '.2  .1  2  0 ' ...                     fract_step  max_step  max_search_distance  degrees_continuity  
                     '"%g"  "%g"  n ' ...                    min_isovalue  max_isovalue  +/-/n 
                     '0  0  0 ' ...                          gradient_threshold  angle  tolerance  
                     '10  0.03  0.0 0'], ...                 max_iterations movement_threshold  stop_threshold force_no_selfintersections
                      Vpp1.fname,Pcentral,Pcentral,th,th);
      [ST, RS] = cat_system(cmds); cat_check_system_output(ST,RS,opt.verb-2);
    
      % load surf and project thickness
      CS = gifti(Pcentral);
      % ignore this warning writing gifti with int32 (eg. cat_surf_createCS:580 > gifti/subsref:45)
      warning off MATLAB:subscripting:noSubscriptsSpecified
      if mati(7)<0, CS.faces = [CS.faces(:,1) CS.faces(:,3) CS.faces(:,2)]; end
      CS.vertices = (vmati*[CS.vertices' ; ones(1,size(CS.vertices,1))])';
      if exist('GMTn','var')
        facevertexcdata = GMTn; 
      else
        facevertexcdata = isocolors2(Yth1,CS.vertices); 
      end
      cat_io_FreeSurfer('write_surf_data',Pthick,facevertexcdata);
      
      % map WM and CSF width data (corrected by thickness)
      if opt.WMT > 1
        %%
        facevertexcdata2  = isocolors2(Ywd,CS.vertices); 
        facevertexcdata2c = max(eps,facevertexcdata2 - facevertexcdata/2);
        cat_io_FreeSurfer('write_surf_data',Pgwo,facevertexcdata2c); % gyrus width WM only
        facevertexcdata2c = correctWMdepth(CS,facevertexcdata2c,100,0.2);
        cat_io_FreeSurfer('write_surf_data',Pgww,facevertexcdata2c); % gyrus width WM only
        facevertexcdata3c = facevertexcdata2c + facevertexcdata; % );
        cat_io_FreeSurfer('write_surf_data',Pgw,facevertexcdata3c); % gyrus width (WM and GM)
        facevertexcdata4 = estimateWMdepthgradient(CS,facevertexcdata2c);
        cat_io_FreeSurfer('write_surf_data',Pgwwg,facevertexcdata4); % gyrus width WM only > gradient
        % smooth resampled values
        try
          cmd = sprintf('CAT_BlurSurfHK "%s" "%s" "%g" "%s"',Pcentral,Pgwwg,3,Pgwwg);
          [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
        end
        %%
        %clear facevertexcdata2 facevertexcdata2c facevertexcdata3c facevertexcdata4; 
        % just a test ... problem with other species ...
        %norm = sum(Ymf(:)>0.5) / prod(vx_vol) / 1000 / 1400;
        %norm = mean([2 1 1].*diff([min(CS.vertices);max(CS.vertices)])); 
        %norm = mean([2 1 1].*std(CS.vertices)); % maybe the hull surface is better...

        facevertexcdata3 = isocolors2(Ycd,CS.vertices); 
        facevertexcdata3 = max(eps,facevertexcdata3 - facevertexcdata/2); 
        cat_io_FreeSurfer('write_surf_data',Psw,facevertexcdata3);
      end
      
      % distance between linked surfaces 
      %Tlink = @(S1,S2) sum( [ sum( abs( S1.vertices(:,1:2) - S2.vertices(:,1:2) ).^2 , 2 ).^0.5  abs(S1.vertices(:,3) - S2.vertices(:,3)) ].^2 , 2 ).^0.5;
              
      % save datastructure
      S.(opt.surf{si}) = struct('faces',CS.faces,'vertices',CS.vertices,'vmat',vmat,...
          'vmati',vmati,'th1',facevertexcdata);
      if opt.WMT > 1
        setfield(S.(opt.surf{si}),'th2',nan(size(facevertexcdata)));
        setfield(S.(opt.surf{si}),'th3',nan(size(facevertexcdata)));
      end
      
      if ~debug
        delete(Vpp.fname);
        delete(Vpp1.fname);
        if exist('Vyp0s','var'), delete(Vyp0s.fname); end
      end
      fprintf('%5.0fs\n',etime(clock,stime)); 
      
      % estimate Euler characteristics: EC = #vertices + #faces - #edges
      EC0 = size(CS.vertices,1) + size(CS.faces,1) - size(spm_mesh_edges(CS),1);
      EC  = EC + abs(EC0);
      
      %%
      clear CS
      continue
    end
    
    %%
    CS.vertices = (vmat*[CS.vertices' ; ones(1,size(CS.vertices,1))])'; 
    save(gifti(struct('faces',CS.faces,'vertices',CS.vertices)),Praw,'Base64Binary');
    
    if opt.reduceCS>0 
      % after reducepatch many triangles have very large area which causes isses for resampling
      % RefineMesh adds triangles in those areas
      if opt.fast
        cmd = sprintf('CAT_RefineMesh "%s" "%s" %0.2f',Praw,Praw,4 * opt.vdist / scale_cerebellum); % adaption for cerebellum
      else  
        cmd = sprintf('CAT_RefineMesh "%s" "%s" %0.2f',Praw,Praw,2 * opt.vdist / scale_cerebellum); % adaption for cerebellum
      end
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
    
      % remove some unconnected meshes
      cmd = sprintf('CAT_SeparatePolygon "%s" "%s" -1',Praw,Praw); % CAT_SeparatePolygon works here
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
    end

    % spherical surface mapping 1 of the uncorrected surface for topology correction
    cmd = sprintf('CAT_Surf2Sphere "%s" "%s" 5',Praw,Psphere0);
    [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);

    % estimate size of topology defects (in relation to number of vertices and mean brain with 100000 vertices)
    cmd = sprintf('CAT_MarkDefects "%s" "%s" "%s"',Praw,Psphere0,Pdefects0); 
    [ST, RS] = cat_system(cmd);
    defect_sizes = cat_io_FreeSurfer('read_surf_data',Pdefects0);
    defect_size0 = round(100000*sum(defect_sizes > 0)/length(defect_sizes));
    defect_size = defect_size + defect_size0;
    delete(Pdefects0);  

    % mark defects and save as gifti 
    if opt.verb > 2 
      cmd = sprintf('CAT_MarkDefects -binary "%s" "%s" "%s"',Praw,Psphere0,Pdefects0); 
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb);
      cmd = sprintf('CAT_AddValuesToSurf "%s" "%s" "%s"',Praw,Pdefects0,Pdefects);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
    end
   
    % estimate Euler characteristics: EC = #vertices + #faces - #edges
    EC0 = size(CS.vertices,1) + size(CS.faces,1) - size(spm_mesh_edges(CS),1);
    EC  = EC + abs(EC0);
    
    %% topology correction and surface refinement 
    stime = cat_io_cmd('  Topology correction and surface refinement:','g5','',opt.verb,stime); 
    if opt.verb>2, fprintf('\n'); end
    if opt.fast
      cmd = sprintf('CAT_FixTopology -lim 128 -bw 512 -n 40960 -refine_length %g "%s" "%s" "%s"',4 * opt.vdist / scale_cerebellum,Praw,Psphere0,Pcentral);
      try
        [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
      catch
        cmd = sprintf('CAT_FixTopology -lim 128 -bw 512 -n 81920 -refine_length %g "%s" "%s" "%s"',2 * opt.vdist / scale_cerebellum,Praw,Psphere0,Pcentral);
        [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
      end  
    else
      cmd = sprintf('CAT_FixTopology -lim 128 -bw 512 -n 81920 -refine_length %g "%s" "%s" "%s"',2  * opt.vdist / scale_cerebellum,Praw,Psphere0,Pcentral);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
    end
    
    if opt.new_release
      % read final surface and map thickness data
      CS = gifti(Pcentral);
      % ignore this warning writing gifti with int32 (eg. cat_surf_createCS:580 > gifti/subsref:45)
      warning off MATLAB:subscripting:noSubscriptsSpecified
      CS.vertices = (vmati*[CS.vertices' ; ones(1,size(CS.vertices,1))])';
      facevertexcdata = isocolors2(Yth1,CS.vertices); 
      cat_io_FreeSurfer('write_surf_data',Pthick,facevertexcdata);
    
      % final correction of central surface in highly folded areas with high mean curvature
      % The distance value of 0.2 corrects the previous scaling of the cortex with 0.7 to finally
      % result in the correct central surface. Equi-volume weighting of 2.0 provides better starting 
      % points in folded areas for the subsequent surface deformation
      stime = cat_io_cmd('  Correction of central surface in highly folded areas 1','g5','',opt.verb,stime);
      cmd = sprintf(['CAT_Central2Pial -equivolume -weight 2.0 "%s" "%s" "%s" 0.2'], ...
                         Pcentral,Pthick,Pcentral);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
    
      % need refinement because some vertices are too large to be deformed with high accuracy
      if opt.fast
        cmd = sprintf('CAT_RefineMesh "%s" "%s" %0.2f 0',Pcentral,Pcentral,4 * opt.vdist / scale_cerebellum); % adaption for cerebellum
      else
        cmd = sprintf('CAT_RefineMesh "%s" "%s" %0.2f 1',Pcentral,Pcentral,2 * opt.vdist / scale_cerebellum); % adaption for cerebellum
      end
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
    end

    % surface refinement by surface deformation based on the PP map
    stime = cat_io_cmd('  Refine central surface','g5','',opt.verb,stime);
    th = 0.5;
    if opt.fast
      cmd = sprintf(['CAT_DeformSurf "%s" none 0 0 0 "%s" "%s" none 0 1 -1 .1 ' ...
                     'avg -0.1 0.1 .2 .1 5 0 "%g" "%g" n 0 0 0 50 0.02 0.0 %d'], ...
                     Vpp.fname,Pcentral,Pcentral,th,th,0);
    else
      cmd = sprintf(['CAT_DeformSurf "%s" none 0 0 0 "%s" "%s" none 0 1 -1 .1 ' ...
                     'avg -0.1 0.1 .2 .1 5 0 "%g" "%g" n 0 0 0 150 0.01 0.0 %d'], ...
                     Vpp.fname,Pcentral,Pcentral,th,th,force_no_selfintersections);
    end
    [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);

    % need some more refinement because some vertices are distorted after CAT_DeformSurf
    if opt.fast
      cmd = sprintf('CAT_RefineMesh "%s" "%s" %0.2f 0',Pcentral,Pcentral,4 * opt.vdist / scale_cerebellum); % adaption for cerebellum
    else
      if opt.new_release
        cmd = sprintf('CAT_RefineMesh "%s" "%s" %0.2f 1',Pcentral,Pcentral,1.75 * opt.vdist / scale_cerebellum); % adaption for cerebellum
      else
        cmd = sprintf('CAT_RefineMesh "%s" "%s" %0.2f 0',Pcentral,Pcentral,1.5 * opt.vdist / scale_cerebellum); % adaption for cerebellum
      end
    end
    [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);

    if opt.fast
      cmd = sprintf(['CAT_DeformSurf "%s" none 0 0 0 "%s" "%s" none 0 1 -1 .1 ' ...
                     'flat -0.15 0.15 .5 .1 5 0 "%g" "%g" n 0 0 0 25 0.01 0.0 %d'], ...
                     Vpp.fname,Pcentral,Pcentral,th,th,0);
    else
      cmd = sprintf(['CAT_DeformSurf "%s" none 0 0 0 "%s" "%s" none 0 1 -1 .2 ' ...
                     'avg -0.05 0.05 .1 .1 5 0 "%g" "%g" n 0 0 0 50 0.01 0.0 %d'], ...
                     Vpp.fname,Pcentral,Pcentral,th,th,force_no_selfintersections);
    end
    [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);

    % read final surface and map thickness data
    CS = gifti(Pcentral);
    % ignore this warning writing gifti with int32 (eg. cat_surf_createCS:580 > gifti/subsref:45)
    warning off MATLAB:subscripting:noSubscriptsSpecified
    CS.vertices = (vmati*[CS.vertices' ; ones(1,size(CS.vertices,1))])';
    facevertexcdata = isocolors2(Yth1,CS.vertices); 
    cat_io_FreeSurfer('write_surf_data',Pthick,facevertexcdata);

    % final correction of central surface in highly folded areas with high mean curvature
    if ~opt.fast
      stime = cat_io_cmd('  Correction of central surface in highly folded areas 2','g5','',opt.verb,stime);
      cmd = sprintf(['CAT_Central2Pial -equivolume -weight 0.3 "%s" "%s" "%s" 0'], ...
                       Pcentral,Pthick,Pcentral);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
    end

    % final correction of cortical thickness using pial and WM surface
    if opt.extract_pial_white && ~opt.fast
      % estimation of pial surface
      % use slightly larger value (default would be 0.5) to ensure that pial surface in sulci
      % will be close enough and opposite sides will almost touch
      stime = cat_io_cmd('  Estimation of pial surface','g5','',opt.verb,stime);
      cmd = sprintf(['CAT_Central2Pial -check_intersect "%s" "%s" "%s" 0.6'], ...
                       Pcentral,Pthick,Ppial);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
  
      % GM/CSF border is at 1.5/3
      th2 = 0.5;
      cmd = sprintf(['CAT_DeformSurf "%s" none 0 0 0 "%s" "%s" none 0 1 -1 .2 ' ...
                     'avg -0.05 0.05 .1 .1 5 0 "%g" "%g" n 0 0 0 100 0.01 0.0 %d'], ...
                     Vyp0s.fname,Ppial,Ppial,th2,th2,force_no_selfintersections);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);

      stime = cat_io_cmd('  Correction of pial surface in highly folded areas','g5','',opt.verb,stime);
      cmd = sprintf(['CAT_Central2Pial -equivolume -weight 0.3 "%s" "%s" "%s" 0'], ...
                       Ppial,Pthick,Ppial);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);

      % estimation of white matter surface
      stime = cat_io_cmd('  Estimation of white matter surface','g5','',opt.verb,stime);
      cmd = sprintf(['CAT_Central2Pial -check_intersect "%s" "%s" "%s" -0.5'], ...
                       Pcentral,Pthick,Pwhite);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
  
      % GM/WM border is at 2.5/3
      th2 = th2 + 1/3;
      cmd = sprintf(['CAT_DeformSurf "%s" none 0 0 0 "%s" "%s" none 0 1 -1 .2 ' ...
                     'avg -0.05 0.05 .1 .1 5 0 "%g" "%g" n 0 0 0 100 0.01 0.0 %d'], ...
                     Vyp0s.fname,Pwhite,Pwhite,th2,th2,force_no_selfintersections);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);

      stime = cat_io_cmd('  Correction of white matter surface in highly folded areas','g5','',opt.verb,stime);
      cmd = sprintf(['CAT_Central2Pial -equivolume -weight 0.3 "%s" "%s" "%s" 0'], ...
                       Pwhite,Pthick,Pwhite);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);

      % update central surface as average between white and pial surface
      cmd = sprintf(['CAT_AverageSurfaces -avg "%s" "%s" "%s"'], ...
                       Pcentral,Pwhite,Ppial);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);

      if 0 % more testing necessary to also correct thickness
        % correction of cortical thickness
        cmd = sprintf(['CAT_Hausdorff  "%s" "%s" "%s"'], ...
                       Pwhite,Ppial,Pthick);
        [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
      end
    end

    %% spherical surface mapping 2 of corrected surface
    stime = cat_io_cmd('  Spherical mapping with areal smoothing','g5','',opt.verb,stime); 
    if opt.fast
      cmd = sprintf('CAT_Surf2Sphere "%s" "%s" 5',Pcentral,Psphere);
    else
      cmd = sprintf('CAT_Surf2Sphere "%s" "%s" 10',Pcentral,Psphere);
    end
    [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
    
    % spherical registration to fsaverage template
    stime = cat_io_cmd('  Spherical registration','g5','',opt.verb,stime);
    if opt.fast
      cmd = sprintf(['CAT_WarpSurf -i "%s" -is "%s" -t "%s" -ts "%s" -ws "%s" ' ...
        '-size 256 128 -loop 1 -steps 1 -runs 1 -v -fwhm 10 -fwhm-surf 20 -lmreg 0.01'],...
        Pcentral,Psphere,Pfsavg,Pfsavgsph,Pspherereg);
    else
      cmd = sprintf('CAT_WarpSurf -steps 2 -avg -i "%s" -is "%s" -t "%s" -ts "%s" -ws "%s"', ...
        Pcentral,Psphere,Pfsavg,Pfsavgsph,Pspherereg);
    end
    [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
    
    
    % set thickness values to zero for masked area (use inverse transformation to map mask)
    if opt.new_release
      stime = cat_io_cmd('  Correct thickness','g5','',opt.verb,stime);
      cmd = sprintf('CAT_ResampleSurf "%s" "%s" "%s" "%s" "%s" "%s"', ...
        Pfsavg,Pfsavgsph,Pspherereg,Ptemp,Pfsavgmask,Pmask);
      [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);      
      resampled_mask = cat_io_FreeSurfer('read_surf_data',Pmask);
      
      % set thickness to zero for masked area and write thickness data
      facevertexcdata(resampled_mask < 0.5) = 0;
      cat_io_FreeSurfer('write_surf_data',Pthick,facevertexcdata);  
      delete(Pmask)
      delete(Ptemp);
    end
    
    % map WM and CSF width data (corrected by thickness)
    if opt.WMT > 1
      %%
      facevertexcdata2  = isocolors2(Ywd,CS.vertices); 
      facevertexcdata2c = max(eps,facevertexcdata2 - facevertexcdata/2);
      cat_io_FreeSurfer('write_surf_data',Pgwo,facevertexcdata2c); % gyrus width WM only
      facevertexcdata2c = correctWMdepth(CS,facevertexcdata2c,100,0.2);
      cat_io_FreeSurfer('write_surf_data',Pgww,facevertexcdata2c); % gyrus width WM only
      facevertexcdata3c = facevertexcdata2c + facevertexcdata; % );
      cat_io_FreeSurfer('write_surf_data',Pgw,facevertexcdata3c); % gyrus width (WM and GM)
      facevertexcdata4 = estimateWMdepthgradient(CS,facevertexcdata2c);
      cat_io_FreeSurfer('write_surf_data',Pgwwg,facevertexcdata4); % gyrus width WM only > gradient
      % smooth resampled values
      try
        cmd = sprintf('CAT_BlurSurfHK "%s" "%s" "%g" "%s"',Pcentral,Pgwwg,3,Pgwwg);
        [ST, RS] = cat_system(cmd); cat_check_system_output(ST,RS,opt.verb-2);
      end
      %%
      %clear facevertexcdata2 facevertexcdata2c facevertexcdata3c facevertexcdata4; 
      % just a test ... problem with other species ...
      %norm = sum(Ymf(:)>0.5) / prod(vx_vol) / 1000 / 1400;
      %norm = mean([2 1 1].*diff([min(CS.vertices);max(CS.vertices)])); 
      %norm = mean([2 1 1].*std(CS.vertices)); % maybe the hull surface is better...
 
      facevertexcdata3 = isocolors2(Ycd,CS.vertices); 
      facevertexcdata3 = max(eps,facevertexcdata3 - facevertexcdata/2); 
      cat_io_FreeSurfer('write_surf_data',Psw,facevertexcdata3);
    end
    fprintf('%5.0fs\n',etime(clock,stime)); 
    fprintf(' Surface Euler number: %d\n',EC0);
    fprintf(' Overall size of topology defects: %d\n',defect_size0);

    % visualize a side
    % csp=patch(CS); view(3), camlight, lighting phong, axis equal off; set(csp,'facecolor','interp','edgecolor','none')

    % create output structure
    S.(opt.surf{si}) = struct('faces',CS.faces,'vertices',CS.vertices,'vmat',vmat,...
        'vmati',vmati,'th1',facevertexcdata);
    if opt.WMT > 1
      S.(opt.surf{si}) = setfield(S.(opt.surf{si}),'th2',facevertexcdata2);
      S.(opt.surf{si}) = setfield(S.(opt.surf{si}),'th3',facevertexcdata3);
    end
    clear Yth1i
    
    % we have to delete the original faces, because they have a different number of vertices after
    % CAT_FixTopology!
    delete(Praw);  
    if opt.verb > 2
      delete(Pdefects0);  
    end
    delete(Psphere0);
    delete(Vpp.fname);
    delete(Vpp1.fname);
    if opt.extract_pial_white
      delete(Vyp0s.fname);
    end
    clear CS
  end  
  
  % calculate mean EC and defect size for all surfaces
  EC          = round(EC / numel(opt.surf));
  defect_size = round(defect_size / numel(opt.surf));
  
  if opt.verb
    for si=1:numel(Psurf)
      fprintf('Display thickness: %s\n',spm_file(Psurf(si).Pthick,'link','cat_surf_display(''%s'')'));
    end
  end
end

%=======================================================================
function [cdata,i] = correctWMdepth(CS,cdata,iter,lengthfactor)
% ______________________________________________________________________
% Correct deep WM depth values that does not fit to the local thickness 
% of the local gyri.
% 
% lengthfactor should be between 0.2 and 0.4
% ______________________________________________________________________

  if ~exist('lengthfactor','var'), lengthfactor = 1/3; end
  if ~exist('iter','var'), iter = 100; end

  %%
  SV  = CS.vertices;                                                          % Surface Vertices 
  SE  = unique([CS.faces(:,1:2);CS.faces(:,2:3);CS.faces(:,3:-2:1)],'rows');  % Surface Edges
  SEv = single(diff(cat(3,SV(SE(:,1),:),SV(SE(:,2),:)),1,3));                 % Surface Edge Vector
  SEL = sum(SEv.^2,2).^0.5;                                                   % Surface Edge Length  
  clear SEv

  
  %%
  i=0; cdatac = cdata+1; pc = 1; oc = 0; 
  while i<iter && pc~=oc; 
  %%
    pc = sum( abs(cdata - cdatac)>0.05 ); 
    i=i+1; cdatac = cdata;
    
    M  = (cdatac(SE(:,1)) - SEL(SE(:,1))*lengthfactor ) > cdatac(SE(:,2)); 
    cdata(SE(M,1)) = cdatac(SE(M,2)) + SEL(SE(M,1))*lengthfactor; 
    M  = (cdata(SE(:,2)) - SEL(SE(:,2))*lengthfactor ) > cdatac(SE(:,1));
    cdata(SE(M,2)) = cdatac(SE(M,1)) + SEL(SE(M,1))*lengthfactor; 
    oc = sum( abs(cdata - cdatac)>0.05 );
    
    %fprintf('%d - %8.2f - %d\n',i,sum( abs(cdata - cdatac)>0.05 ),pc~=oc)
    
  end
  
end
%=======================================================================
function V = isocolors2(R,V,opt)
% ______________________________________________________________________
% calculates an interpolated value of a vertex in R  
% We have to calculate everything with double, thus larger images will 
% cause memory issues.
% ______________________________________________________________________
  
  if isempty(V), return; end
  if ndims(R)~=3,  error('MATLAB:isocolor2:dimsR','Only 2 or 3 dimensional input of R.'); end
  if ~exist('opt','var'), opt=struct(); end
  
  def.interp = 'linear';
  opt = cat_io_checkinopt(opt,def);
  
  if  isa(R,'double'), R = single(R); end
  if ~isa(V,'double'), V = double(V); VD=0; else VD=1; end
  
  nV   = size(V,1);
  ndim = size(V,2);
  
  switch opt.interp
    case 'nearest'
      V = max(1,min(round(V),repmat(size(R),nV,1))); 
      V = R(sub2ind(size(R),V(:,2),V(:,1),V(:,3)));
    case 'linear'
      nb  = repmat(shiftdim(double([0 0 0;0 0 1;0 1 0;0 1 1;1 0 0;1 0 1;1 1 0;1 1 1]'),-1),nV,1);  
      enb = repmat(shiftdim((ones(8,1,'double')*[size(R,2),size(R,1),size(R,3)])',-1),nV,1);  

      % calculate the weight of a neigbor (volume of the other corner) and
      w8b = reshape(repmat(V,1,2^ndim),[nV,ndim,2^ndim]); clear V;
      % if the streamline is near the boundary of the image you could be out of range if you add 1 
      n8b = min(floor(w8b) + nb,enb); clear enb
      n8b = max(n8b,1);
      w8b = flipdim(prod(abs(n8b - w8b),2),3);        

      % multiply this with the intensity value of R
      V = sum(R(sub2ind(size(R),n8b(:,2,:),n8b(:,1,:),n8b(:,3,:))) .* w8b,3);
  end  
  if ~VD, V = single(V); end
end
    
%=======================================================================
function cdata = estimateWMdepthgradient(CS,cdata)
% ______________________________________________________________________
% Estimates the maximum local gradient of a surface. 
% Major use is the WM depth that grows with increasing sulcal depth. 
% It measures the amount of WM behind the cortex, but more relevant is
% the amount of WM fibers that this region will add to the WM depth. 
% The width of the street next to a house gives not the connectivity of
% this house, but the width of the entrance does!
% This measure can be improved by furhter information of sulcal depth.
% ______________________________________________________________________

  %%
  SV  = CS.vertices;                                                          % Surface Vertices 
  SE  = unique([CS.faces(:,1:2);CS.faces(:,2:3);CS.faces(:,3:-2:1)],'rows');  % Surface Edges
  SEv = single(diff(cat(3,SV(SE(:,1),:),SV(SE(:,2),:)),1,3));                 % Surface Edge Vector
  SEL = sum(SEv.^2,2).^0.5;                                                   % Surface Edge Length  
  clear SEv

  
  %%
  cdata_l = inf(size(cdata),'single'); 
  cdata_h = zeros(size(cdata),'single'); 
  for i=1:size(SE,1)
    val = (cdata(SE(i,2)) - cdata(SE(i,1)))*SEL(SE(i,1));
    cdata_l(SE(i,1)) = min([cdata_l(SE(i,1)),val]);
    cdata_h(SE(i,1)) = max([cdata_h(SE(i,2)),val]);
  end
  cdata = cdata_h - cdata_l; 
end
              
