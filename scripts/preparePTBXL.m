function preparePTBXL(outputDir, h)
    if nargin < 2, h = []; end
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    ptbDir = fullfile(outputDir, 'ptbxl');
    if ~exist(ptbDir, 'dir')
        mkdir(ptbDir);
    end

    url = 'https://physionet.org/static/published-projects/ptb-xl/ptb-xl-1.0.3.zip';
    zipFile = fullfile(outputDir, 'ptbxl.zip');
    
    % Step 1: Download
    if ~isfile(zipFile)
        if ~isempty(h), waitbar(0.1, h, 'Downloading PTB-XL (this may take a while)...'); end
        options = weboptions('Timeout', 1200); % 20 minutes timeout
        websave(zipFile, url, options);
    end
    
    % Step 2: Extract
    if ~isempty(h), waitbar(0.6, h, 'Extracting PTB-XL...'); end
    unzip(zipFile, outputDir);
    delete(zipFile);

    % Step 3: Organize (flatten nested folder structure if present)
    if ~isempty(h), waitbar(0.8, h, 'Organizing dataset...'); end
    files = dir(fullfile(ptbDir, '**', '*'));
    for k = 1:length(files)
        if ~files(k).isdir
            src = fullfile(files(k).folder, files(k).name);
            dst = fullfile(ptbDir, files(k).name);
            if ~strcmp(src, dst) % only move if needed
                movefile(src, dst, 'f');
            end
        end
    end

    % Remove nested empty folders
    folders = dir(ptbDir);
    for k = length(folders):-1:1
        if folders(k).isdir && ~ismember(folders(k).name, {'.', '..'})
            try
                rmdir(fullfile(ptbDir, folders(k).name), 's');
            end
        end
    end

    if ~isempty(h), waitbar(1, h, 'PTB-XL dataset ready!'); end
end
