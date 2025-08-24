function prepareStreetScene(outputDir, h)
    if nargin < 2, h = []; end
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    url = 'https://zenodo.org/record/10870472/files/StreetScene.zip?download=1';
    zipFile = fullfile(outputDir, 'StreetScene.zip');

    % Step 1: Download
    if ~isfile(zipFile)
        if ~isempty(h), waitbar(0.1, h, 'Downloading Street Scene dataset...'); end
        websave(zipFile, url);
    end

    % Step 2: Extract
    if ~isempty(h), waitbar(0.3, h, 'Extracting dataset...'); end
    unzip(zipFile, outputDir);
    delete(zipFile);

    % Step 3: Organize
    srcDir = fullfile(outputDir, 'StreetScene');
    tgtTrain = fullfile(outputDir, 'training');
    tgtTest  = fullfile(outputDir, 'testing');

    if exist(srcDir, 'dir')
        if ~isempty(h), waitbar(0.6, h, 'Organizing data folders...'); end
        movefile(fullfile(srcDir, 'Train'), tgtTrain);
        movefile(fullfile(srcDir, 'Test'), tgtTest);
        readme = fullfile(srcDir, 'README.md');
        if isfile(readme)
            movefile(readme, outputDir);
        end
        rmdir(srcDir, 's'); % clean up
    else
        warning('Expected StreetScene folder not found after unzipping.');
    end

    if ~isempty(h), waitbar(1, h, 'Street Scene ready!'); end
end
