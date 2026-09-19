function writeDatasetManifest(outputDir, datasetName, imageSize, channels)
% writeDatasetManifest Write photolab_dataset.mat describing a prepared dataset
%   The manifest lets TrainingCNN and ImageClassificationApp read the image
%   size, channel count and class order instead of re-deriving them.
%
%   imageSize - [H W] of the images as written to disk
%   channels  - 1 (grayscale) or 3 (RGB)
%
% Class names are taken from the training/ subfolder names, sorted the same
% way imageDatastore(..., 'LabelSource', 'foldernames') sorts them, so the
% order matches categories(imds.Labels).

    trainDir = fullfile(outputDir, 'training');
    entries = dir(trainDir);
    entries = entries([entries.isdir] & ~startsWith({entries.name}, '.'));
    classNames = sort(string({entries.name}));

    imageSize = imageSize(1:2);
    createdAt = datetime('now');

    save(fullfile(outputDir, 'photolab_dataset.mat'), ...
        'imageSize', 'channels', 'classNames', 'datasetName', 'createdAt');
end
