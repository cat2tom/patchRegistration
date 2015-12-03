function [sourceWarped, displ, sourceSegmWarped] = example_segmentationWarp3D(exid)

    % parameters
    patchSize = [1, 1, 1] * 3;
    patchOverlap = [0, 0, 0] + 1;
    nScales = 4;
    nInnerReps = 4;
    warning off backtrace; % turn off backtrace for warnings.
    
    % setup buckner path based on username
    [~, whoami] = system('whoami');
    spl = strsplit(whoami, '\');
    usrname = spl{end}; 
    if strncmp(usrname, 'abobu', 5)
        BUCKNER_PATH = '/afs/csail.mit.edu/u/a/abobu/toolbox/buckner/';
    else
        BUCKNER_PATH = 'D:\Dropbox (MIT)\Public\robert\buckner';
    end
    
    W = 64;
    H = 64;
    D = 64;
    source = zeros(W, H, D);
    if exid == 1
         % Real example
         niiSource = loadNii(fullfile(BUCKNER_PATH, 'buckner02_brain_affinereg_to_b61.nii.gz'));
         source = padarray(volresize(double(niiSource.img)/255, [W, H, D]), patchSize, 'both');
         niiTarget = loadNii(fullfile(BUCKNER_PATH, 'buckner03_brain_affinereg_to_b61.nii.gz'));
         target = padarray(volresize(double(niiTarget.img)/255, [W, H, D]), patchSize, 'both');
         
         % Segmentation example
         niiSegmSource = loadNii(fullfile(BUCKNER_PATH, 'buckner02_brain_affinereg_to_b61_seg.nii.gz'));
         sourceSegm = padarray(volresize(double(niiSegmSource.img)/255, [W, H, D], 'nearest'), patchSize, 'both');
         niiSegmTarget = loadNii(fullfile(BUCKNER_PATH, 'buckner03_brain_affinereg_to_b61_seg.nii.gz'));
         targetSegm = padarray(volresize(double(niiSegmTarget.img)/255, [W, H, D], 'nearest'), patchSize, 'both');
    end   
    
    % do multi scale registration
    [sourceWarped, displ] = ...
        patchreg.multiscale(source, target, patchSize, patchOverlap, nScales, nInnerReps);
    
    % use displ on initial segmentation and compare with target
    % segmentation
    sourceSegmWarped = volwarp(sourceSegm, displ, 'interpmethod', 'nearest');
    % display results
    if ndims(source) == 2 %#ok<ISMAT>
        patchview.figure();
        drawWarpedImages(source, target, sourceWarped, displ); 
    elseif ndims(source) == 3
        view3Dopt(source, target, sourceWarped, sourceSegm, targetSegm, sourceSegmWarped);
    end
    