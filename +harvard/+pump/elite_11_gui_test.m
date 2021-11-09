function test
close all
global gui
gui.h=figure('units','pixels',...
    'position',[900 500 400 400],...
    'menubar','none',...
    'name','Pump',...
    'numbertitle','off',...
    'resize','off');

gui.start=uicontrol('Parent',gui.h,'Style','pushbutton','String','Start',...
    'Position',[300 150 50 100],'visible','on','Background',[0 1 0],...
    'callback',@startpump);
gui.stop=uicontrol('Parent',gui.h,'Style','pushbutton','String','Stop',...
    'Position',[300 150 50 100],'visible','off','Background',[1 0 0],...
    'callback',@stoppump);
gui.text1=uicontrol('Parent',gui.h,'Style','Text','String','Fill Rate',...
    'Position',[10 300 150 30],'Fontsize',12,'FontWeight','bold',...
    'HorizontalAlignment','left');
gui.text2=uicontrol('Parent',gui.h,'Style','Text','String','Unit',...
    'Position',[10 250 150 30],'Fontsize',12,'FontWeight','bold',...
    'HorizontalAlignment','left');
gui.edit=uicontrol('Parent',gui.h,'Style','edit','String','',...
    'Position',[90 300 90 30],'Fontsize',12,'FontWeight','bold',...
    'visible','on');
gui.unit=uicontrol('Parent',gui.h,'Style','Popup Menu','String',{'m/h';'m/m';'u/h';'u/m';'u/s';'n/s'},...
    'Position',[90 250 90 30],'Fontsize',12,'FontWeight','bold',...
    'visible','on');

% pump = harvard.pump.elite_11('COM3','address',1,'baud_rate',115200);

    function startpump(~,~)
        gui.units=get(gui.unit,'value');
        switch gui.units
            case 1
                gui.units = 'm/h';
            case 2
                gui.units = 'm/m';
            case 3
                gui.units = 'u/h';
            case 4
                gui.units = 'u/m';
            case 5
                gui.units = 'u/s';
            case 6
                gui.units = 'n/s';
        end
        set(gui.start,'visible','off');
        set(gui.stop,'visible','on');
        gui.rate=str2double(get(gui.edit,'string'));
        % setInfuseRate(pump,rate,units)
        % start(pump)
        gui.x=[num2str(gui.rate),gui.units,'started'];
        disp(gui.x)
    end

    function stoppump(~,~)
        set(gui.start,'visible','on');
        set(gui.stop,'visible','off');
        % obj.runQuery('STP');
        gui.y=[num2str(gui.rate),gui.units,'stopped'];
        disp(gui.y)
    end
end
