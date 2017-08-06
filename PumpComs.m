classdef PumpComs
    properties
        s                                       % serial port object data
        type = 'Harvard Apparatus PHD 4400';	% type of pump
        serialDelay = 0.2;                      % delay for all serial commands
        unitsTable = {'UM' 'UH' 'MM' 'MH'};     % allowable units
    end
    
    methods
        function obj = PumpComs(portName)
            % Create an object to control infusion pumps
            
            % check to see if requests serial port exists
            serialInfo = instrhwinfo('serial');
            if ~any(strcmp(serialInfo.AvailableSerialPorts,portName))
                error(['Serial port ' portName ' not found.'])
            end
            obj.s = serial(portName);
            set(obj.s,'BaudRate',9600,'DataBits',8,...
                'Parity','none','StopBits',2,'Terminator',[]);
            fopen(obj.s);
        end
        
        function q = FlowRate(obj,varargin)
            % Set or check flow rates
            % q = FlowRate(obj,rate,units)           % set infuse rate
            % q = FlowRate(obj)                      % check infuse rate
            % q = FlowRate(obj,pumpAdress,rate,units)
            % q = FlowRate(obj,pumpAdress)
            % q = FlowRate(obj,...,'Refill')        % set/check refill rate
            % See DispUnitFormat for proper units input
            
            % check the pump direction first - if the last entry is
            % 'refill' we need issue the refil command, otherwise we issue
            % the infusion commands
            if ~isempty(varargin) && strcmpi(varargin{end},'Refill')
                optInputs = varargin(1:end-1);
                flowDir = 'RFR';
            else
                optInputs = varargin;
                flowDir = 'RAT';
            end
            
            % 4 conditions with set/get, adress/no address
            numOptArgIn = length(optInputs);
            
            % check the flow rate
            if numOptArgIn==0 || numOptArgIn==1
                if numOptArgIn==0
                    adr = 0;
                else
                    adr = optInputs{1};
                end
                
                fprintf(obj.s,[num2str(adr) ' ' flowDir char(13)]);
                pause(obj.serialDelay)
                out = ReadAvailableBytes(obj);
                % parse response
                q = regexp(out,'\d+\.\d+ (ml|ul)/(mn|hr)','match');
                % disp(out) % uncomment for debugging
                
            % set the flow rate
            elseif numOptArgIn==2 || numOptArgIn==3
                if numOptArgIn==2
                    adr = 0;
                    [rate, units] = deal(optInputs{:});
                else
                    [adr, rate, units] = deal(optInputs{:});
                end
                
                
                if ~any(strcmp(obj.unitsTable,units))
                    error(['Invalid units. Acceptable are: ' sprintf('%s ',obj.unitsTable{:})])
                end
                % the rate must have only 5-digits (with leading 0) to be valid for these pumps
                rate5d = round(rate*10^4)/10^4;
                fprintf(obj.s,[num2str(adr) ' ' flowDir ' ' num2str(rate5d,5) ' ' units char(13)]);
                q = {};
            
            % errors    
            else
                error('Invalid number of inputs.')
            end
            
            % give time for serial commands to be processed
            pause(obj.serialDelay)
        end
        
        
        function Start(obj,adr)
            % Start(obj)
            % Start(obj,pumpAdress)
            % start the pump
            if nargin==1, adr = 0; end
            
            fprintf(obj.s,[num2str(adr) ' RUN' char(13)]);
            pause(obj.serialDelay)
        end
        
        function Stop(obj,adr)
            % Stop(obj)
            % Stop(obj,pumpAdress)
            % stop the pump
            if nargin==1, adr = 0; end
            
            fprintf(obj.s,[num2str(adr) ' STP' char(13)]);
            pause(obj.serialDelay)
        end
        
        function q = GetPumpDirection(obj,adr)
            % GetPumpDirection(obj)
            % GetPumpDirection(obj,pumpAdress)
            % Get Pump Direction
            if nargin==1, adr = 0; end
            
            fprintf(obj.s,[num2str(adr) ' DIR' char(13)]);
            pause(obj.serialDelay)
            out = ReadAvailableBytes(obj);
            % parse response
            q = regexp(out,'(INFUSE|REFILL)','match');
        end
        
        function SetPumpDirection(obj,varargin)
            % set the direction of the pump
            % SetPumpDirection(obj,direction)
            % SetPumpDirection(obj,pumpAdress,direction)
            % direction is a string that is either 'INF' for infusion,
            % 'REF' for refill or 'REV' for reverse the current flow
            % direciton
            if length(varargin)==1
                pdir = varargin{1};
                adr = 0;
            elseif length(varargin)==2
                [adr, pdir] = deal(varargin{:});
            else
                error('Expecting 1 or 2 arguments to follow the pump object')
            end
            
            if ~any(strcmp({'INF' 'REF' 'REV'},pdir))
                error('Acceptable directions are INF, REF, or REV')
            end
            
            fprintf(obj.s,[num2str(adr) ' DIR ' pdir char(13)]);
            pause(obj.serialDelay)
        end
        
        function ClearVolume(obj,adr)
            % ClearVolume(obj)
            % ClearVolume(obj,pumpAdress)
            % Clear accumulated pump volume
            if nargin==1, adr = 0; end
            
            fprintf(obj.s,[num2str(adr) ' CLD' char(13)]);
            pause(obj.serialDelay)
        end
        
        function DU = DispUnitFormat(obj)
            % Display format for units
            % DU = DispUnitFormat(obj)
            
            DU = [obj.unitsTable; ...
                {'ul/min'  'ul/hr' 'ml/min' 'ml/hr'}];
            disp(DU)
        end
        
        function out = ReadAvailableBytes(obj)
            % Get all available bytes from the buffer
            n = obj.s.BytesAvailable;
            if n==0
                out = {};
            else
                out = fscanf(obj.s,'%c',n);
            end
            pause(obj.serialDelay)
        end
        
        function q = ttlRead(obj,varargin)
            % Read the logic level (on/off) from a given pin
            % q = ttlRead(obj,pin)
            % q = ttlRead(obj,pumpAdress,pin)
            
            % 2 conditions with adress/no address
            numOptArgIn = length(varargin);
            if numOptArgIn == 1
                adr = 0;
                pin = varargin{1};
            else
                adr = varargin{1};
                pin = varargin{2};
            end
            
            if ~any(pin==[6 7 8 9])
                error('Allowed reading pins are 6, 7, 8, or 9.')
            end
            fprintf(obj.s,[num2str(adr) ' IN ' num2str(pin) char(13)]);
            out = ReadAvailableBytes(obj);
            % parse response
            q = regexp(out,'(ON|OFF)','match');
            pause(obj.serialDelay)
        end
        
        function ttlSet(obj,varargin)
            % Set the the logic level of the TTL output pin 4 (ON/OFF)
            % ttlSet(obj,level)
            % ttlSet(obj,pumpAddress,level)
            
            % 2 conditions with adress/no address
            numOptArgIn = length(varargin);
            if numOptArgIn == 1
                adr = 0;
                level = varargin{1};
            else
                adr = varargin{1};
                level = varargin{2};
            end
            
            if ~any(strcmp(level,{'ON' 'OFF'}))
                error('level must be "ON" or "OFF"')
            end
            fprintf(obj.s,[num2str(adr) ' OUT 4 = ' level char(13)]);
            pause(obj.serialDelay)
        end
        
        function TerminateComs(obj)
            % close pump serial object
            fclose(obj.s);
            disp('Port closed.')
        end
        
        function OpenComs(obj)
            % initiate serial communications with pump
            if strcmp(obj.s.Status,'open')
                warning('Serial communication already opened.')
            else
                fopen(obj.s);
                disp('Port opened.')
            end
        end
        
        function delete(obj)
            % delete pump serial communication object
            pn = obj.s.Port;
            
            fclose(obj.s);
            delete(obj.s);
            
            disp([pn ' closed.'])
        end
    end
    
end
