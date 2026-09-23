classdef Options < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        TitleLabel                      matlab.ui.control.Label
        ImagePanel                      matlab.ui.container.Panel
        OpcijePanel                     matlab.ui.container.Panel
        DodavanjeumairazliitifilteriButton  matlab.ui.control.Button
        HarrisCornerDetectionButton     matlab.ui.control.Button
        FuzijaslikaButton               matlab.ui.control.Button
        PromenaveliineiponovnouzrokovanjeButton  matlab.ui.control.Button
        PrimenaActiveContoursalgoritmaButton  matlab.ui.control.Button
        WienerFilterButton              matlab.ui.control.Button
        RotacijaslikeButton             matlab.ui.control.Button
        PrimenaalgoritmaHistogramEqualizationButton  matlab.ui.control.Button
        KonverzijaslikeucrnobeluButton  matlab.ui.control.Button
        KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButton  matlab.ui.control.Button
        Image                           matlab.ui.control.Image
        UitajslikuButton                matlab.ui.control.Button
        MolimovasprvouitajteslikukojubistedaobraditeLabel  matlab.ui.control.Label
    end

    
    properties (Access = private)
        ImageLoaded = false; % Description
        ImageFile % Description
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            movegui(app.UIFigure, 'center');
        end

        % Button pushed function: UitajslikuButton
        function UitajslikuButtonPushed(app, event)
            [filename, pathname] = uigetfile('*.png;*.jpg;*.jpeg', "Izaberi sliku");

            if isequal(filename, 0)
                figure(app.UIFigure);
                return;
            end

            filename = strcat(pathname, filename);
            app.ImageFile=imread(filename);

            % uiimage traži RGB, pa crno-belu (2D) sliku prikaži replicirano po 3 kanala
            if ismatrix(app.ImageFile)
                app.Image.ImageSource = repmat(app.ImageFile, [1 1 3]);
            else
                app.Image.ImageSource = app.ImageFile;
            end
            app.ImageLoaded = true;

            figure(app.UIFigure);
        end

        % Button pushed function: 
        % KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButton
        function KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButtonPushed(app, event)
            if app.ImageLoaded
                 konverzije = ColorFormatsConversion(); 

                 konverzije.loadImage(app.ImageFile)
            else
                % Show a warning message if no image is loaded
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
            end
        end

        % Button pushed function: KonverzijaslikeucrnobeluButton
        function KonverzijaslikeucrnobeluButtonPushed(app, event)
            if app.ImageLoaded
                 konverzije = GreyScaleConversion(); 

                 konverzije.loadImage(app.ImageFile)
            else
                % Show a warning message if no image is loaded
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
            end
        end

        % Button pushed function: 
        % PrimenaalgoritmaHistogramEqualizationButton
        function PrimenaalgoritmaHistogramEqualizationButtonPushed(app, event)
            if app.ImageLoaded
                konverzije = HistogramEqualization();
                konverzije.loadImage(app.ImageFile);
            else
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
            end
        end

        % Button pushed function: RotacijaslikeButton
        function RotacijaslikeButtonPushed(app, event)
            if app.ImageLoaded
                rotacija = ImageRotation();
                rotacija.loadImage(app.ImageFile);
            else
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
            end
        end

        % Button pushed function: WienerFilterButton
        function WienerFilterButtonPushed(app, event)
             if app.ImageLoaded
                wf = WienerFilter();
                wf.loadImage(app.ImageFile);
            else
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
            end
        end

        % Button pushed function: PrimenaActiveContoursalgoritmaButton
        function PrimenaActiveContoursalgoritmaButtonPushed(app, event)
            if app.ImageLoaded
                konverzije = ActiveContours();
                konverzije.loadImage(app.ImageFile);
            else
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
            end
        end

        % Button pushed function: PromenaveliineiponovnouzrokovanjeButton
        function PromenaveliineiponovnouzrokovanjeButtonPushed(app, event)
            if app.ImageLoaded
                resizingResampling = ResizingResampling();
                resizingResampling.loadImage(app.ImageFile);
            else
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
            end
        end

        % Button pushed function: FuzijaslikaButton
        function FuzijaslikaButtonPushed(app, event)
            imageFusion = ImageFusion();
        end

        % Button pushed function: HarrisCornerDetectionButton
        function HarrisCornerDetectionButtonPushed(app, event)
            if app.ImageLoaded
                hcorner = HarrisCornerDetectionFeature();
                hcorner.loadImage(app.ImageFile);
            else
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
            end
        end

        % Button pushed function: DodavanjeumairazliitifilteriButton
        function DodavanjeumairazliitifilteriButtonPushed(app, event)
            if app.ImageLoaded
                filters = Filters();
                filters.loadImage(app.ImageFile);
            else
                uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 760];
            app.UIFigure.Name = 'Obrada slika';

            % Create TitleLabel
            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Position = [24 704 800 32];
            app.TitleLabel.Text = 'Obrada slika';

            % Create MolimovasprvouitajteslikukojubistedaobraditeLabel
            app.MolimovasprvouitajteslikukojubistedaobraditeLabel = uilabel(app.UIFigure);
            app.MolimovasprvouitajteslikukojubistedaobraditeLabel.FontSize = 13;
            app.MolimovasprvouitajteslikukojubistedaobraditeLabel.WordWrap = 'on';
            app.MolimovasprvouitajteslikukojubistedaobraditeLabel.Position = [24 668 1152 24];
            app.MolimovasprvouitajteslikukojubistedaobraditeLabel.Text = 'Molimo vas prvo učitajte sliku koju bi ste da obradite';

            %% Slika

            % Create ImagePanel
            app.ImagePanel = uipanel(app.UIFigure);
            app.ImagePanel.Title = 'Slika';
            app.ImagePanel.FontSize = 14;
            app.ImagePanel.FontWeight = 'bold';
            app.ImagePanel.Position = [24 280 1152 372];

            % Create UitajslikuButton
            app.UitajslikuButton = uibutton(app.ImagePanel, 'push');
            app.UitajslikuButton.ButtonPushedFcn = createCallbackFcn(app, @UitajslikuButtonPushed, true);
            app.UitajslikuButton.BackgroundColor = [0.20 0.45 0.75];
            app.UitajslikuButton.FontColor = [1 1 1];
            app.UitajslikuButton.FontSize = 13;
            app.UitajslikuButton.FontWeight = 'bold';
            app.UitajslikuButton.Position = [16 290 200 44];
            app.UitajslikuButton.Text = 'Učitaj sliku';

            % Create Image
            app.Image = uiimage(app.ImagePanel);
            app.Image.Position = [240 16 896 320];

            %% Opcije

            % Create OpcijePanel
            app.OpcijePanel = uipanel(app.UIFigure);
            app.OpcijePanel.Title = 'Opcije';
            app.OpcijePanel.FontSize = 14;
            app.OpcijePanel.FontWeight = 'bold';
            app.OpcijePanel.Position = [24 24 1152 240];

            % Create KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButton
            app.KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButton = uibutton(app.OpcijePanel, 'push');
            app.KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButton.ButtonPushedFcn = createCallbackFcn(app, @KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButtonPushed, true);
            app.KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButton.FontSize = 12;
            app.KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButton.WordWrap = 'on';
            app.KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButton.Position = [16 150 240 48];
            app.KonverzijaslikeurazliiteformateRGBHSVCIELabYCbCrButton.Text = 'Konverzija slike u različite formate (RGB, HSV, CIE Lab, YCbCr)';

            % Create KonverzijaslikeucrnobeluButton
            app.KonverzijaslikeucrnobeluButton = uibutton(app.OpcijePanel, 'push');
            app.KonverzijaslikeucrnobeluButton.ButtonPushedFcn = createCallbackFcn(app, @KonverzijaslikeucrnobeluButtonPushed, true);
            app.KonverzijaslikeucrnobeluButton.FontSize = 12;
            app.KonverzijaslikeucrnobeluButton.WordWrap = 'on';
            app.KonverzijaslikeucrnobeluButton.Position = [272 150 240 48];
            app.KonverzijaslikeucrnobeluButton.Text = 'Konverzija slike u crno-belu';

            % Create PrimenaalgoritmaHistogramEqualizationButton
            app.PrimenaalgoritmaHistogramEqualizationButton = uibutton(app.OpcijePanel, 'push');
            app.PrimenaalgoritmaHistogramEqualizationButton.ButtonPushedFcn = createCallbackFcn(app, @PrimenaalgoritmaHistogramEqualizationButtonPushed, true);
            app.PrimenaalgoritmaHistogramEqualizationButton.FontSize = 12;
            app.PrimenaalgoritmaHistogramEqualizationButton.WordWrap = 'on';
            app.PrimenaalgoritmaHistogramEqualizationButton.Position = [528 150 240 48];
            app.PrimenaalgoritmaHistogramEqualizationButton.Text = 'Primena algoritma Histogram Equalization';

            % Create RotacijaslikeButton
            app.RotacijaslikeButton = uibutton(app.OpcijePanel, 'push');
            app.RotacijaslikeButton.ButtonPushedFcn = createCallbackFcn(app, @RotacijaslikeButtonPushed, true);
            app.RotacijaslikeButton.FontSize = 12;
            app.RotacijaslikeButton.WordWrap = 'on';
            app.RotacijaslikeButton.Position = [784 150 240 48];
            app.RotacijaslikeButton.Text = 'Rotacija slike';

            % Create WienerFilterButton
            app.WienerFilterButton = uibutton(app.OpcijePanel, 'push');
            app.WienerFilterButton.ButtonPushedFcn = createCallbackFcn(app, @WienerFilterButtonPushed, true);
            app.WienerFilterButton.FontSize = 12;
            app.WienerFilterButton.WordWrap = 'on';
            app.WienerFilterButton.Position = [16 90 240 48];
            app.WienerFilterButton.Text = 'Wiener Filter';

            % Create PrimenaActiveContoursalgoritmaButton
            app.PrimenaActiveContoursalgoritmaButton = uibutton(app.OpcijePanel, 'push');
            app.PrimenaActiveContoursalgoritmaButton.ButtonPushedFcn = createCallbackFcn(app, @PrimenaActiveContoursalgoritmaButtonPushed, true);
            app.PrimenaActiveContoursalgoritmaButton.FontSize = 12;
            app.PrimenaActiveContoursalgoritmaButton.WordWrap = 'on';
            app.PrimenaActiveContoursalgoritmaButton.Position = [272 90 240 48];
            app.PrimenaActiveContoursalgoritmaButton.Text = 'Primena Active Contours algoritma';

            % Create PromenaveliineiponovnouzrokovanjeButton
            app.PromenaveliineiponovnouzrokovanjeButton = uibutton(app.OpcijePanel, 'push');
            app.PromenaveliineiponovnouzrokovanjeButton.ButtonPushedFcn = createCallbackFcn(app, @PromenaveliineiponovnouzrokovanjeButtonPushed, true);
            app.PromenaveliineiponovnouzrokovanjeButton.FontSize = 12;
            app.PromenaveliineiponovnouzrokovanjeButton.WordWrap = 'on';
            app.PromenaveliineiponovnouzrokovanjeButton.Position = [528 90 240 48];
            app.PromenaveliineiponovnouzrokovanjeButton.Text = {'Promena veličine'; 'i ponovno uzrokovanje'};

            % Create FuzijaslikaButton
            app.FuzijaslikaButton = uibutton(app.OpcijePanel, 'push');
            app.FuzijaslikaButton.ButtonPushedFcn = createCallbackFcn(app, @FuzijaslikaButtonPushed, true);
            app.FuzijaslikaButton.FontSize = 12;
            app.FuzijaslikaButton.WordWrap = 'on';
            app.FuzijaslikaButton.Position = [784 90 240 48];
            app.FuzijaslikaButton.Text = 'Fuzija slika';

            % Create HarrisCornerDetectionButton
            app.HarrisCornerDetectionButton = uibutton(app.OpcijePanel, 'push');
            app.HarrisCornerDetectionButton.ButtonPushedFcn = createCallbackFcn(app, @HarrisCornerDetectionButtonPushed, true);
            app.HarrisCornerDetectionButton.FontSize = 12;
            app.HarrisCornerDetectionButton.WordWrap = 'on';
            app.HarrisCornerDetectionButton.Position = [16 30 240 48];
            app.HarrisCornerDetectionButton.Text = 'Harris Corner Detection';

            % Create DodavanjeumairazliitifilteriButton
            app.DodavanjeumairazliitifilteriButton = uibutton(app.OpcijePanel, 'push');
            app.DodavanjeumairazliitifilteriButton.ButtonPushedFcn = createCallbackFcn(app, @DodavanjeumairazliitifilteriButtonPushed, true);
            app.DodavanjeumairazliitifilteriButton.FontSize = 12;
            app.DodavanjeumairazliitifilteriButton.WordWrap = 'on';
            app.DodavanjeumairazliitifilteriButton.Position = [272 30 240 48];
            app.DodavanjeumairazliitifilteriButton.Text = 'Dodavanje šuma i različiti filteri';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Options

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end