function [sourceWarped, displ] = register(paths, params, opts, varargin)
% patch-based discrete registration
% TODO: use cubic interpolation? see if there is a difference?

    %% Prepare run
    % prepare source
    niiSource = loadNii(paths.sourceFile);
    szRatio = max(size(niiSource.img)) ./ opts.maxVolSize;
    newSrcSize = round(size(niiSource.img) ./ szRatio);
    source = padarray(volresize(double(niiSource.img), newSrcSize), params.volPad, 'both');
    
    % prepare target
    niiTarget = loadNii(paths.targetFile);
    szRatio = max(size(niiTarget.img)) ./ opts.maxVolSize;
    newTarSize = round(size(niiTarget.img) ./ szRatio);
    target = padarray(volresize(double(niiTarget.img), newTarSize), params.volPad, 'both');
    
    %% Patch Registration
    % do multi scale registration
    displ = patchreg.multiscale(source, target, params, opts, varargin{:});
    
    % compose the final image using the resulting displacements
    sourceWarped = volwarp(source, displ, opts.warpDir);
    
    %% save final displacement and original volumes
    if isfield(opts, 'savefile') && ~isempty(opts.savefile)
        volumes.source = source;
        volumes.sourceWarped = sourceWarped;
        volumes.target = target; %#ok<STRNU>
        save(sprintf(opts.savefile, 0, 0), 'volumes', 'displ', 'params', 'opts', 'paths');
    end
    
    %% Immediate Output Visualization
    % TODO: take this out and put it in a separate visualization function
    if opts.verbose > 0
        % This is just some quick visualization. Analysis should be done separately
        displvols = {source, target, sourceWarped}; % volumes to display
        
        if opts.verbose > 1 % only computer targetWarped if you're willing to wait a while
            oppdirn = ifelse(strcmp(opts.warpDir, 'backward'), 'forward', 'backward');
            targetWarped = volwarp(target, displ,  oppdirn);
            displvols = [displvols, targetWarped];
        end

        % TODO: try to do quilt instead of warp. Soemthing like:
        % [~, ~, srcgridsize] = patchlib.grid(size(source), patchSize, patchOverlap);
        % alternativeWarped = patchlib.quilt(qp, srcgridsize, patchSize, patchOverlap); 

        % display results
        if ndims(source) == 2 %#ok<ISMAT>
            patchview.figure();
            drawWarpedImages(source, target, sourceWarped, displ); 

        elseif ndims(source) == 3
            % prepare segmentations
            segvols = {};
            if isfield(paths, 'sourceSegFile') && isfield(paths, 'targetSegFile')
                sourceSegmWarped = volwarp(sourceSeg, displ, opts.warpDir, 'interpmethod', 'nearest');
                segvols = {sourceSeg, targetSeg, sourceSegmWarped};
            end

            % visualize
            view3Dopt(displvols{:}, segvols{:}, displ{:});
        end
    end
end
