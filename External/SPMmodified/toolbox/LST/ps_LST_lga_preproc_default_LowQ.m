function [job1, job2, job3] = ps_LST_lga_preproc_default_LowQ

job1.channel.biasreg = 0.00001;
job1.channel.biasfwhm = 60;
job1.channel.write = [0 1];
job1.tissue(1).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,1')};
job1.tissue(1).ngaus = 1;
job1.tissue(1).native = [1 0];
job1.tissue(1).warped = [0 0];
job1.tissue(2).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,2')};
job1.tissue(2).ngaus = 1;
job1.tissue(2).native = [1 0];
job1.tissue(2).warped = [0 0];
job1.tissue(3).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,3')};
job1.tissue(3).ngaus = 1;
job1.tissue(3).native = [1 0];
job1.tissue(3).warped = [0 0];
job1.tissue(4).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,4')};
job1.tissue(4).ngaus = 3;
job1.tissue(4).native = [0 0];
job1.tissue(4).warped = [0 0];
job1.tissue(5).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,5')};
job1.tissue(5).ngaus = 4;
job1.tissue(5).native = [0 0];
job1.tissue(5).warped = [0 0];
job1.tissue(6).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,6')};
job1.tissue(6).ngaus = 2;
job1.tissue(6).native = [0 0];
job1.tissue(6).warped = [0 0];
job1.warp.mrf = 1;
job1.warp.cleanup = 0;
job1.warp.reg = [0 0.001 0.5 0.05 0.2];
job1.warp.affreg = 'mni';
job1.warp.fwhm = 0;
job1.warp.samp = 9;
job1.warp.write = [1 0];

job2.channel.biasreg = 0.00001;
job2.channel.biasfwhm = 60;
job2.channel.write = [0 1];
job2.tissue(1).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,1')};
job2.tissue(1).ngaus = 1;
job2.tissue(1).native = [0 0];
job2.tissue(1).warped = [0 0];
job2.tissue(2).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,2')};
job2.tissue(2).ngaus = 1;
job2.tissue(2).native = [0 0];
job2.tissue(2).warped = [0 0];
job2.tissue(3).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,3')};
job2.tissue(3).ngaus = 1;
job2.tissue(3).native = [0 0];
job2.tissue(3).warped = [0 0];
job2.tissue(4).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,4')};
job2.tissue(4).ngaus = 3;
job2.tissue(4).native = [0 0];
job2.tissue(4).warped = [0 0];
job2.tissue(5).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,5')};
job2.tissue(5).ngaus = 4;
job2.tissue(5).native = [0 0];
job2.tissue(5).warped = [0 0];
job2.tissue(6).tpm = {fullfile(spm('dir'), 'tpm', 'TPM.nii,6')};
job2.tissue(6).ngaus = 2;
job2.tissue(6).native = [0 0];
job2.tissue(6).warped = [0 0];
job2.warp.mrf = 1;
job2.warp.cleanup = 0;
job2.warp.reg = [0 0.001 0.5 0.05 0.2];
job2.warp.affreg = 'mni';
job2.warp.fwhm = 0;
job2.warp.samp = 9;
job2.warp.write = [0 0];

job3.other = {''};
job3.eoptions.cost_fun = 'nmi';
job3.eoptions.sep = [4];
job3.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
job3.eoptions.fwhm = [7 7];
job3.roptions.interp = 1;
job3.roptions.wrap = [0 0 0];
job3.roptions.mask = 0;
job3.roptions.prefix = 'r';

end