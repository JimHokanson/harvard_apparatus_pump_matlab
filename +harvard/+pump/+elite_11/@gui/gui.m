classdef gui < handle
    %
    %   Class:
    %   harvard.pump.elite_11.gui
    %
    %   Improvements
    %   ------------
    %   1) Remove sl dependencies, see get path
    
    
    %{
        harvard.pump.elite_11.gui.run('COM3')
    %}
    
    properties
        h %h => handles
        pump
        is_pumping = false
        address
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
            
            in.address = 1;
            in.baud_rate = 115200;
            in = harvard.sl.in.processVarargin(in,varargin);
            
            if nargin == 0 || isempty(com)
               com = h__getDefaultCOM(); 
            end
            
            %Loading the AppDesigner GUI
            obj.h = harvard.pump.elite_11.elite11_gui();
            
            %Units -------------
            obj.h.units.Items = {'ml/hr';'ml/min';'ul/hr';'ul/min'};
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
        
            obj.pump = harvard.pump.elite_11(com,...
                'address',in.address,...
                'baud_rate',in.baud_rate);
            obj.address = in.address; %for file naming
            
            obj.loadFromDisk();
            %loadFromDisk(obj) %works, but don't do this
            %
        end
        function loadFromDisk(obj)
            
            file_path = obj.getSavePath();
            if exist(file_path,'file')
                h2 = load(file_path);
                s = h2.s;
                obj.h.fill_rate.Value = s.fill_rate;
                %TODO: put units here
            else
                obj.h.fill_rate.Value = '5';
            end
        end
        function saveToDisk(obj)
            file_path = obj.getSavePath();
            s = struct;
            s.fill_rate = obj.h.fill_rate.Value;
            save(file_path,'s');
        end
        function file_path = getSavePath(obj)
            package_root = sl.stack.getPackageRoot();
            save_root = sl.dir.createFolderIfNoExist(package_root,'temp_data','elite11');
            file_name = sprintf('gui_data_%02d.mat',obj.address);
            file_path = fullfile(save_root,file_name);
        end
    end
    
    %Pump Interface Commands
    methods
        function startPump(obj)
            obj.is_pumping = true;
            obj.setFillRate();
            obj.h.stop_pump.Visible = 'On';
            obj.h.start_pump.Visible = 'Off';
            obj.pump.start();
        end
        function stopPump(obj)
            obj.is_pumping = false;
            obj.h.stop_pump.Visible = 'Off';
            obj.h.start_pump.Visible = 'On';
            obj.pump.stop();
        end
        function setFillRate(obj)
            fill_rate = str2double(obj.h.fill_rate.Value);
            units = obj.h.units.Value;
            obj.pump.setInfuseRate(fill_rate,units)
        end
    end
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

