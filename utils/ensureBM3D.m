function ok = ensureBM3D()
% ENSUREBM3D  Makes sure the (legacy Tampere) BM3D library is on the MATLAB path.
%   ok = ensureBM3D() returns true if BM3D.m can be called. If it is not on the
%   path, a few likely folders are tried; if none contain BM3D.m the user is asked
%   to pick the folder once. A found folder is added with addpath + savepath.

    if exist('BM3D', 'file') == 2
        ok = true;
        return;
    end

    home = getenv('USERPROFILE');
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    candidates = { ...
        fullfile(home, 'OneDrive', 'Desktop', 'BM3D'), ...
        fullfile(home, 'Desktop', 'BM3D'), ...
        fullfile(repoRoot, 'BM3D'), ...
        fullfile(repoRoot, '..', 'BM3D')};

    for k = 1:numel(candidates)
        if isfile(fullfile(candidates{k}, 'BM3D.m'))
            ok = addLibrary(candidates{k});
            return;
        end
    end

    folder = uigetdir(pwd, 'Izaberite folder u kojem se nalazi BM3D biblioteka (BM3D.m)');
    if ~isequal(folder, 0) && isfile(fullfile(folder, 'BM3D.m'))
        ok = addLibrary(folder);
    else
        ok = false;
    end
end

function ok = addLibrary(folder)
    addpath(folder);
    try
        savepath;
    catch
        % savepath can fail without write access to pathdef.m; the path is
        % still valid for this session.
    end
    ok = exist('BM3D', 'file') == 2;
end
