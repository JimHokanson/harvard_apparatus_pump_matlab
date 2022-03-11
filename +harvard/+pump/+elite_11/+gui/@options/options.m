classdef options < handle
    %
    %   Class:
    %   harvard.pump.elite_11.gui.options
    
    %{
        options = harvard.pump.elite_11.gui.options;
    %}
    
    
    properties
        h harvard.pump.elite_11.gui.options_editor
        parent harvard.pump.elite_11.gui
        clear_volume_on_start = true
        %         resizable = false; %LOW PRIORITY
    end
    
    
    
    methods
        
        
        
        function obj = options(parent)
            obj.parent = parent;
        end
        function launchEditorGUI(obj)
            obj.h = harvard.pump.elite_11.gui.options_editor;
            %TODO: Set close function
            %TODO: Update GUI with current values
            
            obj.h.clear_volume_on_start.Value = obj.clear_volume_on_start;
            %obj.h.clear_volume_on_start.ValueChangedFcn = @(~,~)obj.applyChanges();
            %TODO: Add apply functio
        end
        function applyChanges(obj)
            obj.clear_volume_on_start = obj.h.clear_volume_on_start.Value;
            
            %TODO: Save results to disk
            
            obj.parent.saveToDisk();
        end
        function loadFromStruct(obj,s)
            obj.clear_volume_on_start = s.clear_volume_on_start;
        end
        function s = getStruct(obj)
            s.clear_volume_on_start = obj.clear_volume_on_start;
        end
    end
end
