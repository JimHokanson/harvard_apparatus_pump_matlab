classdef options < handle
    %
    %   Class:
    %   harvard.pump.elite_11.gui.options
    %

    %{
        options = harvard.pump.elite_11.gui.options;
    %}
    
    
    properties
        h harvard.pump.elite_11.gui.options_editor
        parent harvard.pump.elite_11.gui
        clear_volume_on_start = true
        %         resizable = false; %LOW PRIORITY
        volume_unit = 'match with Fill Rate'
    end
    
    methods
        function obj = options(parent)
            obj.parent = parent;
            
            
            
            
            %             disk parameters are loaded by parent
        end
        function launchEditorGUI(obj)
            obj.h = harvard.pump.elite_11.gui.options_editor;
            obj.h.volume_unit.Items = {'nl';'ul';'ml';'match with Fill Rate'};
            obj.h.clear_volume_on_start.ValueChangedFcn = @(~,~)obj.applyChanges();
            obj.h.volume_unit.ValueChangedFcn = @(~,~)obj.volume_unit_change();
            %TODO: Set close function
            %TODO: Update GUI with current values
            obj.h.clear_volume_on_start.Value =   obj.clear_volume_on_start;
            obj.h.volume_unit.Value = obj.volume_unit;
            
            %TODO: Add apply functio
        end
        function volume_unit_change(obj)
            obj.volume_unit = obj.h.volume_unit.Value;
            obj.parent.saveToDisk();
        end
        function applyChanges(obj)
            %JAH: ??? Why have this if going to use callbacks?
            
            obj.clear_volume_on_start = obj.h.clear_volume_on_start.Value;
            
            %TODO: Save results to disk
            obj.parent.saveToDisk();
        end
        function s = getStruct(obj)
            s.clear_volume_on_start = obj.clear_volume_on_start;
            s.volume_unit = obj.volume_unit;
        end
        function loadFromStruct(obj,s)
            obj.clear_volume_on_start = s.clear_volume_on_start;
            obj.volume_unit =  s.volume_unit;
        end
        
        
    end
end
