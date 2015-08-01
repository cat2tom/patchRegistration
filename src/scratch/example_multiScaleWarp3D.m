function [sourceWarped, displ] = example_multiScaleWarp3D(exid)

    % parameters
    patchSize = [1, 1, 1] * 3;
    patchOverlap = [0, 0, 0] + 1;
    nScales = 7;
    nInnerReps = 3;
    warning off backtrace; % turn off backtrace for warnings.
    
    % setup buckner path based on username
    [~, whoami] = system('whoami');
    spl = strsplit(whoami, '\');
    usrname = spl{end}; 
    if strcmp(usrname, 'abobu')
        BUCKNER_PATH = '/afs/csail.mit.edu/u/a/abobu/toolbox/buckner/';
    else
        BUCKNER_PATH = 'D:\Dropbox (MIT)\Public\robert\buckner';
    end
    
    W = 32;
    H = 32;
    D = 32;
    source = zeros(W, H, D);
    if exid == 1
         % Real example
         niiSource = loadNii(fullfile(BUCKNER_PATH, 'buckner02_brain_affinereg_to_b61.nii.gz'));
         source = padarray(volresize(double(niiSource.img)/255, [W, H, D]), patchSize, 'both');
         niiTarget = loadNii(fullfile(BUCKNER_PATH, 'buckner03_brain_affinereg_to_b61.nii.gz'));
         target = padarray(volresize(double(niiTarget.img)/255, [W, H, D]), patchSize, 'both');
    end   
    
    % do multi scale registration
    [sourceWarped, displ] = ...
        patchreg.multiscale(source, target, patchSize, patchOverlap, nScales, nInnerReps);
    
    % display results
    if ndims(source) == 2 %#ok<ISMAT>
        patchview.figure();
        drawWarpedImages(source, target, sourceWarped, displ); 
    elseif ndims(source) == 3
        view3Dopt(source, target, sourceWarped, displ{:});
    end
    