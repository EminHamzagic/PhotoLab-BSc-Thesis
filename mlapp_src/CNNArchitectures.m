classdef CNNArchitectures < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        CNNArchitecturesUIFigure   matlab.ui.Figure
        HintLabel                  matlab.ui.control.Label
        IzaberiButton              matlab.ui.control.Button
        DetaljiLabel               matlab.ui.control.Label
        IzaberitearhitekturuLabel  matlab.ui.control.Label
        ArchitectureDetails        matlab.ui.control.TextArea
        UITable                    matlab.ui.control.Table
    end


    properties (Access = public)
        ArchitecturesData  % struct array, one element per architecture
        choosenArch
        ParentApp
    end

    methods (Access = private)

        function data = getArchitecturesData(~)
            % Name must match the case labels in TrainingCNN.getLayers
            data = struct( ...
                'Name', {'LeNet', 'AlexNet', 'ResNet-18', 'MobileNet-v2', 'SqueezeNet'}, ...
                'Layers', {7, 8, 18, 53, 18}, ...
                'InputSize', {'Veličina dataseta (npr. 28x28x1)', 'Veličina dataseta (npr. 32x32x3)', ...
                              '224x224x3 (automatski)', '224x224x3 (automatski)', '227x227x3 (automatski)'}, ...
                'Pretrained', {false, false, true, true, true}, ...
                'Datasets', {'MNIST, Fashion-MNIST', 'CIFAR-10, CIFAR-100, (Fashion-)MNIST', ...
                             'Svi', 'Svi', 'Svi'}, ...
                'Description', {'Klasična mreža za prepoznavanje cifara', ...
                                'AlexNet prilagođen malim slikama (CIFAR)', ...
                                'Rezidualna mreža, najplića ResNet varijanta', ...
                                'Lagana mreža sa depthwise separable konvolucijama', ...
                                'Kompaktna mreža sa fire modulima (~1.2M parametara)'}, ...
                'Details', { ...
                    ['Struktura:' newline '- 2x Conv (5x5) + BatchNorm + ReLU' newline ...
                     '- Average pooling (2x2)' newline '- FC 120 -> FC 84 -> FC (broj klasa)'], ...
                    ['Struktura:' newline '- 5x Conv (5x5, 3x3) + BatchNorm + ReLU' newline ...
                     '- Max pooling nakon 1., 2. i 5. konvolucije' newline ...
                     '- FC 1024 -> FC 512 -> FC (broj klasa), dropout 0.5' newline ...
                     '- Za ulaze veće od 64x64 prvi sloj koristi veći stride'], ...
                    ['Struktura:' newline '- 8 rezidualnih blokova (2x Conv 3x3)' newline ...
                     '- Skip konekcije' newline '- Global average pooling + FC' newline ...
                     'Posljednji FC sloj (fc1000) se zamjenjuje novim.'], ...
                    ['Struktura:' newline '- Inverted residual blokovi' newline ...
                     '- Depthwise separable konvolucije' newline '- Linear bottleneck slojevi' newline ...
                     'Posljednji FC sloj (Logits) se zamjenjuje novim.'], ...
                    ['Struktura:' newline '- Fire moduli (squeeze 1x1 + expand 1x1/3x3)' newline ...
                     '- Bez velikih FC slojeva' newline ...
                     'Klasifikator conv10 (1x1 konvolucija) se zamjenjuje novim.']}, ...
                'WhyForSmallImages', { ...
                    'Dizajnirana upravo za 28x28 slike cifara; brza bazna linija koja se trenira na CPU.', ...
                    'Dovoljan kapacitet za 32x32x3 slike u boji, a i dalje se trenira od nule na CPU.', ...
                    'Skip konekcije sprječavaju degradaciju; najjeftinija ResNet mreža za transfer learning.', ...
                    'Vrlo mali broj operacija (FLOPs); efikasan transfer learning i na slabijem hardveru.', ...
                    'Najmanja pretrenirana mreža; najbrža opcija za transfer learning.'});
        end

        function showDetails(app, idx)
            arch = app.ArchitecturesData(idx);
            if arch.Pretrained
                modeText = 'Transfer learning (pretrenirana na ImageNet)';
            else
                modeText = 'Treniranje od nule';
            end
            details = [ ...
                arch.Name + ""; ...
                sprintf("Slojevi: %d", arch.Layers); ...
                "Ulaz: " + arch.InputSize; ...
                "Režim: " + modeText; ...
                "Dataset-ovi: " + arch.Datasets; ...
                ""; ...
                splitlines(string(arch.Details)); ...
                ""; ...
                "Zašto za male slike:"; ...
                string(arch.WhyForSmallImages)];
            app.ArchitectureDetails.Value = details;
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.CNNArchitecturesUIFigure, 'center');
            app.ArchitecturesData = getArchitecturesData(app);
            data = app.ArchitecturesData;

            modes = repmat({'Od nule'}, 1, numel(data));
            modes([data.Pretrained]) = {'Transfer learning'};
            datasetsAndMode = strcat({data.Datasets}, {' / '}, modes);

            app.UITable.ColumnName = {'Arhitektura', 'Slojevi', 'Opis', 'Dataset-ovi / režim'};
            app.UITable.Data = [{data.Name}', {data.Layers}', {data.Description}', datasetsAndMode'];
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            indices = event.Indices;
            if isempty(indices)
                return;
            end
            % Always take the architecture name from column 1, whichever cell was clicked
            row = indices(1, 1);
            app.choosenArch = app.UITable.Data{row, 1};
            showDetails(app, row);
        end

        % Button pushed function: IzaberiButton
        function IzaberiButtonPushed(app, event)
            if isempty(app.choosenArch)
                uialert(app.CNNArchitecturesUIFigure, 'Morate izabrati arhitekturu prvo!', 'Warning');
                return;
            end
            uiresume(app.CNNArchitecturesUIFigure);
        end

        % Close request function: CNNArchitecturesUIFigure
        function CNNArchitecturesUIFigureCloseRequest(app, event)
            uiresume(app.CNNArchitecturesUIFigure);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create CNNArchitecturesUIFigure and hide until all components are created
            app.CNNArchitecturesUIFigure = uifigure('Visible', 'off');
            app.CNNArchitecturesUIFigure.Position = [100 100 900 620];
            app.CNNArchitecturesUIFigure.Name = 'CNN Architectures';
            app.CNNArchitecturesUIFigure.CloseRequestFcn = createCallbackFcn(app, @CNNArchitecturesUIFigureCloseRequest, true);

            % Create IzaberitearhitekturuLabel
            app.IzaberitearhitekturuLabel = uilabel(app.CNNArchitecturesUIFigure);
            app.IzaberitearhitekturuLabel.FontSize = 22;
            app.IzaberitearhitekturuLabel.FontWeight = 'bold';
            app.IzaberitearhitekturuLabel.Position = [24 564 500 32];
            app.IzaberitearhitekturuLabel.Text = 'Izaberite arhitekturu';

            % Create HintLabel
            app.HintLabel = uilabel(app.CNNArchitecturesUIFigure);
            app.HintLabel.FontSize = 12;
            app.HintLabel.Position = [24 536 500 22];
            app.HintLabel.Text = 'Kliknite red u tabeli za detalje, zatim potvrdite sa "Izaberi".';

            % Create IzaberiButton
            app.IzaberiButton = uibutton(app.CNNArchitecturesUIFigure, 'push');
            app.IzaberiButton.ButtonPushedFcn = createCallbackFcn(app, @IzaberiButtonPushed, true);
            app.IzaberiButton.BackgroundColor = [0.20 0.45 0.75];
            app.IzaberiButton.FontColor = [1 1 1];
            app.IzaberiButton.FontSize = 13;
            app.IzaberiButton.FontWeight = 'bold';
            app.IzaberiButton.Position = [676 552 200 44];
            app.IzaberiButton.Text = 'Izaberi';

            % Create UITable
            app.UITable = uitable(app.CNNArchitecturesUIFigure);
            app.UITable.ColumnName = {'Arhitektura'; 'Slojevi'; 'Opis'; 'Dataset-ovi / režim'};
            app.UITable.ColumnWidth = {100, 60, 'auto', 'auto'};
            app.UITable.RowName = {};
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.FontSize = 12;
            app.UITable.Position = [24 24 520 480];

            % Create DetaljiLabel
            app.DetaljiLabel = uilabel(app.CNNArchitecturesUIFigure);
            app.DetaljiLabel.FontSize = 14;
            app.DetaljiLabel.FontWeight = 'bold';
            app.DetaljiLabel.Position = [560 480 316 22];
            app.DetaljiLabel.Text = 'Detalji';

            % Create ArchitectureDetails
            app.ArchitectureDetails = uitextarea(app.CNNArchitecturesUIFigure);
            app.ArchitectureDetails.Editable = 'off';
            app.ArchitectureDetails.FontSize = 12;
            app.ArchitectureDetails.Position = [560 24 316 444];

            % Show the figure after all components are created
            app.CNNArchitecturesUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CNNArchitectures

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.CNNArchitecturesUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.CNNArchitecturesUIFigure)
        end
    end
end
