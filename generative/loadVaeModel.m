function model = loadVaeModel(fileName)
% loadVaeModel Load and validate a VAE model saved by trainGenerativeModel
%   Throws errors with Serbian messages when the file is not a supported VAE.

    try
        data = load(fileName);
    catch ME
        error('PhotoLab:vaeLoad', 'Fajl nije moguće učitati: %s', ME.message);
    end

    if ~isfield(data, 'modelType')
        error('PhotoLab:vaeInvalid', 'Fajl nije generativni model (nema polje modelType).');
    end
    if ~(ischar(data.modelType) || isstring(data.modelType)) || ~strcmp(string(data.modelType), "VAE")
        error('PhotoLab:vaeUnsupported', ...
            'Model tipa "%s" nije podržan. Podržan je samo VAE.', string(data.modelType));
    end

    required = {'encoder', 'decoder', 'latentDim', 'imageSize', 'channels', 'outputRange', 'datasetName'};
    missing = required(~isfield(data, required));
    if ~isempty(missing)
        error('PhotoLab:vaeInvalid', 'Fajl nije validan VAE model. Nedostaju polja: %s.', strjoin(missing, ', '));
    end
    if ~isa(data.encoder, 'dlnetwork') || ~isa(data.decoder, 'dlnetwork')
        error('PhotoLab:vaeInvalid', 'Fajl nije validan VAE model. encoder i decoder moraju biti dlnetwork.');
    end
    if ~isscalar(data.latentDim) || ~isnumeric(data.latentDim) || data.latentDim < 1
        error('PhotoLab:vaeInvalid', 'Fajl nije validan VAE model. latentDim mora biti pozitivan broj.');
    end
    if ~isequal(data.decoder.Layers(1).InputSize, [1 1 data.latentDim])
        error('PhotoLab:vaeInvalid', 'Fajl nije validan VAE model. Dekoder ne odgovara polju latentDim.');
    end

    model = data;
end
