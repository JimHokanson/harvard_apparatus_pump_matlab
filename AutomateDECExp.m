% Automated DEC SplitPrep Experiment

%% Initialize Comms

% serial communicaitons with pump
pump = PumpComs('COM4');
% assign pump addresses
adrU = 0;
adrB = 1;
% switch serial ttl output to zero
ttlSet(pump,'OFF')


% interface with Labchart
TempInstance = actxserver('ADIChart.Document');
LCApp = TempInstance.Application;
TempInstance.Close



%% RUN Urethral Flow Block

% === Manual and Recorderd Experiment Parameters ===

% measured values
BCs = [0.215, 0.380, 0.250, 0.470];        % BCs as measured in pretrials

% bladder fill parameters
InitBVol = 1/3;                     % initial fill volume in flow trials
InitTTF = 10;                       % amount of time (min) in which to reach target B vol
pctBCrate = 0.5;                    % bladder fill rate (BCs/hr)

% urethral flow parameters
dVu = [0.1 0.5 1.0 5.0 11];         % urethral flow rates to use
mpf = 2.0;                          % min per flow trial
fon = 10;                           % seconds flow is on during trial
T = 80;                             % total sequence time


% === generate sequence of pseudorandom urethral flows ===

% construct sequence (ensure random but homogeneous fills)
lq=length(dVu);         % number of rates per block
n = floor(T/(mpf*lq));  % num of blocks

flowSeq=nan(1,n*lq);
for k=1:n
    flowSeq( ((k-1)*lq+1:k*lq) ) = dVu(randperm(lq));
end


% === run protocol ===

% Fill bladder to pre-determined percent of BC
TargVolB = mean(BCs)*InitBVol;          % target bladder volume
InitFillRate = TargVolB/(InitTTF/60);   % fill rate needed to reach target in TTF min
FlowRate(pump,adrB,InitFillRate,'MH');  % set the fill rate
fprintf('BC: %2.3g ml\n',mean(BCs));    % inform user
fprintf('Filling Bladder %2.3g ml/hr\n\n',InitFillRate)

Start(pump,adrB);                               % start filling
comtext = ['B ' num2str(InitFillRate) 'ml/hr']; % note the time and rate in LC
LCApp.ActiveDocument.AppendComment(comtext,-1); 
pause(InitTTF*60)                               % wait TTF min
Stop(pump,adrB)                                 % stop the pump
LCApp.ActiveDocument.AppendComment('B off',-1); % note the bladder filling stopped in LC
pause(2)

% continue filling bladder at a slower rate for urethral flow trials
SlowFillRate = mean(BCs)*pctBCrate;             % compute during-trial fill rate
FlowRate(pump,adrB,SlowFillRate,'MH');
fprintf('Filling Bladder %2.3g ml/hr\n\n',SlowFillRate)

Start(pump,adrB)
comtext = ['B ' num2str(SlowFillRate) 'ml/hr']; % note the time and rate in LC
LCApp.ActiveDocument.AppendComment(comtext,-1); 
pause(2)


% Various urethral flows
for k=1:length(flowSeq)
    fprintf('\nFlow trial %g of %g. Flowrate: %2.3g ml/min\n',k,length(flowSeq),flowSeq(k))
    
    FlowRate(pump,adrU,flowSeq(k),'MM');
    Start(pump,adrU)
    ttlSet(pump,adrU,'ON')
    comtext = ['U ' num2str(flowSeq(k)) 'ml/min'];
    LCApp.ActiveDocument.AppendComment(comtext,-1);
    pause(fon)
    Stop(pump,adrU)
    ttlSet(pump,adrU,'OFF')
    
    if k==length(flowSeq)
        % notify user of end of block, stop the bladder filling
        disp('block complete')
        pause(5);   % give us some time to manually intervene and continue block
        Stop(pump,adrB)
        LCApp.ActiveDocument.AppendComment('B off',-1);
    else
        pause(mpf*60-fon)
    end
    
end



