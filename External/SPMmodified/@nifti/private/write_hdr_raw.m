function sts = write_hdr_raw(fname,hdr,be)
% Write a NIFTI-1 header
% FORMAT sts = write_hdr_raw(fname,hdr,be)
% fname      - filename of image
% hdr        - a structure containing hdr info
% be         - whether big-endian or not [Default: native]
%
% sts        - status (1=good, 0=bad)
%__________________________________________________________________________
% Copyright (C) 2005-2017 Wellcome Trust Centre for Neuroimaging

%
% $Id: write_hdr_raw.m 7147 2017-08-03 14:07:01Z spm $


[pth,nam] = fileparts(fname);
if isempty(pth), pth = pwd; end

% ExploreASL hack
% When hdr.dim(1) a.k.a dim[0], which specifies what is the number of dimensions is <4, but hdr.pixdim(5) ~= 0, then change hdr.dim(1) to 4, otherwise this crashes BIDS validator
if hdr.dim(1) < 4 && hdr.pixdim(5) ~= 0
	% Only do this for ASL and M0 files. For T1w it must not be like that
	if ~isempty(regexpi(nam,'m0')) || ~isempty(regexpi(nam,'asl'))
		hdr.dim(1) = 4;
	end
end

if isfield(hdr,'magic')
    switch hdr.magic(1:3)
        case {'ni1'}
            org = niftistruc('nifti1');
            hname = fullfile(pth,[nam '.hdr']);
        case {'ni2'}
            org = niftistruc('nifti2');
            hname = fullfile(pth,[nam '.hdr']);
        case {'n+1'}
            org = niftistruc('nifti1');
            hname = fullfile(pth,[nam '.nii']);
        case {'n+2'}
            org = niftistruc('nifti2');
            hname = fullfile(pth,[nam '.nii']);
        otherwise
            error('Bad header.');
    end
else
    org   = mayostruc;
    hname = fullfile(pth,[nam '.hdr']);
end

if nargin >= 3
    if be, mach = 'ieee-be';
    else   mach = 'ieee-le';
    end
else       mach = 'native';
end

sts = true;
if spm_existfile(hname)
    [fp,msg] = fopen(hname,'r+',mach);
else
    [fp,msg] = fopen(hname,'w+',mach);
end
if fp == -1
    sts = false;
    fprintf('Error: %s\n',msg);
end

if sts
    for i=1:length(org)
        if isfield(hdr,org(i).label)
            dat = hdr.(org(i).label);
            if length(dat) ~= org(i).len
                if length(dat)< org(i).len
                    if ischar(dat), z = char(0); else z = 0; end
                    dat = [dat(:) ; repmat(z,org(i).len-length(dat),1)];
                else
                    dat = dat(1:org(i).len);
                end
            end
        else
            dat = org(i).def;
        end
        % fprintf('%s=\n',org(i).label)
        % disp(dat)
        len = fwrite(fp,dat,org(i).dtype.prec);
        if len ~= org(i).len
            sts = false;
        end
    end
    fclose(fp);
end

if ~sts
     fprintf('There was a problem writing to the header of\n');
     fprintf('  "%s"\n', fname);
end
