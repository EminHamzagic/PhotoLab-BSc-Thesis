function [datasetPath, datasetName] = resolveDatasetPath(datasetPath)
% resolveDatasetPath Descend one level through a single wrapper folder
%   If the folder has no training/ + testing/ pair but exactly one subfolder,
%   that subfolder is the real dataset root. datasetName is its folder name.

    datasetPath = char(datasetPath);
    subDirs = dir(datasetPath);
    subDirs = subDirs([subDirs.isdir] & ~startsWith({subDirs.name}, '.'));
    hasTrain = any(strcmpi({subDirs.name}, 'training'));
    hasTest  = any(strcmpi({subDirs.name}, 'testing'));
    if ~(hasTrain && hasTest) && numel(subDirs) == 1
        datasetPath = fullfile(datasetPath, subDirs(1).name);
    end
    [~, datasetName] = fileparts(datasetPath);
end
