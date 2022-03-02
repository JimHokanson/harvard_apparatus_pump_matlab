classdef gui < handle
    %
    %   Class:
    %   harvard.pump.elite_11.gui
    %
    %   Improvements
    %   ------------
    %   1) Remove sl dependencies, see get path
    %
    %   See Also
    %   --------
    %   harvard.pump.elite_11
    
    
    %{
        harvard.pump.elite_11.gui.run('COM1','clear_volume_on_start',true)
    %}
    
    %Handles List
    %------------
    %                   UIFigure: [1×1 Figure]
    %               clear_volume: [1×1 Button]
    %                    display: [1×1 TextArea]
    %                 stop_flush: [1×1 Button]
    %                start_flush: [1×1 Button]
    %                 flush_rate: [1×1 DropDown]
    %     FlushRateDropDownLabel: [1×1 Label]
    %                  stop_pump: [1×1 Button]
    %                 start_pump: [1×1 Button]
    %                      units: [1×1 DropDown]
    %         UnitsDropDownLabel: [1×1 Label]
    %                  fill_rate: [1×1 EditField]
    %     FillRateEditFieldLabel: [1×1 Label]
    
    
    events
        pre_start_pump
        post_start_pump
        pre_stop_pump
        post_stop_pump
        pre_start_flush
        post_start_flush
        pre_stop_flush
        post_stop_flush
    end
    
    properties
        %This defaults to nothing. It is specified by user. Does not
        %impact the pump operation, but we do save properties based
        %on this name (if specified)
        name
        h %h => handles
        pump  %harvard.pump.elite_11
        is_pumping = false
        is_flushing = false
        clear_volume_on_start
        address
        post_start_callback
        timer
        display_strings
    end
    
    
    
    methods (Static)
        function run(com,varargin)
            %   harvard.pump.elite_11.gui.run()
            obj = harvard.pump.elite_11.gui(com,varargin{:});
        end
    end
    
    methods
        function obj = gui(com,varargin)
            %
            %   obj = harvard.pump.elite_11.gui(com,varargin)
            %
            %   Inputs
            %   ------
            %   com :
            %       e.g. 'COM3'
            %
            %   Optional Inputs
            %   ---------------
            %   address : default 1
            %   baud_rate : default 115200
            %
            %   Example
            %   --------
            %   obj = harvard.pump.elite_11.gui('COM3','address',2)
            
            %TODO: Switch from callbacks to listeners
            %https://www.mathworks.com/help/matlab/ref/handle.notify.html
            
            in.name = -1;
            in.address = 1;
            in.baud_rate = 115200;
            in.clear_volume_on_start = false;
            in = harvard.sl.in.processVarargin(in,varargin);
            
            if nargin == 0 || isempty(com)
                com = h__getDefaultCOM();
            end
            
            obj.clear_volume_on_start = in.clear_volume_on_start;
            
            %Loading the AppDesigner GUI
            obj.h = harvard.pump.elite_11.elite11_gui();
            obj.h.UIFigure.CloseRequestFcn = @(~,~)h__closeFigure(obj);
            
            if ischar(in.name)
                obj.h.UIFigure.Name = in.name;
                obj.name = in.name;
            else
                obj.name = '';
            end
            
            %Units -------------
            obj.h.units.Items = {'ml/hr';'ml/min';'ul/hr';'ul/min'};
            obj.h.flush_rate.Items = {'5ml/min';'10ml/min';'15ml/min';'20ml/min'};
            obj.h.flush_rate.ItemsData=[5 10 15 20];
            %callback? - none needed, set fill rate when pumping
            %- load from disk below
            
            %Fill Value ------
            %- load from disk below
            %TODO: Eventually we might want some rate checking on what
            %is valid - VERY LOW PRIORITY
            obj.h.fill_rate.ValueChangedFcn = @(~,~)obj.saveToDisk();
            
            %Start/Stop Pump Button --------------------
            obj.h.stop_pump.Position = obj.h.start_pump.Position;
            obj.h.stop_pump.Visible = 'Off';
            obj.h.stop_pump.ButtonPushedFcn = @(~,~)obj.stopPump();
            obj.h.start_pump.ButtonPushedFcn = @(~,~)obj.startPump();
            
            %Start/Stop Flushing Button --------------------
            obj.h.stop_flush.Position = obj.h.start_flush.Position;
            obj.h.stop_flush.Visible = 'Off';
            obj.h.stop_flush.ButtonPushedFcn = @(~,~)obj.stopflush();
            obj.h.start_flush.ButtonPushedFcn = @(~,~)obj.startflush();
            
            %Clear Infused Volume Button --------------------
            obj.h.clear_volume.ButtonPushedFcn=@(~,~)obj.clearVolume();
            %             +(~,~)obj.updateDisplay();
            
            %Timer --------------------
            obj.timer =timer();
            obj.timer.ExecutionMode='fixedRate';
            obj.timer.Period=0.5;
            obj.timer.TimerFcn=@(~,~)obj.updateDisplay();
            start(obj.timer);
            
            obj.pump = harvard.pump.elite_11(com,...
                'address',in.address,...
                'baud_rate',in.baud_rate);
            obj.address = in.address; %for file naming
            
            obj.loadFromDisk();
            %loadFromDisk(obj) %works, but don't do this
            
            
        end
        function delete(obj)
            obj.pump = [];
            if ~isempty(obj.timer)
                stop(obj.timer);
                delete(obj.timer);
            end
        end
        function loadFromDisk(obj)
            file_path = obj.getSavePath();
            if exist(file_path,'file')
                h2 = load(file_path);
                s = h2.s;
                obj.h.fill_rate.Value = s.fill_rate;
                obj.h.units.Value = s.fill_units;
            else
                obj.h.fill_rate.Value = '5';
            end
        end
        function saveToDisk(obj)
            file_path = obj.getSavePath();
            s = struct;
            s.fill_rate = obj.h.fill_rate.Value;
            s.fill_units = obj.h.units.Value;
            save(file_path,'s');
        end
        function file_path = getSavePath(obj)
            package_root = harvard.sl.stack.getPackageRoot();
            save_root = harvard.sl.dir.createFolderIfNoExist(package_root,'temp_data','elite11');
            if ~isempty(obj.name)
                file_name = sprintf('gui_data_%s.mat',obj.name);
            else
                file_name = sprintf('gui_data_%02d.mat',obj.address);
            end
            file_path = fullfile(save_root,file_name);
        end
    end
    
    %Pump Interface Commands
    methods
        function setFillRate(obj)
            fill_rate = str2double(obj.h.fill_rate.Value);
            units = obj.h.units.Value;
            obj.pump.setInfuseRate(fill_rate,units)
        end
        function startPump(obj)
            obj.is_pumping = true;
            obj.setFillRate();
            obj.h.stop_pump.Visible = 'On';
            obj.h.start_pump.Visible = 'Off';
            %TODO: implement clear_volume_on_start
            %             if obj.clear_volume_on_start
            %                %Clear the infused volume counter
            %             end
            
            notify(obj,'pre_start_pump');
            obj.pump.start();
            notify(obj,'post_start_pump');
        end
        
        function stopPump(obj)
            obj.is_pumping = false;
            obj.h.stop_pump.Visible = 'Off';
            obj.h.start_pump.Visible = 'On';
            
            notify(obj,'pre_stop_pump');
            obj.pump.stop();
            notify(obj,'post_stop_pump');
        end
        
        %         if obj.is_pumping == true;
        %             notify(obj,'start_pump');
        %         else
        %             notify(obj,'stop_pump');
        %         end
        
        function setFlushRate(obj)
            flush_rate = obj.h.flush_rate.Value;
            obj.pump.setInfuseRate(flush_rate,'ml/min');
        end
        function startflush(obj)
            obj.is_flushing = true;
            obj.setFlushRate();
            obj.h.stop_flush.Visible = 'On';
            obj.h.start_flush.Visible = 'Off';
            %             disp('starting pump')
            notify(obj,'pre_start_flush');
            obj.pump.start();
            notify(obj,'post_start_flush');
        end
        function stopflush(obj)
            obj.is_flushing = false;
            obj.h.stop_flush.Visible = 'Off';
            obj.h.start_flush.Visible = 'On';
            %             disp('stopping pump')
            notify(obj,'pre_stop_flush');
            obj.pump.stop();
            notify(obj,'post_stop_flush');
            %             disp('pump stopped')
        end
        %         function startTimer(obj)
        %             start(obj.timer);
        %         end
        %         function stopTimer(obj)
        %             stop(obj.timer);
        %          end
        
        function updateDisplay(obj)
            try
                obj.display_strings = cell(1,2);
                
                current_rate = obj.pump.current_rate;
                volume = obj.pump.volume_delivered_ml;
                %current_rate: {numeric_value,units_string}
                
                obj.display_strings{1} = sprintf('Current Rate: %g (%s)',current_rate{1},current_rate{2});
                obj.display_strings{2} = sprintf('Infused Volume: %g (%s)',volume{1},volume{2});
                
% %                 %['Current Rate:',num2str(obj.pump.current_rate{1}),obj.pump.current_rate{2}]
% %                 obj.display_strings{1} = strcat('Current Rate:',num2str(obj.pump.current_rate{1}),obj.pump.current_rate{2});
% %                 obj.display_strings{2} = strcat('Infused Volume:',obj.pump.volume_delivered_ml);
                obj.h.display.Value = sprintf('%s\n%s',obj.display_strings{1},obj.display_strings{2});
            end
        end
        function clearVolume(obj)
            obj.pump.clearDeliveredVolume();
        end
    end
end

function h__closeFigure(obj)
delete(obj.h.UIFigure);
delete(obj)
end

function com_port_use = h__getDefaultCOM()
serial_info = instrhwinfo('serial');

%This is for when no COM port is detected (which should never happen)
%or for when multiple ports are detected ...

%===============================================
%            ***** EDIT HERE *******
%===============================================
DEFAULT_COM_PORT_TO_USE = 'COM3';

com_ports = serial_info.SerialPorts;

if length(com_ports) == 1
    com_port_use = com_ports{1};
else
    com_port_use = DEFAULT_COM_PORT_TO_USE;
end

end

