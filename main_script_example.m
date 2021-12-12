%raw folder should be in'/NAS/home/s_sanami/Documents/Naj/BIDS_test/final_report/' with subjects
%in it
%JSON file should be in
%'/NAS/home/s_sanami/Documents/Naj/BIDS_test/final_report/CIRM' and at the
%same time should be in
%'/NAS/home/s_sanami/Documents/exploreASL/github_repo/Development/ConfigFiles'

addpath(genpath( '/NAS/home/s_sanami/Documents/ASLtoobox/spm12'))
addpath('/NAS/home/s_sanami/Documents/exploreASL/github_repo/')
prompt='Insert data directory: ';
dir = input(prompt);

ExploreASL_Import_2(ExploreASL_ImportConfig(dir));