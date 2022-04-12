classdef unpaired_rate  < handle
    %
    %   Class:
    %   harvard.pump.elite_11.gui.unpaired_rate
    
    %{
        unpaired_rate = harvard.pump.elite_11.gui.unpaired_rate;
    %}
    
    
    properties
        h harvard.pump.elite_11.gui.unpaired_rate_app
        parent harvard.pump.elite_11.gui
    end
    
    methods   
        function obj = unpaired_rate(parent)
            if nargin > 0
            obj.parent = parent;
            end
        end
        function launchunpaired_rateGUI(obj)
            obj.h = harvard.pump.elite_11.gui.unpaired_rate_app;
            obj.h.ButtonA.ButtonPushedFcn = @(~,~)obj.button1();
            obj.h.ButtonB.ButtonPushedFcn = @(~,~)obj.button2();
            obj.h.ButtonC.ButtonPushedFcn = @(~,~)obj.button3();
            obj.h.ButtonD.ButtonPushedFcn = @(~,~)obj.button4();
            obj.h.Label.Text = 'The current rate on pump  does not match the fill rate you used last time. What are you going to do? '
            obj.h.LabelA.Text = 'set GUI to current pump rate'
            obj.h.LabelB.Text = 'set GUI to saved rate, but don not change pump'
            obj.h.LabelC.Text = 'change pump to saved rate'
            obj.h.LabelD.Text = 'cancel, close GUI I NEVER RUN!!!!!!!'
        end
       
        function button1(obj)
            obj.parent.h.fill_rate.Value = num2str(obj.parent.new_value);             
        end
        function button2(obj)
             obj.parent.new_value = str2double(obj.parent.h.fill_rate.Value);
             obj.parent.h.display1.Value = sprintf('Current Rate: %g (%s)', obj.parent.new_value,obj.parent.target_units);
        end
         function button3(obj)
            
               obj.parent.setFillRate();
               obj.parent.new_value = str2double(obj.parent.h.fill_rate.Value);
               obj.parent.display1;
         end
         function button4(obj)
            obj.parent.h__closeFigure();
            obj.close();
         end
         function close(obj)
             
             delete(obj.h.UIFigure);
         end
    end
end
