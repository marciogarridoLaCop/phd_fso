% Programa de Pós Graduação em Engenharia Elétrica e Telecomunicações
% LACOP - Laboratório de Comunicações Óticas - UFF
% Aluno: Márcio Alexandre Dias Garrido
% Data: Fev/2022
% Coleta de dados Informações sobre o DAQ6216 - NI

clear all;
clc;
format long;
%% Configuração do DAQ
sample_rate = 1000;      % Taxa amostral (Hz)
time_reading = 20;       % Tempo de Coleta (segundos)
d = daq("ni");           % Cria instância do DAQ
d.Rate = sample_rate;   

%% Configuração dos Canais
% Detector Central (Porta 0)
A0 = addinput(d, "Dev1", "ai0", "Voltage");
A0.Range = [-5 5];
A0.TerminalConfig = "SingleEnded";     

% Sensor Direita (Porta 1)
A1 = addinput(d, "Dev1", "ai2", "Voltage");
A1.Range = [-5 5];
A1.TerminalConfig = "SingleEnded"; 

% Sensor Esquerda (Porta 2)
A2 = addinput(d, "Dev1", "ai3", "Voltage");
A2.Range = [-5 5];
A2.TerminalConfig = "SingleEnded"; 

% Sensor Topo (Porta 3)
A3 = addinput(d, "Dev1", "ai4", "Voltage");
A3.Range = [-5 5];
A3.TerminalConfig = "SingleEnded"; 

% Temperatura Inferior (Porta 4)
A4 = addinput(d, "Dev1", "ai5", "Voltage");
A4.Range = [-5 5];
A4.TerminalConfig = "SingleEnded"; 

% Temperatura Superior (Porta 5)
A5 = addinput(d, "Dev1", "ai6", "Voltage");
A5.Range = [-5 5];
A5.TerminalConfig = "SingleEnded"; 

% Sensor de Fluxo (Porta 6)
A6 = addinput(d, "Dev1", "ai7", "Voltage");
A6.Range = [-5 5];
A6.TerminalConfig = "SingleEnded";

% Sensor de Umidade (Porta 7)
A7 = addinput(d, "Dev1", "ai8", "Voltage");
A7.Range = [-5 5];
A7.TerminalConfig = "SingleEnded";



%% Primeiro renomeie as colunas
[DADOS, starTime] = read(d, seconds(time_reading)); 

DADOS.Properties.DimensionNames{1} = 'Time';
DADOS.Properties.VariableNames{1} = 'Central'; 
DADOS.Properties.VariableNames{2} = 'Topo'; 
DADOS.Properties.VariableNames{3} = 'Esquerda'; 
DADOS.Properties.VariableNames{4} = 'Direita';
DADOS.Properties.VariableNames{5} = 'Temp_1'; 
DADOS.Properties.VariableNames{6} = 'Temp_2'; 
DADOS.Properties.VariableNames{7} = 'Fluxo'; 
DADOS.Properties.VariableNames{8} = 'Umidade';

%% arredondamento 
vars_to_round = {'Central', 'Direita', 'Esquerda', 'Topo', 'Temp_1', 'Temp_2', 'Fluxo', 'Umidade'};
for k = 1:length(vars_to_round)
    DADOS.(vars_to_round{k}) = round(DADOS.(vars_to_round{k}), 1);
end

%% Depois faça os cálculos
DADOS.Temp_1(:,1) = round(f_temperatura(DADOS.Temp_1(:,1)), 1);
DADOS.Temp_2(:,1) = round(f_temperatura(DADOS.Temp_2(:,1)), 1);
DADOS.Fluxo(:,1) = round(f_flow(DADOS.Fluxo(:,1)), 1);
DADOS.Umidade(:,1) = round(f_umidade(DADOS.Umidade(:,1)), 1);

%% Salvamento dos Dados
arquivo = "1-CENTRO_TXX_FYY_DDMMYY";
save(arquivo, 'DADOS');


