function mlappFromSource(srcFile, targetFile)
% mlappFromSource Rebuild an .mlapp (design model + code) from App Designer-style classdef source
%   Parses the App Designer generated layout of srcFile: component
%   properties, editable sections, callbacks, startupFcn and
%   createComponents. Creates the components and tags them with the same
%   DesignTimeProperties App Designer uses, then saves them with App
%   Designer's own MLAPPSerializer. App Designer then opens the new UI.

    codeText = fileread(srcFile);
    codeText = strrep(codeText, sprintf('\r\n'), newline);
    lines = splitlines(string(codeText));
    lines = lines(:)';

    className = regexp(lines(1), '^classdef\s+(\w+)', 'tokens', 'once');
    className = char(className);

    %% Section boundaries
    cbStart   = find(contains(lines, '% Callbacks that handle component events'), 1);
    compInit  = find(contains(lines, '% Component initialization'), 1);
    propsEnd  = find(strcmp(strtrim(lines), 'end'), 1);         % end of component properties block
    assert(~isempty(cbStart) && ~isempty(compInit), 'Unexpected layout in %s', srcFile);

    % Editable section: everything between the component properties block and the callbacks
    editable = lines(propsEnd+1:cbStart-1);
    editable = trimBlank(editable);

    %% Callbacks (+ startupFcn)
    callbacks = struct('Name', {}, 'Code', {});
    startup = [];
    i = cbStart;
    while i < compInit
        tok = regexp(lines(i), '^        function\s+(\w+)\s*\(', 'tokens', 'once');
        if ~isempty(tok)
            name = char(tok);
            j = i + 1;
            while ~strcmp(lines(j), "        end")
                j = j + 1;
            end
            body = cellstr(lines(i+1:j-1));
            if strcmp(name, 'startupFcn')
                startup = struct('Name', name, 'Code', {body'});
            else
                callbacks(end+1) = struct('Name', name, 'Code', {body'}); %#ok<AGROW>
            end
            i = j;
        end
        i = i + 1;
    end

    %% createComponents
    ccStart = find(contains(lines, 'function createComponents(app)'), 1);
    ccEnd = ccStart + 1;
    while ~strcmp(lines(ccEnd), "        end")
        ccEnd = ccEnd + 1;
    end
    body = strtrim(lines(ccStart+1:ccEnd-1));
    % join continuation lines
    stmts = strings(0);
    buf = "";
    for k = 1:numel(body)
        ln = body(k);
        if ln == "" || startsWith(ln, "%"), continue; end
        if endsWith(ln, "...")
            buf = buf + extractBefore(ln, strlength(ln) - 2) + " ";
        else
            stmts(end+1) = buf + ln; %#ok<AGROW>
            buf = "";
        end
    end

    app = struct();
    codeNames = strings(0);
    compCode = containers.Map();
    figName = "";
    for k = 1:numel(stmts)
        s = stmts(k);
        % createCallbackFcn(app, @Fn, true) -> 'Fn' (App Designer stores callback names)
        s = regexprep(s, 'createCallbackFcn\(app,\s*@(\w+),\s*true\)', '''$1''');
        ctor = regexp(s, '^app\.(\w+)\s*=\s*(\w+)\((.*)\);$', 'tokens', 'once');
        if ~isempty(ctor)
            name = ctor(1);
            codeNames(end+1) = name; %#ok<AGROW>
            parent = regexp(ctor(3), '^app\.(\w+)', 'tokens', 'once');
            if isempty(parent)
                figName = name;
                genLine = regexprep(s, '^app\.\w+', 'app.ad_CODENAME_ad');
            else
                genLine = regexprep(s, '^app\.\w+', 'app.ad_CODENAME_ad');
                genLine = regexprep(genLine, ['\(app\.' char(parent) '\>'], '(app.ad_PARENTCODENAME_ad');
            end
            compCode(char(name)) = {char(genLine)};
            eval(char(s));
            continue;
        end
        prop = regexp(s, '^app\.(\w+)\.', 'tokens', 'once');
        assert(~isempty(prop), 'Unrecognised statement in createComponents: %s', s);
        name = prop(1);
        if name == figName && startsWith(s, "app." + figName + ".Visible")
            continue;   % App Designer adds the final Visible = 'on' itself
        end
        genLine = regexprep(s, ['^app\.' char(name) '\>'], 'app.ad_CODENAME_ad');
        compCode(char(name)) = [compCode(char(name)), {char(genLine)}];
        eval(char(s));
    end

    % Tag every component the way App Designer does
    for k = 1:numel(codeNames)
        comp = app.(codeNames(k));
        if ~isprop(comp, 'DesignTimeProperties')
            addprop(comp, 'DesignTimeProperties');
        end
        comp.DesignTimeProperties = struct( ...
            'CodeName', char(codeNames(k)), ...
            'GroupId', '', ...
            'ComponentCode', {compCode(char(codeNames(k)))'}, ...
            'ImageRelativePath', '');
    end
    fig = app.(figName);

    %% Metadata: keep the existing app's (uuid, description) when present
    metadata = appdesigner.internal.model.MetadataModel;
    if isfile(targetFile)
        try
            old = appdesigner.internal.serialization.FileReader(targetFile).readAppMetadata();
            for f = fieldnames(old)'
                if isprop(metadata, f{1})
                    try, metadata.(f{1}) = old.(f{1}); catch, end
                end
            end
        catch
        end
    end

    %% Save
    serializer = appdesigner.internal.serialization.MLAPPSerializer(targetFile, fig);
    serializer.ClassName = className;
    serializer.MatlabCodeText = char(strjoin(lines, newline));
    serializer.EditableSectionCode = cellstr(editable);
    serializer.Callbacks = callbacks;
    if ~isempty(startup)
        serializer.StartupCallback = startup;
    end
    serializer.AppTypeData = struct();
    serializer.Metadata = metadata;
    serializer.save();
    delete(fig);
end

function out = trimBlank(in)
    first = find(strtrim(in) ~= "", 1);
    last = find(strtrim(in) ~= "", 1, 'last');
    out = in(first:last);
end
