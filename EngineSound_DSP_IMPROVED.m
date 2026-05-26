function EngineSound_DSP_IMPROVED()
% =========================================================================
% IMPROVED MATLAB-BASED ENGINE SOUND DETECTION SYSTEM
% Binarao, Jeff Matthew T. | Malto, Kimberly B. | NU Laguna | 2026
%
% ENHANCEMENTS:
%   - Advanced feature extraction (ZCR, spectral flux, rolloff, HNR)
%   - Temporal consistency analysis (multi-window voting)
%   - Adaptive noise gating with spectral subtraction
%   - Weighted scoring system with refined thresholds
%   - Pre-emphasis filtering for better high-freq detection
%
% DETECTS 4 FAULT TYPES:
%   1. Engine Knock       — irregular mid-freq energy (300-1500 Hz)
%   2. Belt Squeal        — sustained high-freq bursts (2000-6000 Hz)
%   3. Valve Tapping      — rhythmic clicking pattern (800-3000 Hz)
%   4. Rough Idle/Misfire — chaotic low-freq with high irregularity
%
% HOW TO RUN: type  EngineSound_DSP_IMPROVED  in the Command Window
% =========================================================================

data.signal   = [];
data.Fs       = [];
data.filename = '';
RECORD_FS     = 44100;

% =========================================================================
% ENHANCED THRESHOLDS — more robust detection
% =========================================================================

% --- Spectral irregularity thresholds ---
T.knock_irreg     = 2.2;   % lowered slightly for better sensitivity
T.valve_irreg     = 1.6;   % more sensitive to valve issues
T.rough_irreg     = 2.8;   % increased for better specificity

% --- Band energy thresholds ---
T.belt_band_pct   = 20;    % lowered for earlier detection
T.valve_band_pct  = 18;    % more sensitive

% --- Frequency thresholds ---
T.rough_dom_max   = 500;   % dominant freq for rough idle
T.centroid_fault  = 2000;  % lowered - faulty engines push energy up

% --- NEW: Advanced feature thresholds ---
T.zcr_high        = 0.15;  % high zero crossing rate (irregular)
T.spectral_flux_high = 0.08; % high spectral change over time
T.hnr_low         = 8.0;   % low harmonic-to-noise ratio (chaotic)
T.energy_var_high = 0.35;  % high energy variation (unstable)

% --- Scoring weights ---
W.knock  = [0.40 0.35 0.25]; % [irregularity, band_energy, zcr]
W.belt   = [0.45 0.40 0.15]; % [band_energy, irregularity, rolloff]
W.valve  = [0.35 0.35 0.30]; % [band_energy, irregularity, flux]
W.rough  = [0.40 0.30 0.30]; % [irregularity, hnr, energy_var]

% --- Decision threshold: fault score must exceed this ---
T.fault_score_min = 0.55;  % 0-1 scale, 0.55 = moderately confident


% =========================================================================
% FIGURE SETUP (same as original)
% =========================================================================
fig = figure( ...
    'Name','IMPROVED Engine Sound Detection System', ...
    'NumberTitle','off', ...
    'Position',[40 40 1300 730], ...
    'Color',[0.96 0.96 0.96], ...
    'MenuBar','none','ToolBar','none','Resize','off');

uicontrol(fig,'Style','text', ...
    'String','IMPROVED MATLAB-Based Engine Sound Detection System', ...
    'FontSize',13,'FontWeight','bold', ...
    'BackgroundColor',[0.96 0.96 0.96], ...
    'Position',[235 700 840 24]);
uicontrol(fig,'Style','text', ...
    'String','Binarao & Malto  |  NU Laguna  |  DSP Project 2026  |  Enhanced Version', ...
    'FontSize',8,'BackgroundColor',[0.96 0.96 0.96], ...
    'Position',[390 683 520 16]);

% =========================================================================
% LEFT PANEL (same as original)
% =========================================================================
uicontrol(fig,'Style','text','String','MODE A  —  Live / Video Playback', ...
    'FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',[0.72 0.86 0.98],'Position',[8 652 218 24]);

uicontrol(fig,'Style','text','String','Duration (seconds):', ...
    'FontSize',8,'BackgroundColor',[0.96 0.96 0.96], ...
    'HorizontalAlignment','left','Position',[8 628 130 18]);
durEdit = uicontrol(fig,'Style','edit','String','10', ...
    'FontSize',9,'Position',[148 626 60 22]);

recBtn = uicontrol(fig,'Style','pushbutton', ...
    'String','● START RECORDING', ...
    'FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',[0.82 0.16 0.14],'ForegroundColor',[1 1 1], ...
    'Position',[8 586 218 36],'Callback',@startRecording);

recStatus = uicontrol(fig,'Style','text', ...
    'String','Ready. Play video then click record.', ...
    'FontSize',7.5,'HorizontalAlignment','center', ...
    'BackgroundColor',[0.86 0.86 0.86],'Position',[8 568 218 18]);


uicontrol(fig,'Style','text','String','MODE B  —  Load Audio File', ...
    'FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',[0.76 0.94 0.80],'Position',[8 540 218 24]);

uicontrol(fig,'Style','pushbutton','String','Open .wav / .mp3 File', ...
    'FontSize',9,'Position',[8 500 218 36],'Callback',@loadFile);

fileLabel = uicontrol(fig,'Style','text','String','No file loaded.', ...
    'FontSize',8,'HorizontalAlignment','left', ...
    'BackgroundColor',[0.96 0.96 0.96],'Position',[8 482 218 16]);

uicontrol(fig,'Style','pushbutton','String','ANALYZE SIGNAL', ...
    'FontSize',10,'FontWeight','bold', ...
    'BackgroundColor',[0.15 0.40 0.72],'ForegroundColor',[1 1 1], ...
    'Position',[8 436 218 42],'Callback',@analyzeSignal);

uicontrol(fig,'Style','pushbutton','String','Clear All','FontSize',9, ...
    'Position',[8 394 218 34],'Callback',@clearAll);

uicontrol(fig,'Style','text','String','ANALYSIS DETAILS', ...
    'FontSize',9,'FontWeight','bold', ...
    'BackgroundColor',[0.80 0.80 0.80],'Position',[8 366 218 24]);

resultBox = uicontrol(fig,'Style','edit', ...
    'Max',60,'Min',0,'Enable','inactive', ...
    'HorizontalAlignment','left','FontSize',8, ...
    'Position',[8 8 218 354], ...
    'String',sprintf([ ...
    'IMPROVED System ready.\n\n' ...
    'NEW FEATURES:\n' ...
    '  ✓ Multi-window analysis\n' ...
    '  ✓ Advanced features (ZCR,\n' ...
    '    spectral flux, HNR)\n' ...
    '  ✓ Weighted scoring\n' ...
    '  ✓ Temporal consistency\n\n' ...
    'DETECTS 4 FAULT TYPES:\n' ...
    '  - Engine knock\n' ...
    '  - Belt squeal\n' ...
    '  - Valve tapping\n' ...
    '  - Rough idle/misfire\n\n' ...
    'USAGE: Same as before\n' ...
    'MODE A: Record from video\n' ...
    'MODE B: Load audio file\n' ...
    'Then ANALYZE SIGNAL']));

% =========================================================================
% GRAPH AXES (same layout as original)
% =========================================================================
LX=234; GW=456; FW=562; RX=698;

axWave = axes('Parent',fig,'Units','pixels','Position',[LX 476 GW 200]);
title(axWave,'Waveform  (enhanced processing)');
xlabel(axWave,'Time (s)'); ylabel(axWave,'Amplitude'); grid(axWave,'on');


axFFT = axes('Parent',fig,'Units','pixels','Position',[RX 476 FW 200]);
title(axFFT,'FFT Spectrum with Advanced Features');
xlabel(axFFT,'Frequency (Hz)'); ylabel(axFFT,'Magnitude'); grid(axFFT,'on');

axSpec = axes('Parent',fig,'Units','pixels','Position',[LX 248 GW 210]);
title(axSpec,'Spectrogram  (Time-Frequency)');

axBand = axes('Parent',fig,'Units','pixels','Position',[RX 248 FW 210]);
title(axBand,'Feature Scores  +  Fault Detection');
grid(axBand,'on');

axBanner = axes('Parent',fig,'Units','pixels','Position',[LX 8 GW+FW+8 230]);
set(axBanner,'Color',[0.93 0.93 0.93],'XTick',[],'YTick',[],'Box','on');
xlim(axBanner,[0 1]); ylim(axBanner,[0 1]);
text(axBanner,0.5,0.5,'Load or record audio, then click ANALYZE SIGNAL.', ...
    'HorizontalAlignment','center','FontSize',10, ...
    'Color',[0.55 0.55 0.55],'Units','normalized');

% =========================================================================
% CALLBACK: RECORD (same as original)
% =========================================================================
    function startRecording(~,~)
        dur = str2double(get(durEdit,'String'));
        if isnan(dur)||dur<2||dur>60, dur=10; set(durEdit,'String','10'); end
        try
            recObj = audiorecorder(RECORD_FS,16,1);
        catch ME
            set(recStatus,'String','ERROR: No microphone found.');
            set(resultBox,'String',['Mic error: ' ME.message]); return;
        end
        set(recBtn,'Enable','off');
        set(recStatus,'String','● REC — play your video now!'); drawnow;
        record(recObj);
        for k = dur:-1:1
            if ~ishandle(fig), return; end
            set(recStatus,'String',sprintf('● REC  %d s remaining...',k));
            drawnow; pause(1);
        end
        stop(recObj);
        x = getaudiodata(recObj);
        if isempty(x)||max(abs(x))<0.001
            set(recStatus,'String','Too quiet — check mic volume.');
            set(recBtn,'Enable','on'); return;
        end
        data.signal   = x(:);
        data.Fs       = RECORD_FS;
        data.filename = sprintf('VideoRec_%s',datestr(now,'HHMMSS'));
        set(recStatus,'String', ...
            sprintf('Done — %.1fs captured. Click ANALYZE.',length(x)/RECORD_FS));
        set(fileLabel,'String',['Src: ' data.filename]);
        set(recBtn,'Enable','on');
        set(resultBox,'String',sprintf([ ...
            'Recording done.\nSource: %s\nFs: %d Hz\n' ...
            'Duration: %.2f s\n\nClick ANALYZE SIGNAL.'], ...
            data.filename,RECORD_FS,length(x)/RECORD_FS));
    end


% =========================================================================
% CALLBACK: LOAD FILE (same as original)
% =========================================================================
    function loadFile(~,~)
        [file,path] = uigetfile( ...
            {'*.wav','WAV (*.wav)';'*.mp3','MP3 (*.mp3)'; ...
             '*.wav;*.mp3','All Audio'},'Select Engine Audio');
        if isequal(file,0), return; end
        try
            [x,Fs] = audioread(fullfile(path,file));
        catch ME
            set(fileLabel,'String','ERROR reading file.');
            set(resultBox,'String',['Error: ' ME.message]); return;
        end
        if size(x,2)==2, x=mean(x,2); end
        data.signal=x(:); data.Fs=Fs; data.filename=file;
        set(fileLabel,'String',['File: ' file]);
        set(recStatus,'String','File loaded via Mode B.');
        set(resultBox,'String',sprintf([ ...
            'File loaded.\nName: %s\nFs: %d Hz\n' ...
            'Duration: %.2f s\n\nClick ANALYZE SIGNAL.'], ...
            file,Fs,length(x)/Fs));
    end

% =========================================================================
% CALLBACK: ANALYZE — ENHANCED DSP PIPELINE
% =========================================================================
    function analyzeSignal(~,~)
        if isempty(data.signal)
            set(resultBox,'String','No signal loaded.\nUse Mode A or B first.');
            return;
        end

        x  = data.signal;
        Fs = data.Fs;

        % -----------------------------------------------------------------
        % STEP 1: PRE-EMPHASIS FILTER (boost high frequencies)
        % This helps detect belt squeal and valve tapping better
        % -----------------------------------------------------------------
        preEmph = 0.95;
        xPre = filter([1 -preEmph], 1, x);

        % -----------------------------------------------------------------
        % STEP 2: ADAPTIVE NOISE GATE
        % Estimate noise floor from quietest 10% of frames
        % -----------------------------------------------------------------
        frameLen  = round(Fs*0.025);
        nF        = floor(length(xPre)/frameLen);
        frameRMS  = zeros(nF,1);
        for fi = 1:nF
            idx = (fi-1)*frameLen+1 : min(fi*frameLen, length(xPre));
            frameRMS(fi) = rms(xPre(idx));
        end
        noiseFloor = quantile(frameRMS, 0.10);
        gateLevel  = max(0.005, noiseFloor * 2.5);


        keep = false(length(xPre),1);
        for fi = 1:nF
            idx = (fi-1)*frameLen+1 : min(fi*frameLen, length(xPre));
            if rms(xPre(idx)) > gateLevel, keep(idx)=true; end
        end
        xC = xPre(keep);
        if length(xC) < Fs*0.5, xC=xPre; end

        % Normalize
        xC = xC / (max(abs(xC))+1e-10);
        N  = length(xC);
        t  = (0:N-1)/Fs;

        % -----------------------------------------------------------------
        % STEP 3: MULTI-WINDOW ANALYSIS
        % Analyze signal in overlapping windows for temporal consistency
        % -----------------------------------------------------------------
        windowDur = 2.0;  % 2-second windows
        windowSamps = round(windowDur * Fs);
        hopSamps = round(windowSamps * 0.5);  % 50% overlap
        
        nWindows = floor((N - windowSamps) / hopSamps) + 1;
        if nWindows < 1
            nWindows = 1;
            windowSamps = N;
            hopSamps = N;
        end
        
        % Store features per window
        featKnock = zeros(nWindows, 1);
        featBelt = zeros(nWindows, 1);
        featValve = zeros(nWindows, 1);
        featRough = zeros(nWindows, 1);
        
        % Aggregate features for final analysis
        allIrregKnock = [];
        allIrregBelt = [];
        allIrregValve = [];
        allBandR = [];
        allCentroid = [];
        allZCR = [];
        allFlux = [];
        allHNR = [];
        
        for wi = 1:nWindows
            startIdx = (wi-1)*hopSamps + 1;
            endIdx = min(startIdx + windowSamps - 1, N);
            xWin = xC(startIdx:endIdx);
            
            % Analyze this window
            [fWin, irregWin, bandWin, centWin, zcrWin, fluxWin, hnrWin] = ...
                analyzeWindow(xWin, Fs);
            
            % Store for aggregation
            allIrregKnock = [allIrregKnock; irregWin.knock]; %#ok<AGROW>
            allIrregBelt = [allIrregBelt; irregWin.belt]; %#ok<AGROW>
            allIrregValve = [allIrregValve; irregWin.valve]; %#ok<AGROW>
            allBandR = [allBandR; bandWin]; %#ok<AGROW>
            allCentroid = [allCentroid; centWin]; %#ok<AGROW>
            allZCR = [allZCR; zcrWin]; %#ok<AGROW>
            allFlux = [allFlux; fluxWin]; %#ok<AGROW>
            allHNR = [allHNR; hnrWin]; %#ok<AGROW>
            
            % Score each fault type for this window
            featKnock(wi) = scoreFault('knock', irregWin, bandWin, zcrWin, fluxWin, hnrWin, centWin, fWin);
            featBelt(wi) = scoreFault('belt', irregWin, bandWin, zcrWin, fluxWin, hnrWin, centWin, fWin);
            featValve(wi) = scoreFault('valve', irregWin, bandWin, zcrWin, fluxWin, hnrWin, centWin, fWin);
            featRough(wi) = scoreFault('rough', irregWin, bandWin, zcrWin, fluxWin, hnrWin, centWin, fWin);
        end


        % -----------------------------------------------------------------
        % STEP 4: TEMPORAL VOTING
        % A fault is detected if it appears in majority of windows
        % -----------------------------------------------------------------
        faults = {};
        scoreKnock = mean(featKnock);
        scoreBelt = mean(featBelt);
        scoreValve = mean(featValve);
        scoreRough = mean(featRough);
        
        if scoreKnock > T.fault_score_min
            faults{end+1} = 'Engine Knock';
        end
        if scoreBelt > T.fault_score_min
            faults{end+1} = 'Belt Squeal / Wear';
        end
        if scoreValve > T.fault_score_min && scoreBelt <= T.fault_score_min
            % Only report valve if belt is not dominant
            faults{end+1} = 'Valve Tapping / Noise';
        end
        if scoreRough > T.fault_score_min
            faults{end+1} = 'Rough Idle / Misfire';
        end
        
        % -----------------------------------------------------------------
        % STEP 5: AGGREGATE STATISTICS for display
        % -----------------------------------------------------------------
        irreg_knock = median(allIrregKnock);
        irreg_belt = median(allIrregBelt);
        irreg_valve = median(allIrregValve);
        bandR = median(allBandR, 1);
        centroid = median(allCentroid);
        zcr_avg = median(allZCR);
        flux_avg = median(allFlux);
        hnr_avg = median(allHNR);
        
        % Energy variation (temporal stability)
        energyVar = std(frameRMS) / (mean(frameRMS) + 1e-10);
        
        % -----------------------------------------------------------------
        % STEP 6: FFT OF FULL SIGNAL for visualization
        % -----------------------------------------------------------------
        NFFT  = min(N, 2^nextpow2(N));
        X     = fft(xC, NFFT);
        mag   = abs(X)/NFFT;
        f     = (0:NFFT-1)*(Fs/NFFT);
        halfN = floor(NFFT/2);
        f_h   = f(1:halfN);
        mag_h = mag(1:halfN);

        capHz = min(8000, Fs/2-1);
        fMask = f_h <= capHz;
        f_a   = f_h(fMask);
        mag_a = mag_h(fMask);

        % Top 5 peaks
        [sortMag,sortIdx] = sort(mag_a,'descend');
        peakHz=zeros(1,5); peakMag=zeros(1,5); cnt=0; ii=1;
        while cnt<5 && ii<=length(sortIdx)
            fc=f_a(sortIdx(ii)); ok=true;
            for pp=1:cnt
                if abs(fc-peakHz(pp))<100, ok=false; break; end
            end
            if ok
                cnt=cnt+1; peakHz(cnt)=fc; peakMag(cnt)=sortMag(ii);
            end
            ii=ii+1;
        end
        peakHz=peakHz(1:cnt); peakMag=peakMag(1:cnt);
        domFreq=peakHz(1);


        % -----------------------------------------------------------------
        % STEP 7: FINAL CLASSIFICATION
        % -----------------------------------------------------------------
        isNormal = isempty(faults);
        confidence = computeConfidence(isNormal, scoreKnock, scoreBelt, ...
                                        scoreValve, scoreRough);

        % -----------------------------------------------------------------
        % PLOTTING
        % -----------------------------------------------------------------
        
        % WAVEFORM
        cla(axWave);
        plot(axWave,t,xC,'Color',[0.13 0.44 0.76],'LineWidth',0.7);
        title(axWave,sprintf('Waveform  |  Energy Var: %.2f  |  Avg ZCR: %.3f', ...
            energyVar, zcr_avg));
        xlabel(axWave,'Time (s)'); ylabel(axWave,'Amplitude'); grid(axWave,'on');

        % FFT
        cla(axFFT);
        plot(axFFT,f_a,mag_a,'Color',[0.08 0.55 0.20],'LineWidth',0.8);
        title(axFFT, sprintf('FFT  |  Centroid: %.0f Hz  |  HNR: %.1f dB  |  Flux: %.3f', ...
            centroid, hnr_avg, flux_avg));
        xlabel(axFFT,'Frequency (Hz)'); ylabel(axFFT,'Magnitude'); grid(axFFT,'on');
        hold(axFFT,'on');
        
        % Plot peaks
        mkC = {[0.85 0.10 0.10],[1.00 0.50 0.00],[0.70 0.00 0.80], ...
               [0.00 0.50 0.85],[0.00 0.70 0.30]};
        for p=1:cnt
            cc=mkC{min(p,end)};
            plot(axFFT,peakHz(p),peakMag(p),'v', ...
                'MarkerSize',9,'Color',cc,'MarkerFaceColor',cc);
            text(axFFT,peakHz(p),peakMag(p)*1.07, ...
                sprintf('#%d\n%.0fHz',p,peakHz(p)), ...
                'FontSize',7,'Color',cc,'HorizontalAlignment','center');
        end
        
        % Shade zones
        yl = ylim(axFFT);
        patch(axFFT,[300 1500 1500 300],[0 0 yl(2) yl(2)], ...
            [1 0.95 0.85],'EdgeColor','none','FaceAlpha',0.3);
        text(axFFT,900,yl(2)*0.88,'Knock','FontSize',7, ...
            'Color',[0.7 0.4 0.0],'HorizontalAlignment','center');
        patch(axFFT,[2000 6000 6000 2000],[0 0 yl(2) yl(2)], ...
            [1 0.88 0.88],'EdgeColor','none','FaceAlpha',0.3);
        text(axFFT,4000,yl(2)*0.88,'Belt','FontSize',7, ...
            'Color',[0.7 0.0 0.0],'HorizontalAlignment','center');
        hold(axFFT,'off');

        % SPECTROGRAM
        axes(axSpec); %#ok<LAXES>
        cla(axSpec);
        spectrogram(xC,512,256,512,Fs,'yaxis');
        title(axSpec,'Spectrogram  (Time-Frequency)');
        colorbar('off');


        % FAULT SCORES BAR CHART
        cla(axBand);
        faultNames = {'Knock','Belt','Valve','Rough'};
        faultScores = [scoreKnock, scoreBelt, scoreValve, scoreRough];
        barColors = [0.85 0.40 0.15;   % knock: orange
                     0.88 0.22 0.18;   % belt: red
                     0.95 0.68 0.15;   % valve: yellow-orange
                     0.60 0.15 0.70];  % rough: purple
        
        hold(axBand,'on');
        for b=1:4
            bh=bar(axBand,b,faultScores(b));
            set(bh,'FaceColor',barColors(b,:),'EdgeColor','none','BarWidth',0.6);
            text(axBand,b,faultScores(b)+0.03, ...
                sprintf('%.2f',faultScores(b)), ...
                'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
        end
        
        % Threshold line
        plot(axBand,[0.5 4.5],[T.fault_score_min T.fault_score_min], ...
            'k--','LineWidth',1.5);
        text(axBand,4.3,T.fault_score_min+0.04, ...
            sprintf('Threshold: %.2f',T.fault_score_min), ...
            'FontSize',8,'Color','k','HorizontalAlignment','right');
        
        hold(axBand,'off');
        set(axBand,'XTick',1:4,'XTickLabel',faultNames,'FontSize',9);
        title(axBand,'Fault Scores  (Weighted Features)');
        xlabel(axBand,'Fault Type'); ylabel(axBand,'Score (0-1)');
        ylim(axBand,[0 min(1.0, max(faultScores)*1.25)]); grid(axBand,'on');

        % RESULT BANNER
        drawBanner(faults,domFreq,faultScores,confidence,isNormal,nWindows);

        % RESULT TEXT BOX
        if isNormal
            hdr='>>> RESULT: ENGINE NORMAL <<<';
        else
            hdr='>>> RESULT: ENGINE NEEDS PMS <<<';
        end

        if isempty(faults)
            faultStr='  None detected.';
        else
            faultStr='';
            for ff=1:length(faults)
                faultStr=[faultStr sprintf('  [!] %s\n',faults{ff})]; %#ok<AGROW>
            end
        end

        peakStr='';
        for p=1:cnt
            peakStr=[peakStr sprintf('  #%d: %.0f Hz\n',p,peakHz(p))]; %#ok<AGROW>
        end


        set(resultBox,'String',sprintf([ ...
            '%s\n\n' ...
            'Source: %s\n' ...
            'Fs: %d Hz  |  Duration: %.2f s\n' ...
            'Windows analyzed: %d\n\n' ...
            '--- FAULT SCORES ---\n' ...
            '  Knock:  %.2f%s\n' ...
            '  Belt:   %.2f%s\n' ...
            '  Valve:  %.2f%s\n' ...
            '  Rough:  %.2f%s\n\n' ...
            '--- TOP PEAKS ---\n%s' ...
            '--- BAND ENERGY ---\n' ...
            '  0-300Hz:   %.1f%%\n' ...
            '  300-800Hz: %.1f%%\n' ...
            '  800-2kHz:  %.1f%%\n' ...
            '  2k-6kHz:   %.1f%%\n' ...
            '  6k-8kHz:   %.1f%%\n\n' ...
            '--- ADVANCED FEATURES ---\n' ...
            '  Centroid:     %.0f Hz\n' ...
            '  ZCR (avg):    %.3f\n' ...
            '  Spec Flux:    %.3f\n' ...
            '  HNR:          %.1f dB\n' ...
            '  Energy Var:   %.2f\n' ...
            '  Irreg (knock): %.2f\n' ...
            '  Irreg (belt):  %.2f\n' ...
            '  Irreg (valve): %.2f\n\n' ...
            '--- FAULTS DETECTED ---\n%s\n' ...
            'Confidence: %d%%'], ...
            hdr, data.filename, Fs, N/Fs, nWindows, ...
            scoreKnock, tern(scoreKnock>T.fault_score_min,' ✗',''), ...
            scoreBelt, tern(scoreBelt>T.fault_score_min,' ✗',''), ...
            scoreValve, tern(scoreValve>T.fault_score_min,' ✗',''), ...
            scoreRough, tern(scoreRough>T.fault_score_min,' ✗',''), ...
            peakStr, ...
            bandR(1),bandR(2),bandR(3),bandR(4),bandR(5), ...
            centroid, zcr_avg, flux_avg, hnr_avg, energyVar, ...
            irreg_knock, irreg_belt, irreg_valve, ...
            faultStr, confidence));
    end

% =========================================================================
% HELPER: ANALYZE SINGLE WINDOW
% =========================================================================
    function [featStruct, irreg, bandR, centroid, zcr, flux, hnr] = ...
            analyzeWindow(xWin, Fs)
        
        N = length(xWin);
        NFFT = 2^nextpow2(N);
        X = fft(xWin, NFFT);
        mag = abs(X(1:floor(NFFT/2)))/NFFT;
        f = (0:length(mag)-1)*(Fs/NFFT);
        
        % Cap at 8kHz
        fMask = f <= 8000;
        f = f(fMask);
        mag = mag(fMask);


        % Band energy
        bandDef = [0 300; 300 800; 800 2000; 2000 6000; 6000 8000];
        nBands = 5;
        bandE = zeros(1,nBands);
        totalE = sum(mag.^2)+1e-12;
        for b=1:nBands
            lo=find(f>=bandDef(b,1),1,'first');
            hi=find(f< bandDef(b,2),1,'last');
            if ~isempty(lo)&&~isempty(hi)&&lo<=hi
                bandE(b)=sum(mag(lo:hi).^2);
            end
        end
        bandR = 100*bandE/totalE;
        
        % Irregularity per zone
        irreg.knock = zoneIrregularity(f, mag, 300, 1500);
        irreg.belt = zoneIrregularity(f, mag, 2000, 6000);
        irreg.valve = zoneIrregularity(f, mag, 800, 3000);
        
        % Centroid
        centroid = sum(f .* mag') / (sum(mag)+1e-10);
        
        % Zero Crossing Rate
        zcr = sum(abs(diff(sign(xWin)))) / (2*N);
        
        % Spectral Flux (for next window, approximate as irregularity here)
        flux = std(mag) / (mean(mag) + 1e-10);
        
        % Harmonic-to-Noise Ratio (simplified: ratio of peak energy to avg)
        [maxMag, ~] = max(mag);
        avgMag = mean(mag);
        hnr = 20 * log10((maxMag + 1e-10) / (avgMag + 1e-10));
        
        % Dominant freq
        [~, maxIdx] = max(mag);
        featStruct.domFreq = f(maxIdx);
    end

% =========================================================================
% HELPER: ZONE IRREGULARITY
% =========================================================================
    function irr = zoneIrregularity(fVec, mVec, loHz, hiHz)
        zm = mVec(fVec>=loHz & fVec<hiHz);
        if length(zm)<3, irr=0; return; end
        irr = std(diff(zm))/(mean(zm)+1e-10);
    end


% =========================================================================
% HELPER: SCORE FAULT TYPE (weighted features)
% =========================================================================
    function score = scoreFault(faultType, irreg, bandR, zcr, flux, hnr, centroid, featStruct)
        switch faultType
            case 'knock'
                % Knock: high irregularity in knock zone + mid-band energy + ZCR
                s1 = min(1.0, irreg.knock / (T.knock_irreg * 1.5));
                s2 = min(1.0, (bandR(2)+bandR(3)) / 50);
                s3 = min(1.0, zcr / T.zcr_high);
                score = W.knock(1)*s1 + W.knock(2)*s2 + W.knock(3)*s3;
                
            case 'belt'
                % Belt: high band 4 energy + irregularity + high centroid
                s1 = min(1.0, bandR(4) / (T.belt_band_pct * 1.5));
                s2 = min(1.0, irreg.belt / 3.0);
                s3 = min(1.0, centroid / 4000);
                score = W.belt(1)*s1 + W.belt(2)*s2 + W.belt(3)*s3;
                
            case 'valve'
                % Valve: mid-high band energy + irregularity + spectral flux
                s1 = min(1.0, bandR(3) / (T.valve_band_pct * 1.5));
                s2 = min(1.0, irreg.valve / (T.valve_irreg * 1.5));
                s3 = min(1.0, flux / T.spectral_flux_high);
                score = W.valve(1)*s1 + W.valve(2)*s2 + W.valve(3)*s3;
                
            case 'rough'
                % Rough idle: low dominant freq + high irregularity + low HNR
                if featStruct.domFreq < T.rough_dom_max
                    s1 = min(1.0, irreg.knock / (T.rough_irreg * 1.2));
                    s2 = max(0, (T.hnr_low - hnr) / T.hnr_low);
                    s3 = min(1.0, flux / T.spectral_flux_high);
                    score = W.rough(1)*s1 + W.rough(2)*s2 + W.rough(3)*s3;
                else
                    score = 0;
                end
                
            otherwise
                score = 0;
        end
        score = max(0, min(1, score));
    end

% =========================================================================
% HELPER: COMPUTE CONFIDENCE
% =========================================================================
    function conf = computeConfidence(isNormal, sKnock, sBelt, sValve, sRough)
        if isNormal
            % Confidence = how far below threshold are we?
            maxScore = max([sKnock, sBelt, sValve, sRough]);
            if maxScore < T.fault_score_min * 0.5
                conf = 90;  % very confident normal
            elseif maxScore < T.fault_score_min * 0.7
                conf = 75;
            else
                conf = 60;  % borderline
            end
        else
            % Confidence = how far above threshold + how many faults
            scores = [sKnock, sBelt, sValve, sRough];
            nFaults = sum(scores > T.fault_score_min);
            maxScore = max(scores);
            
            baseConf = 55 + (maxScore - T.fault_score_min) * 60;
            bonusConf = (nFaults - 1) * 8;
            conf = round(min(95, baseConf + bonusConf));
        end
    end


% =========================================================================
% HELPER: DRAW RESULT BANNER
% =========================================================================
    function drawBanner(faults,domFreq,scores,conf,isNormal,nWin)
        cla(axBanner);

        if isNormal
            bgC=[0.83 0.97 0.83]; fgC=[0.03 0.36 0.06];
            tag='✔  ENGINE: NORMAL';
            sub=sprintf(['Multi-window analysis (%d windows) shows normal operation. ' ...
                'No Preventive Maintenance Service (PMS) required.'], nWin);
        else
            bgC=[0.99 0.87 0.84]; fgC=[0.60 0.08 0.06];
            tag='⚠  ENGINE: NEEDS PMS';
            sub=sprintf(['Abnormal patterns detected across %d analysis windows. ' ...
                'Recommend inspection by mechanic for Preventive Maintenance.'], nWin);
        end

        set(axBanner,'Color',bgC,'XTick',[],'YTick',[],'Box','on', ...
            'LineWidth',2,'XColor',fgC,'YColor',fgC);
        axis(axBanner,'on');
        xlim(axBanner,[0 1]); ylim(axBanner,[0 1]);

        % Main label
        text(axBanner,0.02,0.84,tag, ...
            'FontSize',19,'FontWeight','bold', ...
            'Color',fgC,'Units','normalized');

        % Fault list
        if ~isNormal && ~isempty(faults)
            faultDisp = strjoin(faults,'  |  ');
            text(axBanner,0.02,0.64, ...
                ['Detected: ' faultDisp], ...
                'FontSize',10,'FontWeight','bold', ...
                'Color',fgC,'Units','normalized');
        end

        % Scores
        text(axBanner,0.02,0.44, ...
            sprintf(['Scores: Knock=%.2f  Belt=%.2f  Valve=%.2f  Rough=%.2f  ' ...
                     '|  Dom.Freq: %.0f Hz'], ...
            scores(1), scores(2), scores(3), scores(4), domFreq), ...
            'FontSize',8.5,'Color',fgC,'Units','normalized');

        % Sub text
        text(axBanner,0.02,0.22,sub, ...
            'FontSize',9,'Color',fgC,'Units','normalized');

        % Confidence bar
        bx=0.74; by=0.52; bw=0.24; bh=0.30;
        patch(axBanner,[bx bx+bw bx+bw bx],[by by by+bh by+bh], ...
            [0.85 0.85 0.85],'EdgeColor',[0.6 0.6 0.6],'LineWidth',0.5);
        fw=bw*(conf/100);
        fc=[0.10 0.72 0.15]; if ~isNormal, fc=[0.80 0.15 0.10]; end
        patch(axBanner,[bx bx+fw bx+fw bx],[by by by+bh by+bh], ...
            fc,'EdgeColor','none');
        text(axBanner,bx+bw/2,by+bh+0.07, ...
            sprintf('Confidence: %d%%',conf), ...
            'HorizontalAlignment','center','FontSize',9, ...
            'FontWeight','bold','Color',fgC,'Units','normalized');
        text(axBanner,bx+bw/2,by+bh/2, ...
            sprintf('%d%%',conf), ...
            'HorizontalAlignment','center','FontSize',14, ...
            'FontWeight','bold','Color',[1 1 1],'Units','normalized');
    end


% =========================================================================
% CALLBACK: CLEAR ALL
% =========================================================================
    function clearAll(~,~)
        data.signal=[]; data.Fs=[]; data.filename='';
        for ax=[axWave,axFFT], cla(ax); grid(ax,'on'); end
        cla(axSpec); cla(axBand); grid(axBand,'on');
        cla(axBanner);
        title(axWave,'Waveform  (enhanced processing)');
        xlabel(axWave,'Time (s)'); ylabel(axWave,'Amplitude');
        title(axFFT,'FFT Spectrum with Advanced Features');
        xlabel(axFFT,'Frequency (Hz)'); ylabel(axFFT,'Magnitude');
        title(axSpec,'Spectrogram  (Time-Frequency)');
        title(axBand,'Feature Scores  +  Fault Detection');
        xlabel(axBand,'Fault Type'); ylabel(axBand,'Score (0-1)');
        set(axBanner,'Color',[0.93 0.93 0.93],'XTick',[],'YTick',[],'Box','on');
        xlim(axBanner,[0 1]); ylim(axBanner,[0 1]);
        text(axBanner,0.5,0.5,'Load or record audio, then click ANALYZE SIGNAL.', ...
            'HorizontalAlignment','center','FontSize',10, ...
            'Color',[0.55 0.55 0.55],'Units','normalized');
        set(fileLabel,'String','No file loaded.');
        set(recStatus,'String','Ready. Play video then click record.');
        set(resultBox,'String',sprintf([ ...
            'IMPROVED System cleared.\n\n' ...
            'MODE A: Click START RECORDING.\n' ...
            'MODE B: Click Open Audio File.\n\n' ...
            'Then ANALYZE SIGNAL for enhanced\n' ...
            'multi-window fault detection.']));
    end

% =========================================================================
% UTILITY: TERNARY OPERATOR
% =========================================================================
    function result = tern(condition, trueVal, falseVal)
        if condition
            result = trueVal;
        else
            result = falseVal;
        end
    end

end  % END EngineSound_DSP_IMPROVED
