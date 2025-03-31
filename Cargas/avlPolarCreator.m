% Script para a criacao de polar atraves de execucao autom�tica do avl

clear all
clc

%% INPUTS
AVL = 'MTN'; %arquivo de entrada .avl - SEM EXTENS�O
MASS = 'MTN'; %arquivo de massa - SEM EXTENS�O

V = 14.0 ; % velocidade

%% ==============================================
i = 0;
for a=-5.0:1.0:17.0  % para efeito solo diminuir range de alpha
    i = i+1;
    m = int2str(a);
    
    %% Comandos que ser�o executados no avl
    
    frun = fopen(strcat(AVL,'.run'),'W');
    fprintf(frun,'LOAD %s\n',strcat(AVL,'.avl'));
    fprintf(frun,'%s\n', 'MASS');
    fprintf(frun,'%s\n', strcat(MASS, '.mass'));
    fprintf(frun, '%s\n',   'MSET');
     fprintf(frun, '%s\n',   '0');
    fprintf(frun, '%s\n',   'OPER');
    fprintf(frun, '%s\n',   'C1');
    fprintf(frun, '%s\n',   'V');
    fprintf(frun, '%s\n',   num2str(V));
    fprintf(frun, '\n');
    % fprintf(frun, '%s\n',   'B');
    % fprintf(frun, '%s\n\n',   '45');
    fprintf(frun, '%s\n',   'd1');
    fprintf(frun, '%s\n',   'pm');
    fprintf(frun, '%s\n',   '0');
    fprintf(frun, '%s\n',   'a');
    fprintf(frun, '%s\n%f\n',   'a',a);
    
    fprintf(frun, '%s\n',   'X');
    fprintf(frun, '%s\n',   'FT');
    fprintf(frun, '%s\n', [m '.ft']);
    fprintf(frun,'$s\n');
    fprintf(frun,'QUIT\n');
    fclose(frun);
    dos(strcat('avl < ', AVL,'.run'));
    
    %% Leitura dos dados
    % parametros para serem lidos do arquivo
    parameters = {'Alpha', 'Beta', 'CXtot', 'CYtot', 'CZtot',...
                'CLtot', 'CDtot', 'CDvis', 'CDind',...
                'aileron', 'elevator'};
    
    % l� o arquivo para uma unica string
    ft = fileread([m '.ft']);
    
    for j = 1:length(parameters)
        par = parameters{j};
        
        target_exp = ['(?<=' par '[^0-9-]*)[0-9-]*\.?[0-9]+'];
        % what this gibberish means:    % * look ahead for (i.e. start matching after) the string in par followed by any number of characters not including '0' to '9' and -, the (?<=par[^0-9]*)
                                        % * once the preceding is found, match 0 or more characters from '0' to '9' or -, the [0-9-]*
                                        % * followed by an optional ., the \.?
                                        % * followed by one or more '0' to '9' character, the [0-9]+
        
        % what we need: result = str2double(regexp(ft, target_exp, 'match'));
        command = [par '(i) = str2double(regexp(ft, target_exp, ''match''));'];
        % note that this already created the variable arrays. The variables
        % created are those in the 'parameters' cell array
        
        % run commands
        eval(command);
    end
    
    %% Delete de arquivos de leitura
    delete([m '.ft']);
    delete(strcat(AVL,'.run'));
end

%% Plots

figure(1), clf
plot(CDtot, CLtot)
xlabel('CD')
ylabel('CL')
grid on
box on

figure(2), clf
plot(Alpha, CLtot)
xlabel('Alpha')
ylabel('CL')
grid on
box on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%