classdef model_44_gui < handle
    %
    %   Class:
    %   harvard.pump.model_44_gui
    %
    %   This GUI was created very hastily with little testing and poor 
    %   overall design. It works ok but ideally it would be fixed up a bit.
    %
    %   Improvements
    %   ------------
    %   1) Provide popup for editing infuse rate to clean up main panel
    %   2) Right click menu on display to clear pumped volume
    %   3) Allow disabling the GUI so that the pump isn't locked ...
    %   4) On error, update the GUI to indicate that it is invalid
    %   5) DONE On closing the GUI, delete the object ...
    %   6) Allow callbacks
    
    
    properties
        fig_handle
        h %handles in figure
        p %pump handle
        is_running
        timer
        instruction = 0
    end
    
    methods
        function obj = model_44_gui(p)
            %
            %   obj = harvard.pump.model_44_gui(p);
            
            %TODO: Support saving GUI options to disk and reloading on
            %startup
            
            %obj.button_names = {'Launch File Processor','Launch Experiment Viewer'};
            
            %TODO: We might want to update this for function calls
            PAUSE_TIME_BETWEEN_READS = 0.20;
            
            obj.p = p;
            
            gui_path = fullfile(harvard.sl.stack.getMyBasePath,'model_44_gui.fig');
            obj.fig_handle = openfig(gui_path);
            obj.h = guihandles(obj.fig_handle);
            setappdata(obj.fig_handle,'obj',obj);
            
            %If the figure closes, delete the object
            set(obj.fig_handle,'CloseRequestFcn',@(~,~)h__closeFigure(obj));
            
            %Buttons
            %----------------------------
            %clear_volume
            set(obj.h.button_clear_volume,'Callback',@(~,~)obj.cb_clearVolume);
            
            %Start/Stop
            set(obj.h.button_start_stop,'Callback',@(~,~)obj.cb_startStop);
            
            %Set Infuse Rate
            set(obj.h.button_set_infuse_rate,'Callback',@(~,~)obj.cb_setInfuseRate);
            
            %Display Initiatialization
            %------------------------------
            temp = p.infuse_rate;
            set(obj.h.etext_infuse_rate_current_value,'String',sprintf('%0.4f %s',temp{1},temp{2}));
            
            set(obj.h.check_clear_volume,'Value',1);
            
            %TODO: Initialize the value of the menu selection based onthis
%             switch temp{2}
%                 case 'ul/hr'
%                 case 'ul/mn'
%                 case 'ml/hr'
%                 case 'ml/mn'
%             end
            
            obj.timer = timer('ExecutionMode','fixedSpacing','Period',PAUSE_TIME_BETWEEN_READS,'TimerFcn',@(~,~)obj.updateDisplay);
            start(obj.timer);
        end
        function delete(obj)
            if ~isempty(obj.timer)
                stop(obj.timer);
                delete(obj.timer);
            end
        end
        function updateDisplay(obj)
            %
            %   This is the main function that runs ...
            %
            %   
            
            %'etext_main_display'
            temp_instruction = obj.instruction;
            
            try
                %Now we effectively run 
                switch temp_instruction
                    case 0
                        vol = obj.p.volume_delivered_ml;
                        mode = obj.p.current_mode;

                        %TODO: Add on a status query as well besides using last
                        %populated ...
                        status = obj.p.pump_status_from_last_query;

                        %TODO: Make this a property of the pump object
                        temp = status(1) < '3';
                        
                        if isempty(obj.is_running) || temp ~= obj.is_running
                            if temp
                                set(obj.h.button_start_stop,'String','Stop')
                            else
                                set(obj.h.button_start_stop,'String','Start')
                            end
                        end
                        obj.is_running = temp;

                        str = sprintf('%0.4f ml\nMode: %s\n%s',vol,mode,status);
                        set(obj.h.etext_main_display,'String',str);
                    case 1
                        if get(obj.h.check_clear_volume,'Value')
                           obj.p.clearDeliveredVolume(); 
                        end
                        obj.p.start();
                    case 2
                        obj.p.stop();
                    case 3
                        obj.p.clearDeliveredVolume();
                    case 4
                        all_units = get(obj.h.menu_units_infuse_rate,'String');
                        cur_value = get(obj.h.menu_units_infuse_rate,'Value');
                        %TODO: Fix this so that units is a local property
                        %to index into
                        units = strtrim(all_units{cur_value});
                        new_rate = str2double(get(obj.h.etext_infuse_rate_set,'String'));
                        obj.p.setInfuseRate(new_rate,units);
                        %TODO: We could copy here, rather than doing
                        %another call
                     	temp = obj.p.infuse_rate;
                        set(obj.h.etext_infuse_rate_current_value,'String',sprintf('%0.4f %s',temp{1},temp{2}));
                end
                        
            catch ME
                if isvalid(obj)
                    fprintf(2,'ERROR DETECTED: Timer shutting down\n')
                    disp(ME)
                    stop(obj.timer);
                    delete(obj.timer);
                    obj.timer = [];
                end
            end
            
            if isvalid(obj)
                %I'm not sure how to handle this ....
                if temp_instruction == obj.instruction
                    %Hopefully this allows remote updates ...
                    obj.instruction = 0;
                end
            end
        end
        function cb_setInfuseRate(obj)
            obj.instruction = 4;
        end
        function cb_clearVolume(obj)
            obj.instruction = 3;
        end
        function cb_startStop(obj)
            
            if obj.is_running
                obj.instruction = 2;
            else
                obj.instruction = 1;
            end
            
            
        end
    end
    
end

function h__closeFigure(obj)
    delete(obj)
    delete(gcf);
end

