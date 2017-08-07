classdef model_44 < sl.obj.display_class
    %
    %   Class:
    %   harvard.pump.model_44
    %
    %   Multiple Pumps
    %   -------------------------------------------------------------------
    %   Multiple pumps can be connected to the same serial connection. To 
    %   support this feature, a shared serial port instance would need to
    %   be passed to multiple instances of this class. This has not yet
    %   been fully flushed out and tested.
    %
    %   Improvements
    %   -------------
    %   1) Build a method that scans the addresses (use VER).
    %   2) Make a consistent error message for out of range so that
    %   we can try/catch on it. Perhaps even return whether or not
    %   the value was out of range as a variable and allow the user to not
    %   throw an error
    
    %{
        Demo Code
        ----------
        p = harvard.pump.model_44('COM4');
        p.setPumpDirection('infuse');
        p.setPumpMode('pump');
        p.setInfuseRate(1,'ml/min');	
        p.start();
        for i = 1:10
            pause(1)
            pumped_volume = p.volume_delivered_ml;
            fprintf('Volume Pumped: %g (ml)\n',pumped_volume);
        end
        p.stop();

    %}
    
    %{
        Questions
        ---------
        Q: How do we well if the pump is running?
        A: I think we need to extract from the prompt
        
    
    %}
    
    %{    
    %Model 44 Commands
    %-------------------------------------------
    
    <cr> => stop all pumps on the chain NYI
    
    x RUN
    x STP
    x DEL
    x CLD
    
    x RAT - infusion rate
    x RFR - refill rate
    x PGR
    x DIA -
    TGT - target volume setting NYI
    x MOD
    x DIR - pump direction
            INF - infusion
            REF - refill
            REV - reverse
    AF - autofill setting
    SYR - set or query volume setting (for Volume mode?)
    In - read TTL logic level
    Out - set TTL logicl level
    
    SEQ - sequences
    
    x VER
    
    %}
    
    
    properties (Hidden)
        s 	% serial port object data
        
        %BaudRate is selectable and could be something else
        %Other values are from Appendix F in the User Manual (PHD2000)
        serial_options = {...
            'BaudRate',NaN,...
            'DataBits',8,...
            'Parity','none',...
            'StopBits',2,...
            'Terminator',[]... %This is because the response is non-standard
            }
    end
    
    properties
        address
        pump_firmware_version
        pump_status_from_last_query
        %   
        %   - '1: infusing'
        %   - '2: refilling'
        %   - '3: stopped'
        %   - '4: paused'
        %   - '5: pumping interrupted'
        %   - '6: dispense trigger wait'
        %   - '7: unrecognized'
        %
        %   Note that grabbing the first char can identify
        %   the type. >= 3 is stopped
    end
    
    properties (Dependent)
        syringe_diameter_mm
        infuse_rate % {value,units}
        refill_rate %
        volume_delivered_ml
        current_rate %This is either:
        %1) 0
        %2) 'infuse_rate'
        %3) something else if a program is running
        
        %TODO: If we are using model_22 this will return
        %?, instead of a valid value
        current_mode
        %   PUMP - just keep pumping
        %   VOLUME - pump to a particular volume
        %   PROGRAM - run a program NYI
        
        
        current_direction
        %   INFUSE
        %   REFILL
        %
        
        %NYI
        %target_volume_ml
        %auto_fill
        %syringe_volume %- autofill
    end
    
    methods
        function value = get.syringe_diameter_mm(obj)
            response = obj.runQuery('DIA');
            value = str2double(response);
        end
        function value = get.infuse_rate(obj)
            response = obj.runQuery('RAT');
            value = h__extractFlowRate(response);
        end
        function value = get.refill_rate(obj)
            response = obj.runQuery('RFR');
            value = h__extractFlowRate(response);
        end
        function value = get.volume_delivered_ml(obj)
            response = obj.runQuery('DEL');
            value = str2double(response);
        end
        function value = get.current_rate(obj)
            response = obj.runQuery('PGR');
            value = h__extractFlowRate(response);
        end
        function value = get.current_mode(obj)
            temp = strtrim(obj.runQuery('MOD'));
            
            %TODO: Due to dependent displays, throwing an error does
            %nothing when displaying
            if strcmp(temp,'?')
                %fprintf(2,'Value returned suggests pump is not in model_44 mode')
                error('Pump is not in 44 mode')
            else
                value = temp;
            end
        end
        function value = get.current_direction(obj)
            value = strtrim(obj.runQuery('DIR'));
        end
    end
    
    properties
        %type = 'Harvard Apparatus PHD 4400';	% type of pump
        serial_delay = 0.2;                      % delay for all serial commands
        %unitsTable = {'UM' 'UH' 'MM' 'MH'};     % allowable units
    end
    
    methods
        function obj = model_44(input,varargin)
            % Create an object to control infusion pumps
            %
            %   obj = harvard.pump.model_44(port_name,varargin)
            %
            %   obj = harvard.pump.model_44(port_number,varargin)
            %
            %   NYI
            %   obj = harvard.pump.phd(serial_instance)
            %
            %   Inputs
            %   ------
            %   port_name : string
            %       Examples 'COM1', 'COM2'
            %   port_number : number
            %       Examples - 1,2,3
            %
            %   Optional Inputs
            %   ---------------
            %   address
            %   baud_rate
            %
            %   Example
            %   -------
            %   p = harvard.pump.model_44('COM4');
            %
            %   See Also
            %   --------
            %   harvard.utils.getCOMInfo
            %
            %   Improvements
            %   ------------
            %   1) Support numeric input for COM port_name
            
            in.address = 1;
            in.baud_rate = 19200;
            in = sl.in.processVarargin(in,varargin);
            
            obj.serial_options{2} = in.baud_rate;
            
            obj.address = in.address;
            
            h__initSerial(obj,input)
            
            obj.pump_firmware_version = strtrim(obj.runQuery('VER'));
            
        end
        function delete(obj)
            fclose(obj.s);
            delete(obj.s);
        end
    end
    
    methods
        function setInfuseRate(obj,rate,input_units)
            %x Change the infusion rate setting on the pump
            %
            %   setInfuseRate(obj,rate,*input_units)
            %
            %   Inputs
            %   ------
            %   rate : number
            %   input_units :
            %       - 'ml/hr'
            %       - 'ml/min' or 'ml/mn'
            %       - 'ul/hr'
            %       - 'ul/min' or 'ul/mn'
            %       The default behavior is to not change the current
            %       units.
            
            if nargin < 3
                units = '';
            else
                units = h__translateUnits(input_units);
            end
            
            cmd = sprintf('RAT %0.4f %s',rate,units);
            obj.runQuery(cmd);
        end
        function setRefillRate(obj,rate,input_units)
            %x Change the refill (withdraw) rate setting on the pump
            %
            %   setRefillRate(obj,rate,*input_units)
            %
            %   Inputs
            %   ------
            %   rate : number
            %   input_units :
            %       - 'ml/hr'
            %       - 'ml/min' or 'ml/mn'
            %       - 'ul/hr'
            %       - 'ul/min' or 'ul/mn'
            %       The default behavior is to not change the current
            %       units.
            
            if nargin < 3
                units = '';
            else
                units = h__translateUnits(input_units);
            end
            
            cmd = sprintf('RFR %0.4f %s',rate,units);
            obj.runQuery(cmd);
        end
        function start(obj)
            %x Start the pump
            obj.runQuery('RUN');
        end
        function stop(obj)
            %x Stop the pump
            obj.runQuery('STP');
        end
        function clearDeliveredVolume(obj)
            %x Clears the accumalator that tracks the delivered volume
            obj.runQuery('CLD');
        end
        function setSyringeDiameter(obj,diameter)
            %
            %   Units are in mm
            
            error('Not yet implemented')
        end
        function setTargetVolume(obj)
            error('Not yet implemented')
        end
        function setPumpMode(obj,mode)
            %x Sets the pump mode (pump, volume, program)
            %
            %   setPumpMode(obj,mode)
            %
            %   Inputs
            %   ------
            %   mode : 
            %       - 'pump'
            %       - 'volume'
            %       - 'program'
            
            switch lower(mode)
                case 'pump'
                    code = 'PMP';
                case 'volume'
                    code = 'VOL';
                case 'program'
                    code = 'PGM';
                otherwise
                    error('Unrecognized mode option: %s',mode);
            end
            
            cmd = ['MOD ' code];
            obj.runQuery(cmd);
        end
        function setPumpDirection(obj,direction)
            %x Set the pump direction (infuse, withdraw, reverse)
            %
            %   setPumpDirection(obj,direction)
            %
            %   Inputs
            %   ------
            %   direction : string
            %       - 'infuse','infusion','inf'
            %       - 'refill','withdraw','ref'
            %       - 'reverse','toggle' => reverses the current code
            
            switch lower(direction)
                case {'infuse','infusion','inf'}
                    code = 'INF';
                case {'refill','withdraw','ref'}
                    code = 'REF';
                case {'reverse','toggle'}
                    code = 'REV';
                otherwise
                    error('Unrecognized direction option: %s',direction);
            end
            
            cmd = ['DIR ' code];
            obj.runQuery(cmd);
        end
        function readPinLevel(obj)
            %x Read level (on or off) of a pin on the I/O connector
            error('Not yet implemented')
        end
        function setPinLevel(obj)
            %x Turn on or off a pin I/O connector
            error('Not yet implemented')
        end
    end
    
    methods (Hidden)
        function flush(obj)
            %Normally not needed ... should only be during debugging
            %when I am creating errors ...
            flushinput(obj.s)
        end
        function response = runQuery(obj,cmd)
            %
            
            CR = char(13);
            LF = char(10);
            
            s2 = obj.s;
            full_cmd = sprintf('%d %s \r',obj.address,cmd);
            fprintf(s2,full_cmd);

            %Model 44
            %<lf><text><cr> - 1 or more lines
            %<lf> 1 or 2 digit address, prompt char => e.g. 1:
            %  :  pump stopped
            %  >  pump infusing
            %  <  pump refilling
            %  /  pause interval, pump stopped
            %  *  pumping interrupted (pump stopped)
            %  ^  dispense trigger wait (pump stopped)
            
            %OPTIONS
            %-----------------------
            PAUSE_DURATION = 0.005;
            MAX_INITIAL_WAIT_TIME = 2;
            MAX_READ_TIME = 5;
            
            %Error Codes
            %----------------------
            %<lf>,space,space,<message><cr>
            %   where message is 1 of:
            %   ? - syntax error
            %   NA - command not applicable at this time
            %   OOR - control data is out of the operating range of the
            %   pump
            
            ERROR_1 = [LF '  ?' CR];
            ERROR_2 = [LF '  NA' CR];
            ERROR_3 = [LF '  OOR' CR];
            
            %TODO: Why aren't these hidden
            %             obj.addlistener
            %             obj.delete
            %             obj.findobj
            %             obj.findprop
            
            %Note, don't include CR because some responses are only the
            %end of message indicator
            END_OF_MSG_START = sprintf('%s%d',LF,obj.address);
            n_chars_back = length(END_OF_MSG_START);
            
            %Wait until we get something
            %----------------------------------
            i = 0;
            while s2.BytesAvailable == 0
                pause(PAUSE_DURATION);
                i = i + 1;
                if PAUSE_DURATION*i > MAX_INITIAL_WAIT_TIME
                    %This can occur if:
                    %1) The baud rate is incorrect
                    %2) Multiple commands are sent to the device
                    %without appropriate blocking
                    %3) The pump is currently in a menu :/
                    %4) Pump gets turned off
                    error('Something wrong happened')
                end
            end
            
            %Read the response
            %-----------------------------------
            t1 = tic;
            response = [];
            done = false;
            while ~done
                
                if obj.s.BytesAvailable
                    response = [response fscanf(obj.s,'%c',obj.s.BytesAvailable)]; %#ok<AGROW>
                    
                    %Expecting Model 44 - model 22 starts with CR ...
                    if response(1) == LF
                        switch response(end)
                            case {':' '>' '<' '/' '*' '^'}
                                if length(response) >= n_chars_back + 1 && ...
                                        strcmp(response(end-n_chars_back:end-1),END_OF_MSG_START)
                                    
                                    %  :  pump stopped
                                    %  >  pump infusing
                                    %  <  pump refilling
                                    %  /  pause interval, pump stopped
                                    %  *  pumping interrupted (pump stopped)
                                    %  ^  dispense trigger wait (pump stopped)
                                    last_char = response(end);
                                    response = response(1:end-n_chars_back-1);
                                    
                                    switch response
                                        case ERROR_1
                                            error('Syntax error for cmd: "%s"',full_cmd)
                                        case ERROR_2
                                            error('Command not applicable at this time')
                                        case ERROR_3
                                            error('Control data out of range for this pump')
                                    end

                                    %YUCK :/
                                    %--------------------------------------
                                    switch last_char
                                        case ':'
                                            ps = '3: stopped'; %ps => Pump Status
                                        case '>'
                                            ps = '1: infusing';
                                        case '<'
                                            ps = '2: refilling';
                                        case '/'
                                            ps = '4: paused';
                                        case '*'
                                            ps = '5: pumping interrupted';
                                        case '^'
                                            ps = '6: dispense trigger wait';
                                        otherwise
                                            ps = '7: unrecognized';
                                            
                                    end
                                    obj.pump_status_from_last_query = ps;
                                    
                                    done = true;
                                end
                            case CR
                                %I don't think this ever runs ...
                                %It is unclear whether or not
                                switch response
                                    case ERROR_1
                                        error('Syntax error')
                                    case ERROR_2
                                        error('Command not applicable at this time')
                                    case ERROR_3
                                        error('Control data out of range for this pump')
                                    otherwise
                                        %Keep reading ...
                                end
                            otherwise
                                %Here we need to read more ...
                                %Keep going
                        end
                    else
                        error('Unexpected first character')
                    end
                else
                    pause(PAUSE_DURATION);
                end
                
                if (~done && toc(t1) > MAX_READ_TIME)
                    error('Response timed out')
                end
            end
        end
    end
    
end

function h__initSerial(obj,input,in)

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
        fprintf(2,'You may use "delete(instrfindall)" to clear all serial ports\n')
        error('Requested serial port: %s is in use',port_name);
    else
        fprintf(2,'-----------------------------\n');
        fprintf(2,'Requested serial port: %s was not found\n',port_name)
        fprintf(2,'Available ports:\n')
        sp = serial_info.SerialPorts;
        for i = 1:length(sp)
            fprintf(2,'%s\n',sp{i})
        end
        fprintf(2,'-------------------------\n')
        error('See above for error info');
    end
end
obj.s = serial(port_name);



set(obj.s,obj.serial_options{:});
fopen(obj.s);

end

function units = h__translateUnits(input_units)
switch input_units
    case 'ml/hr'
        units = 'MH';
    case {'ml/mn' 'ml/min'}
        units = 'MM';
    case 'ul/hr'
        units = 'UH';
    case {'ul/mn' 'ul/min'}
        units = 'UM';
    otherwise
        error('Unrecognized units option')
end
end

function value = h__extractFlowRate(response)
%%Example Response:  0.1644 ml/hr
value = regexp(response,'(\d+\.\d*) ([^\s]+)','tokens','once');
value{1} = str2double(value{1});
end