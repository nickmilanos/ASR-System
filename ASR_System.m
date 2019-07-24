% Automatic Sound Recognition System
% ==================================
clear
clc
% Signal Processing and Useful Feature Extraction
% ===============================================

[y, ~] = audioread("Testing Set/numbers3.wav");

% Reduction of Sampling Rate 
Fs = 10000;

% DC offset subtraction
y = y - mean(y);

% Subtraction of 60Hz hum from signal,using an FIR Bandstop filter
humFilter = designfilt('bandstopfir','FilterOrder',30, ...
        'CutoffFrequency1',59,'CutoffFrequency2',61, ...
        'SampleRate',Fs);
y = filter(humFilter, y);

% Signal Discretization into frames and application of a Hamming window on each frame
% Windows overlap with each other by 50%
L = 400; % Window length in samples
R = 200; % Window step in samples
original_y = y;
y = buffer(y, L, R);
for i = 1:length(y)
    y(:,i) = y(:,i) .* hamming(L);
end

%  Log of Energy per frame
E = 10*log10(sum(y.^2));

% ZeroCrossing Rate per frame
ZCR = (R/(2*L)) * sum(abs(diff(sign(y))));

% Average value and standard deviation of Energy and ZCR of 10 first frames 
% which will be used in order to calculate satisfactory thresholds 
eavg = mean(E(1:10));
zcavg = mean(ZCR(1:10));

esig = std(E(1:10));
zcsig = std(ZCR(1:10));

% Calculation of Zero Crossing Rate Threshold
IF = 35; % Generic Threshold for detection of non-verbal frames
IZCT = max(IF, zcavg + 3 * zcsig);

% Calculation of Energy Thresholds
IMX = abs(max(E)); % Absolute width of highest pick of Energy 
ITU = IMX-20; % Highest Energy Threshold
ITR = max(ITU - 10, eavg + 3 * esig); % Lowest Energy Threshold


% Search for the borders of each word
% ===================================
% Energy, Zero Crossing Rate and all of thresholds graph
% During the search, the borders of each digit found are marked with dashed lines
original_E = E;
figure(1);
plot(original_E);
hold on;
plot(ZCR);
xlabel('Frames');
yline(ITR, ':','ITR');
yline(ITU, ':','ITU');
yline(IZCT, ':','IZCT');

% Find the frame with the highest value of enegry and then extend left and right of it 
% in order to find where speech starts and ends, using Log of Energy, and thersholds ITU and ITR
StartingFrames = [];
FinishingFrames = [];
anotherDigitExists = true;

digitCounter = 0;
while anotherDigitExists == true   
    maxEnergyFrame = findMaxEnergyFrame(E, y);
    leftITUBorder = findLeftITUBorder(maxEnergyFrame, E, ITU);
    rightITUBorder = findRightITUBorder(maxEnergyFrame, y, ITU, E);
    leftITRBorder = findLeftITRBorder(leftITUBorder, E, ITR);
    rightITRBorder = findRightITRBorder(rightITUBorder, E, ITR);

    StartingFrame = leftITRBorder;
    FinishingFrame = rightITRBorder;

% Extension of the search of beginning and enging of speech piece
% using  Zero Crossing Rate and IZCT threshold

% Left end extension
    StartingFrame = findFinalLeftBorder(StartingFrame, ZCR, IZCT, ITR, E);
    xline(StartingFrame, ':', 'Start');
    
% Right end extension
    FinishingFrame = findFinalRightBorder(FinishingFrame, ZCR, IZCT, E, ITR);
    xline(FinishingFrame, ':', 'Finish');

% Modification of Energy of given digit in order of it not participating into the following 
% repetitions of the searching algorithm
    E(StartingFrame-10 : FinishingFrame+10 ) = ITR - 10;
    
    
% Storing of all starting and ending frames into two matrices
StartingFrames = [StartingFrames StartingFrame];
StartingFrames = sort(StartingFrames);
FinishingFrames = [FinishingFrames FinishingFrame];
FinishingFrames = sort(FinishingFrames);
    
digitCounter = digitCounter + 1;
    
% Check for existence of other digits 
    for i = 1:length(y)
        if E(i) > ITU
            anotherDigitExists = true;
            break;
        else
            anotherDigitExists = false;
        end
    end
end

% Signal discretization and preservation only of thoses pieces in which speech exists
for i = 1 : digitCounter
    speechOnly{i} = original_y(StartingFrames(i) * R : FinishingFrames(i) * R);
end

% MFCC extraction from each piece in which speech was detected
for i = 1: digitCounter    
    mfccsinput{i} = mfcc(speechOnly{i}, Fs);
    % Transformation of each matrix tha includes MFCC coefficients into a vector
    mfccsinput{i} = mfccsinput{i}(:);

end

% Dynamic Time Warping
% ====================

% Load into workspace the stored MFCC coefficients which where extracted from all reference templates
% These coefficients where extracted from reference templates the same way they are extracted from the input signal
% Before the extraction the reference templates where preprocessed and cut the exact same way the input signal
% is manipulated
allMfccs = {'MFCCs Προτύπων Αναφοράς/MFCCs0.mat','MFCCs Προτύπων Αναφοράς/MFCCs02.mat'...
    ,'MFCCs Προτύπων Αναφοράς/MFCCs1.mat','MFCCs Προτύπων Αναφοράς/MFCCs12.mat'...
    ,'MFCCs Προτύπων Αναφοράς/MFCCs2.mat','MFCCs Προτύπων Αναφοράς/MFCCs22.mat'...
    ,'MFCCs Προτύπων Αναφοράς/MFCCs3.mat','MFCCs Προτύπων Αναφοράς/MFCCs32.mat'...
    ,'MFCCs Προτύπων Αναφοράς/MFCCs4.mat','MFCCs Προτύπων Αναφοράς/MFCCs42.mat'...
    ,'MFCCs Προτύπων Αναφοράς/MFCCs5.mat','MFCCs Προτύπων Αναφοράς/MFCCs52.mat'...
    ,'MFCCs Προτύπων Αναφοράς/MFCCs6.mat','MFCCs Προτύπων Αναφοράς/MFCCs62.mat'...
    ,'MFCCs Προτύπων Αναφοράς/MFCCs7.mat','MFCCs Προτύπων Αναφοράς/MFCCs72.mat'...
    ,'MFCCs Προτύπων Αναφοράς/MFCCs8.mat','MFCCs Προτύπων Αναφοράς/MFCCs82.mat'...
    ,'MFCCs Προτύπων Αναφοράς/MFCCs9.mat','MFCCs Προτύπων Αναφοράς/MFCCs92.mat'};

for i = 1:numel(allMfccs)
    load(allMfccs{i});
end



for i = 1 : digitCounter
    inputSignal = speechOnly{i};
    
   % Calculation of distances from MFCCs of each reference template 
    d0  = dtw(mfccsinput{i}, mfccs0);
    d02 = dtw(mfccsinput{i}, mfccs02);
    d1  = dtw(mfccsinput{i}, mfccs1);
    d12 = dtw(mfccsinput{i}, mfccs12);
    d2  = dtw(mfccsinput{i}, mfccs2);
    d22 = dtw(mfccsinput{i}, mfccs22);
    d3  = dtw(mfccsinput{i}, mfccs3);
    d32 = dtw(mfccsinput{i}, mfccs32);
    d4  = dtw(mfccsinput{i}, mfccs4);
    d42 = dtw(mfccsinput{i}, mfccs42);
    d5  = dtw(mfccsinput{i}, mfccs5);
    d52 = dtw(mfccsinput{i}, mfccs52);
    d6  = dtw(mfccsinput{i}, mfccs6);
    d62 = dtw(mfccsinput{i}, mfccs62);
    d7  = dtw(mfccsinput{i}, mfccs7);
    d72 = dtw(mfccsinput{i}, mfccs72);
    d8  = dtw(mfccsinput{i}, mfccs8);
    d82 = dtw(mfccsinput{i}, mfccs82);
    d9  = dtw(mfccsinput{i}, mfccs9);
    d92 = dtw(mfccsinput{i}, mfccs92);
    
    distances = [d0 d02 d1 d12 d2 d22 d3 d32 d4 d42 d5 d52 d6 d62 d7 d72 d8 d82 d9 d92];
    sortedDistances = sort(distances);
    % Pick the smallest "distance"
    answer = sortedDistances(1);

    switch answer
        case {d0, d02}
            fprintf('Μηδέν (0) \n');
        case {d1, d12}
            fprintf('Ένα (1) \n');
        case {d2, d22}
            fprintf('Δύο (2) \n');
        case {d3, d32}
            fprintf('Τρία (3) \n');
        case {d4, d42} 
            fprintf('Τέσσερα (4) \n');
        case {d5, d52}
            fprintf('Πέντε (5) \n');
        case {d6, d62}
            fprintf('Έξι (6) \n');
        case {d7, d72}
            fprintf('Εφτά (7) \n');
        case {d8, d82}
            fprintf('Οχτώ (8) \n');
        case {d9, d92}
            fprintf('Εννιά (9) \n');
    end
end



% Functions Used 
% ==============
function maxEnergyFrame= findMaxEnergyFrame(E, y)
    maxEnergyFrame = 1;
    for i = 1:length(y)
        if E(i) > E(maxEnergyFrame)
            maxEnergyFrame = i;
        end
    end
end

function leftITUBorder = findLeftITUBorder(maxEnergyFrame, E, ITU)
    for i = maxEnergyFrame: -1 : 1
        if E(i) < ITU
            leftITUBorder = i;
            break;
        end
    end
end

function rightITUBorder = findRightITUBorder(maxEnergyFrame, y, ITU, E)
    for i = maxEnergyFrame:length(y)
        if E(i) < ITU
            rightITUBorder = i;
            break;
        end
    end
end

function leftITRBorder = findLeftITRBorder(leftITUBorder, E, ITR)
    for i = leftITUBorder - 60 : leftITUBorder
        if E(i) < ITR
            leftITRBorder = i;
        end
    end
end

function rightITRBorder = findRightITRBorder(rightITUBorder, E, ITR)
    for i = rightITUBorder + 60 :-1: rightITUBorder
        if E(i) < ITR
            rightITRBorder = i;
        end
    end
end

function StartingFrame = findFinalLeftBorder(StartingFrame, ZCR, IZCT, ITR, E)
    newLeftBorder = StartingFrame - 30;
    for i = StartingFrame : -1 : newLeftBorder
        if ZCR(i) > IZCT
            StartingFrame = i;
        end
    end
    newLeftBorder = StartingFrame - 30;
    for i = StartingFrame : -1 : newLeftBorder
        if E(i) > ITR
            StartingFrame = i;
        end
    end
end

function FinishingFrame = findFinalRightBorder(FinishingFrame, ZCR, IZCT, E, ITR)
    newRightBorder = FinishingFrame + 30;
    for i = FinishingFrame : newRightBorder
        if ZCR(i) > IZCT
            FinishingFrame = i;
        end
    end
    newRightBorder = FinishingFrame + 30;
    for i = FinishingFrame : newRightBorder
        if E(i) > ITR
            FinishingFrame = i;
        end
    end
end
