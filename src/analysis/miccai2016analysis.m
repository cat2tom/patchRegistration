%% Analyse and prepare data for the MICCAI 2016 submission of patch-based registration
% assumes data organization:
% /outpath/datatype/runname/subjid_param1_param2_.../
%   /final/datatype61-seg-in-%s-raw_via_%s-2-datatype61-invWarp.nii.gz
%   /final/datatype61-seg-in-%s_via_%s-2-datatype61-invWarp.nii.gz
%   /out/stats.amt
% /inpath/datatype/proc/brain_pad10/subjid/
%
% where datatype is buckner or stroke, runname is something like PBR_v5

%% setup paths
INPUT = '/data/vision/polina/scratch/patchRegistration/inputs/';
bucknerinpath = [INPUT, 'buckner/proc/brain_pad10/'];
strokeinpath = [INPUT, 'stroke/proc/brain_pad10/'];

OUTPATH = '/data/vision/polina/scratch/patchRegistration/output/';
bppath = [OUTPATH, 'buckner/sparse_ds7_pad10_lambdaedge_gridspacing_innerreps/'];
bapath = [OUTPATH, 'buckner/ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam/'];
sppath = [OUTPATH, 'stroke/PBR_v5'];
sapath = [OUTPATH, 'stroke/ANTs_v2_raw_fromDs7us7Reg_continueAffine']; %ANTs_v3_raw_fromDs7us7Reg_continueAffine_multiparam

buckneroutpaths = {bppath, bapath};
strokeoutpaths = {sppath, sapath};
bucknerpathnames = {'buckner-PBR', 'buckner-ANTs'};
strokepathnames = {'stroke-PBR', 'stroke-ANTs'};

segInRawFiletpl = '%s61-seg-in-%s-raw_via_%s-2-%s61-invWarp.nii.gz';
rawSubjFiletpl = '%s_proc_ds7.nii.gz';

segInSubjFiletpl = '%s61-seg-in-%s_via_%s-2-%s61-invWarp.nii.gz';
subjFiletpl = '%s_proc_ds7_ds7_reg.nii.gz';

%% settings
bucknerSelSubj = 'buckner03';
strokeSelSubj = '10534'; % 10530
nTrainSubj = 10;

desiredDiceLabels = [2, 3, 4, 17, 41, 42, 43, 53];
dicenames = {'LWM', 'LC', 'LV', 'LH', 'RWM', 'RC', 'RV', 'RH'};
dice4OverallPlots = cell(1, numel(desiredDiceLabels));

%% buckner analysis
for pi = 1:numel(buckneroutpaths)
    respath = buckneroutpaths{pi};
    
    % gather Dice parameters 
    [params, dices, dicelabels, subjNames, folders] = gatherDiceStats(respath, desiredDiceLabels, 1);
    nParams = size(params, 2);
    
    % select entries that belong to the first nTrainSubj subjects
    trainidx = params(:, 1) < nTrainSubj;
    testidx = ~trainidx;

    % get optimal parameters for training subjects
    [optParams, optDices] = optimalDiceParams(params(trainidx, 2:end), dices(trainidx, :), true);

    % select testing subjects dice values for those parameters.
    optsel = testidx & all(bsxfun(@eq, params(:, 2:end), optParams), 2);
    
    % some Dice plotting
    % plotMultiParameterDICE(params(trainidx, :), dices(trainidx, :), dicelabels, diceLabelNames, paramNames);
    % figure(); boxplot(dices(optsel, :)); hold on; grid on;
    % xlabel('Structure'); ylabel('DICE'); title(bucknerpathnames{pi});
    
    % prepare Dice of rest of subjects given top parameters
    for i = 1:numel(dice4OverallPlots)
        dice4OverallPlots{i} = [dice4OverallPlots{i}, dices(optsel, i)];
    end
    
    % show some example slices of outlines 
    % axial slices
    subjnr = find(strcmp(subjNames, bucknerSelSubj));
    showSel = find(all(bsxfun(@eq, params, [subjnr, optParams]), 2));
    assert(numel(showSel) == 1, 'did not find the folder to show');
    % extract volumes
    vol = nii2vol(fullfile(bucknerinpath, bucknerSelSubj, sprintf(rawSubjFiletpl, bucknerSelSubj)));
    selfname = sprintf(segInRawFiletpl, 'buckner', bucknerSelSubj, bucknerSelSubj, 'buckner');
    seg = nii2vol(fullfile(respath, folders{showSel}, 'final', selfname));
    seg(~ismember(seg, desiredDiceLabels)) = 0;
    hs = showVolStructures2D(vol, seg, {'axial', 'saggital'});
    figure(hs{1}); title(bucknerpathnames{pi});
    figure(hs{2}); title(bucknerpathnames{pi});
end

% joint dice plotting
boxplotALMM(dice4OverallPlots, dicenames); grid on;
ylabel('DICE', 'FontSize', 28);
legend(bucknerpathnames(1:2));

%% stroke analysis 
meanin = nan(numel(folders), 2);
meanout = nan(numel(folders), 2);
for pi = 1:numel(strokeoutpaths)
    % get stroke folders
    [params, subjNames, folders] = gatherRunParams(strokeoutpaths{pi});
    
    % go through existing folders
    for i = 1:numel(folders)
        subjName = subjNames{params(i, 1)};
        volfile = fullfile(strokeinpath, subjName, sprintf(rawSubjFiletpl, subjName));
        selfname = sprintf(segInRawFiletpl, 'stroke', subjName, subjName, 'stroke');
        segfile = fullfile(strokeoutpaths{pi}, folders{i}, 'final', selfname);
        
        if ~sys.isfile(volfile)
            fprintf(2, 'Skipping %s due to missing %s\n', folders{i}, volfile);
            continue;
        end
        
        if ~sys.isfile(segfile)
            fprintf(2, 'Skipping %s due to missing %s\n', folders{i}, segfile);
            continue;
        end
        
        volnii = loadNii(volfile);
        segnii = loadNii(segfile);
        
        [meanin(i, pi), meanout(i, pi)] = inoutStats(volnii, 3, segnii, desiredDiceLabels(3), true);
    end
    
    % show optimal based on meanout - meanin
    subjnr = find(strcmp(subjNames, strokeSelSubj));
    [optParams, optDiffs] = optimalDiceParams(params(:, 2:end), meanout - meanin, true);
    showSel = find(all(bsxfun(@eq, params, [subjnr, optParams]), 2));
    % get volumes
    vol = nii2vol(fullfile(strokeinpath, strokeSelSubj, sprintf(rawSubjFiletpl, strokeSelSubj)));
    selfname = sprintf(segInRawFiletpl, 'stroke', strokeSelSubj, strokeSelSubj, 'stroke');
    seg = nii2vol(fullfile(strokeoutpaths{pi}, folders{showSel}, 'final', selfname));
    % get and show axial images
    hs = showVolStructures2D(vol, seg, {'axial', 'saggital'});
    figure(hs{1}); title(strokeoutpaths{pi});
    figure(hs{2}); title(strokeoutpaths{pi});
end

figure(); plot(meanout - meanin, '.'); title('Mean intensity diff around ventricles');
legend(strokepathnames);
xlabel('run/subject');
ylabel('out - in intensity diff');

