classdef phd < sl.obj.display_class
    %
    %   Class:
    %   harvard.pump.phd
    
    %   Multiple pumps can be connected to the same serial connection :/
    %
    %   If we wanted to build multiple pump support, we would add an 
    %   'address' property and share the serial port instance ...
    %
    
    %TODO
    %-------------------------
    %Build in pump scan operation
    %VER for all
    
    
    %User Manual Notes
    %---------------------------
    %PG50 - Appendix F: RS-232 Specifications
    
    %{
    Pump Port 1 � Computer control side
    Pump Port 2 � Connection for remainder
    of pump chain
    Baud Rate � 1200, 2400, 9600 or 19,200
    Word Size � 8
    Parity � none
    Stop Bits � 2
    
    %}
    
    %{
    Set => 1 => then press 1 to toggle between Model 22 or Model 44
    protocol => enter
    
    Set => RS-232 => RS-232 to toggle if necessary => enter =>
    select address on keypad 00 - 99 - enter - select baud rate (how?) - enter
    
    
    
    
    %}
    
    %{
    There are apparently two sets of commmands
    %Model 22
    %Model 44
    
    Starting on Page 35 in the PHD2000 manual
    
    Commands
    --------
    RUN - infuse (forward direction)
    REV - Start (reverse direction)
    STP - Stop
    CLV - Clear volume accumulator to zero
    CLT - Clear target volume to zero
    MLM - Set rate, units are mmillitiers per minute
    ULM - Set rate, units are microliters per minute
    MLH - Set rate, units are milliliters per hour
    ULH - Set rate, units are mmicroliters per hour
    MMD - Set diameter, units are mm, Rate is set to 0
    MLT - Set target infusion volume, units are ml
    
    Queries
    -------
    DIA - Send diameter value, units are in mm
    RAT - 
    VOL
    TAR
    VER
    
    %Model 44 Commands
    <cr> => stop all pumps on the chain
    pump address, <cr>
    
    
    %}
    
    
    properties (Hidden)
        s 	% serial port object data
        
        %BaudRate is selectable and could be something else
        %Other values are from Appendix F in the User Manual (PHD2000)
        SERIAL_OPTIONS = {...
            'BaudRate',9600,...
            'DataBits',8,...
            'Parity','none',...
            'StopBits',2,...
            'Terminator',[]... %This is because the response is non-standard
            }
    end
    
    properties
       address = 1; 
    end
    
    properties (Dependent)
       flow_rate 
    end
    
    methods
        function value = get.flow_rate(obj)
            response = obj.runQuery('RAT');
            %TODO: We need to parse this ...
            value = response;
        end
    end
    
    properties
        %type = 'Harvard Apparatus PHD 4400';	% type of pump
        serial_delay = 0.2;                      % delay for all serial commands
        %unitsTable = {'UM' 'UH' 'MM' 'MH'};     % allowable units
    end
        
    methods
        function obj = phd(input)
            % Create an object to control infusion pumps
            %
            %   obj = harvard.pump.phd(port_name)
            %
            %   obj = harvard.pump.phd(port_number)
            %
            %   NYI
            %   obj = harvard.pump.phd(serial_instance)
            %
            %   Inputs
            %   ------
            %   port_name : string
            %       Examples 'COM1' or 'COM2'
            %
            %
            %   Example
            %   -------
            %   p = harvard.pump.phd('COM3');
            %
            %   See Also
            %   --------
            %   harvard.utils.getCOMInfo
            %
            %   Improvements
            %   ------------
            %   1) Support numeric input for COM port_name

            h__initSerial(obj,input)
            
        end
     	function delete(obj)
            % delete pump serial communication object
            pn = obj.s.Port;
            
            fclose(obj.s);
            delete(obj.s);
            
            %disp([pn ' closed.'])
            
            %Deleting everything
            %delete(instrfindall)
        end
    end
    
    methods        
        
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
        
%         function OpenComs(obj)
%             % initiate serial communications with pump
%             if strcmp(obj.s.Status,'open')
%                 warning('Serial communication already opened.')
%             else
%                 fopen(obj.s);
%                 disp('Port opened.')
%             end
%         end
    end
    
    methods (Hidden)
        function response = runQuery(obj,cmd)
            %
            
          	CR = char(13);
            LF = char(10);
            
            s2 = obj.s;
            full_cmd = sprintf('%d %s \r',obj.address,cmd);
            fprintf(s2,full_cmd);
            
            
            %Unfortunately the response types differ between
            %Model 22 and Model 44
            %
            %Note, PHD2000 supports both types ...
            %
            %Model 22
            %response is CR LF Value CR LF Prompt
            %   Prompt:
            %   : stopped
            %   > When running forward
            %   < When running reverse
            %   * When stalled
            %
            %
            %Model 44
            %<lf><text><cr> - 1 or more lines
            %<lf> 1 or 2 digit address, prompt char => e.g. 1:
            %  :  pump stopped
            %  >  pump infusing
            %  <  pump refilling
            %  /  pause interval, pump stopped
            %  *  pumping interrupted (pump stopped)
            %  ^  dispense trigger wait (pump stopped)
            %
            %   Note that the first char is different between the two
            %   so after the first char, we know what we are looking for
            %   ...
            
            %Error Codes
            %-----------
            %Model 22
            %
            %
            %Model 44
            %<lf>,space,space,<message><cr>
            %   where message is 1 of:
            %   ? - syntax error
            %   NA - command not applicable at this time
            %   OOR - control data is out of the operating range of the
            %   pump
            
            
            i = 0;
            while s2.BytesAvailable == 0
                pause(0.02);
                i = i + 1;
                %Wait 2 seconds ...
                if 0.02*i > 2
                    error('Something wrong happened')
                end
            end
            
            response = [];
            done = false;
            while ~done
                if obj.s.BytesAvailable
                    response = [response fscanf(obj.s,'%c',obj.s.BytesAvailable)];

                    %TODO: Write model44 and model22 classes

                    %Are we done?
                    if response(1) == LF
                        switch response(end)
                            case {':' '>' '<' '/' '*' '^'}
                                %TODO: Ideally we would reparse the address
                                %All done
                                done = true;
                            case CR
                                %TODO: Have to look for exact errors :/
                                %?
                                %NA
                                %OOR
                                
                                %We might need to keep going ...
                                %Back track ...
                                error(response)
                            otherwise
                                %Here we need to read more ...
                                %Keep going
                                %error('Unsupported case')

                     %  :  pump stopped
                    %  >  pump infusing
                    %  <  pump refilling
                    %  /  pause interval, pump stopped
                    %  *  pumping interrupted (pump stopped)
                    %  ^  dispense trigger wait (pump stopped)
                        end
                    else
                        error('Unexpected first character')
                    end
                else
                    pause(0.02);
                end
            end
            
            response
%             pause(obj.serial_delay)
%             n = obj.s.BytesAvailable;
%             
%             %TODO: Hopefully this is everything :/
%             if n
%                response = [response fscanf(obj.s,'%c',n)];
%             end
            
            %This approach is on hold for now ...
            %==============================================================
% % %             str = char(32*ones(1,100));
% % %             
% % %             CR = char(13);
% % %             LF = char(10);
% % %             
% % %             keyboard
% % %             
% % %             
% % %             %Response Mode 
% % %             
% % %             tic
% % %             I = 0;
% % %             i = 0;
% % %             done = false;
% % %             while ~done
% % %                 i = i + 1;
% % %                 n = s2.BytesAvailable; 
% % %                 if n  > 0
% % %                     str(I+1:I+n) = fscanf(s2,'%c',n);
% % %                     I = I + n;
% % %                     done = i > 1e6 || (I > 2 && str(I-2) == CR && str(I-1) == LF);
% % %                 end
% % %             end
% % %             
% % %             if i > 1e6
% % %                 error('Something wrong happpened')
% % %             end
% % %             
% % %             response = str(1:I);
% % %             toc
            %==============================================================

        end
    end
    
end

function h__initSerial(obj,input)

if ischar(input)
    port_name = input;
elseif isnumeric(input)
    port_name = sprintf('COM%d',input);
else
    %We could make this 
    error('Unexpected input')
end
    
% check to see if requests serial port exists
serial_info = instrhwinfo('serial');

if ~any(strcmp(serial_info.AvailableSerialPorts,port_name))
    if any(strcmp(serial_info.SerialPorts,port_name))
        %delete(instrfindall) will delete everything in Matlab
        error('Requested serial port: %s is in use',port_name);
    else
        error('Requested serial port: %s was not found',port_name);
    end
end
obj.s = serial(port_name);



set(obj.s,obj.SERIAL_OPTIONS{:});
fopen(obj.s);

end