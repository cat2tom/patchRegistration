origPath = '/data/vision/polina/scratch/patchRegistration/input/stroke/proc/brain_pad10/';
runPath = '/data/vision/polina/scratch/patchRegistration/output/stroke/PBR_v63_brainpad/';

subjlist = {'10537','10534','10530','10529','10522','14209','P0870','12191','P0054','P0180'};
maxScale = 1;

% string templates
segInRaw = 'stroke61-seg-in-%s-raw_via_%s-2-stroke61-warp_via-scale%d.nii.gz';
diceAtScale = 'ven-dice-in-raw_via_%s-2-stroke61-warp_via-scale%d.nii.gz';

dices = [];
for i = 1:numel(subjlist)
    subj = subjlist{i};
    
    % get manual segmentation
    truesegFile = fullfile(origPath, subj, [subj, '_proc_ds7_ven_seg.nii.gz']);
    trueseg = nii2vol(truesegFile); % get volume not nii structure
    
    % go through different settings and get automatic segmentation
    d = sys.fulldir(fullfile(runPath, [subj, '*']));
    for si = 1:numel(d)
        % load auto seg file
        localname = sprintf(segInRaw, subj, subj, maxScale);
        autoSegFile = fullfile(d(si).name, 'final', localname);
        autoseg = nii2vol(autoSegFile);
        
        % dice
        autosegVenMap = ismember(autoseg, [4, 43]);
        dce = dice(trueseg(:), autosegVenMap(:), 1);
        dices(i, si) = dce;
        
        % save dice
        diceFileName = sprintf(diceAtScale, subj, maxScale);
        save(diceFileName, 'dce');
        
        % some output, especially so that Andreea can understand it.
        parts = strsplit(d(si).name, '/');
        fprintf('done %25s. Dice: %3.2f\n', parts{end}, dce)        
    end
end
    